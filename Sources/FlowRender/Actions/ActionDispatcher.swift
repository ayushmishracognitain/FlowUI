import SwiftUI
import FlowCore

/// What an action handler can reach while handling.
public struct ActionContext {
    public let sourceWidgetID: String?
    public weak var pageStore: PageStore?
    public let presenter: FlowPresenter?
    /// Re-enters the dispatcher, for handlers that unwrap composite actions.
    public let redispatch: @MainActor (ActionData) -> Void

    public init(
        sourceWidgetID: String?,
        pageStore: PageStore?,
        presenter: FlowPresenter?,
        redispatch: @escaping @MainActor (ActionData) -> Void = { _ in }
    ) {
        self.sourceWidgetID = sourceWidgetID
        self.pageStore = pageStore
        self.presenter = presenter
        self.redispatch = redispatch
    }
}

/// One link in the action handling chain.
///
/// Return `true` when the action was consumed. Handlers are consulted newest
/// first, so a host handler can override a built in one for the same type.
public protocol ActionHandler {
    @MainActor func handle(_ action: ActionData, context: ActionContext) async -> Bool
}

/// A record of one dispatched action, kept in debug builds for the overlay.
public struct ActionLogEntry: Identifiable, Sendable {
    public let id = UUID()
    public let date = Date()
    public let type: String
    public let sourceWidgetID: String?
    public let handledBy: String?
}

/// Routes backend declared actions to whoever understands them.
///
/// Ships with handlers for `toast`, `dismiss`, `refresh_page`, `open_bottom_sheet`
/// and `api`. Deeplinks are deliberately absent: navigation belongs to the host,
/// which registers its own handler:
///
/// ```swift
/// dispatcher.register(MyDeeplinkHandler())
/// ```
@Observable
@MainActor
public final class ActionDispatcher {
    private var handlers: [any ActionHandler] = []
    /// Handles for actions still running, so they can be cancelled together.
    private var inFlight: [Task<Void, Never>] = []
    /// Recent dispatches, newest last. Populated in debug builds only.
    public private(set) var log: [ActionLogEntry] = []

    /// Creates a dispatcher preloaded with the built in handlers.
    public init(builtIns: Bool = true) {
        if builtIns {
            register(ToastActionHandler())
            register(DismissActionHandler())
            register(RefreshPageActionHandler())
            register(OpenBottomSheetActionHandler())
            register(APIActionHandler())
        }
    }

    /// Adds a handler. Later registrations win over earlier ones.
    public func register(_ handler: any ActionHandler) {
        handlers.append(handler)
    }

    public func dispatch(_ action: ActionData, context: ActionContext) {
        let task = Task { [weak self] in
            guard let self else { return }
            await self.route(action, context: context)
        }
        inFlight.append(task)
        // Drop handles for work that has already finished, so a long lived page
        // does not accumulate them.
        inFlight.removeAll { $0.isCancelled }
    }

    /// Cancels every action still in flight. Hosts call this when tearing a page
    /// down so an `api` round trip cannot land against a screen that is gone.
    public func cancelInFlight() {
        for task in inFlight {
            task.cancel()
        }
        inFlight.removeAll()
    }

    private func route(_ action: ActionData, context: ActionContext) async {
        // The redispatch closure used to capture the same `context` variable that
        // then stored it, which is a reference cycle on the captured box and leaked
        // one context per dispatched action. Rebuilding a plain context from locals
        // means the closure captures values, not the box holding itself.
        let widgetID = context.sourceWidgetID
        let store = context.pageStore
        let presenter = context.presenter

        let resolved = ActionContext(
            sourceWidgetID: widgetID,
            pageStore: store,
            presenter: presenter,
            redispatch: { [weak self] inner in
                let fresh = ActionContext(sourceWidgetID: widgetID, pageStore: store, presenter: presenter)
                self?.dispatch(inner, context: fresh)
            }
        )

        for handler in handlers.reversed() {
            guard await handler.handle(action, context: resolved) else { continue }
            guard !Task.isCancelled else { return }
            record(action, context: resolved, handledBy: String(describing: type(of: handler)))
            return
        }
        guard !Task.isCancelled else { return }
        record(action, context: resolved, handledBy: nil)
    }

    private func record(_ action: ActionData, context: ActionContext, handledBy: String?) {
        #if DEBUG
        log.append(ActionLogEntry(
            type: action.type,
            sourceWidgetID: context.sourceWidgetID,
            handledBy: handledBy
        ))
        if log.count > 200 {
            log.removeFirst(log.count - 200)
        }
        #endif
    }
}

private struct FlowDispatcherKey: EnvironmentKey {
    static let defaultValue: ActionDispatcher? = nil
}

public extension EnvironmentValues {
    /// The dispatcher installed by the nearest `FlowPageView` or `FlowSheetView`.
    var flowDispatcher: ActionDispatcher? {
        get { self[FlowDispatcherKey.self] }
        set { self[FlowDispatcherKey.self] = newValue }
    }
}
