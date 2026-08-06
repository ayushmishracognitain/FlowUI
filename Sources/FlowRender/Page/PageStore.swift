import SwiftUI
import Observation
import FlowCore

/// Loads, holds and mutates one server driven page.
///
/// The store owns the fetch lifecycle (initial load, pull to refresh, pagination)
/// and the decode pipeline (registry plus diagnostics). Views observe `state` and
/// render whatever it says; nothing else in the framework talks to the network.
@Observable
@MainActor
public final class PageStore {
    public enum State {
        case loading
        case loaded(PageModel)
        case failed(message: String)
        case empty
    }

    public private(set) var state: State = .loading
    public private(set) var isLoadingMore = false

    public let pageID: String
    public let registry: WidgetRegistry
    public let stateStore = WidgetStateStore()
    /// Problems from the most recent decode, surfaced by the debug overlay.
    public private(set) var diagnostics = DecodeDiagnostics()

    private let loader: any PageLoader
    /// The in flight page fetch. Retained so a newer request can cancel an older
    /// one instead of racing it, which otherwise lets the slower response win.
    private var fetchTask: Task<Void, Never>?
    private var pageTask: Task<Void, Never>?

    public init(pageID: String, loader: any PageLoader, registry: WidgetRegistry) {
        self.pageID = pageID
        self.loader = loader
        self.registry = registry
    }

    public var page: PageModel? {
        if case .loaded(let page) = state { return page }
        return nil
    }

    // MARK: - Lifecycle

    public func loadInitial() async {
        state = .loading
        await fetch(kind: .initial)
    }

    public func refresh() async {
        // Keep current content on screen while the refresh is in flight.
        stateStore.reset()
        await fetch(kind: .refresh)
    }

    public func retry() async {
        await loadInitial()
    }

    public func loadNextPage() async {
        guard case .loaded(let current) = state,
              current.pagination?.hasMore == true,
              !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let request = PageRequest(pageID: pageID, kind: .nextPage(postback: current.pagination?.postback))
        let postback = current.pagination?.postback

        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let next = try await self.decodePage(from: try await self.loader.loadPage(request))
                guard !Task.isCancelled else { return }
                self.appendNextPage(next, requestedWith: postback)
            } catch {
                // A failed pagination fetch should not blank a healthy page.
                // The sentinel stays visible and the next appearance retries.
            }
        }
        pageTask?.cancel()
        pageTask = task
        await task.value
    }

    /// Merges a paginated response into whatever is on screen *now*.
    ///
    /// The previous version captured the page before the await and wrote that
    /// capture back afterwards, so any mutation applied while the fetch was in
    /// flight, an `api` action's `replace_widget` or a completed refresh, was
    /// silently discarded. Re-reading the state here is what keeps those.
    private func appendNextPage(_ next: PageModel, requestedWith postback: JSONValue?) {
        guard case .loaded(var current) = state else { return }
        // The page was replaced wholesale while this fetch was in flight, so the
        // cursor this response answers no longer describes what is on screen.
        guard current.pagination?.postback == postback else { return }

        current.sections.append(contentsOf: next.sections)
        current.pagination = next.pagination
        // Two responses that were each internally consistent can still collide
        // with one another once merged.
        current.makeWidgetIdentifiersUnique(recordingTo: diagnostics)
        state = .loaded(current)
    }

    /// Performs a loader round trip for an `api` action and returns the raw response
    /// for the action handler to interpret.
    public func performAction(payload: JSONValue) async throws -> Data {
        try await loader.loadPage(PageRequest(pageID: pageID, kind: .action(payload)))
    }

    /// Decodes an `api` action response off the main actor, the same way page
    /// responses are decoded. Doing it inline would block the UI for as long as a
    /// large mutation payload takes to parse.
    public func decodeActionResponse(from data: Data) async throws -> ActionResponse {
        let registry = registry
        let diagnostics = diagnostics
        return try await Task.detached(priority: .userInitiated) {
            try FlowDecoder.make(widgetDecoding: registry, diagnostics: diagnostics)
                .decode(ActionResponse.self, from: data)
        }.value
    }

    // MARK: - Mutations

    public func apply(_ mutation: PageMutation) {
        guard case .loaded(var page) = state else {
            if case .replacePage(let newPage) = mutation {
                state = .loaded(newPage)
            }
            return
        }
        page.apply(mutation)
        state = .loaded(page)
    }

    // MARK: - Fetch and decode

    /// Runs one page fetch, cancelling any fetch already in flight.
    ///
    /// Without the cancellation two rapid refreshes race and whichever response
    /// lands last wins, regardless of which was asked for last.
    private func fetch(kind: PageRequest.Kind) async {
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let data = try await self.loader.loadPage(PageRequest(pageID: self.pageID, kind: kind))
                let page = try await self.decodePage(from: data)
                guard !Task.isCancelled else { return }
                self.state = page.allWidgets.isEmpty ? .empty : .loaded(page)
            } catch is CancellationError {
                // Superseded by a newer request; the newer one owns the state.
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .failed(message: self.friendlyMessage(for: error))
            }
        }
        fetchTask?.cancel()
        pageTask?.cancel()
        fetchTask = task
        await task.value
    }

    private func decodePage(from data: Data) async throws -> PageModel {
        let freshDiagnostics = DecodeDiagnostics()
        let registry = registry
        let page = try await Task.detached(priority: .userInitiated) {
            try FlowDecoder.make(widgetDecoding: registry, diagnostics: freshDiagnostics)
                .decode(PageResponse.self, from: data)
                .page
        }.value
        diagnostics = freshDiagnostics
        return page
    }

    private func friendlyMessage(for error: Error) -> String {
        if error is DecodingError {
            return describeDecodingError(error)
        }
        return (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
    }
}
