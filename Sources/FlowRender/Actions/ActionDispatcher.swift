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
        Task {
            var context = context
            context = ActionContext(
                sourceWidgetID: context.sourceWidgetID,
                pageStore: context.pageStore,
                presenter: context.presenter,
                redispatch: { [weak self] inner in
                    self?.dispatch(inner, context: context)
                }
            )
            for handler in handlers.reversed() {
                guard await handler.handle(action, context: context) else { continue }
                record(action, context: context, handledBy: String(describing: type(of: handler)))
                return
            }
            record(action, context: context, handledBy: nil)
        }
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
