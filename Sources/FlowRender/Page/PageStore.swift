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
        do {
            let next = try await decodePage(from: try await loader.loadPage(request))
            var merged = current
            merged.sections.append(contentsOf: next.sections)
            merged.pagination = next.pagination
            state = .loaded(merged)
        } catch {
            // A failed pagination fetch should not blank a healthy page.
            // The sentinel stays visible and the next appearance retries.
        }
    }

    /// Performs a loader round trip for an `api` action and returns the raw response
    /// for the action handler to interpret.
    public func performAction(payload: JSONValue) async throws -> Data {
        try await loader.loadPage(PageRequest(pageID: pageID, kind: .action(payload)))
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

    private func fetch(kind: PageRequest.Kind) async {
        do {
            let data = try await loader.loadPage(PageRequest(pageID: pageID, kind: kind))
            let page = try await decodePage(from: data)
            state = page.allWidgets.isEmpty ? .empty : .loaded(page)
        } catch {
            state = .failed(message: friendlyMessage(for: error))
        }
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
