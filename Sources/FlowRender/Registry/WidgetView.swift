import SwiftUI
import FlowCore

/// Everything a widget view receives besides its typed content.
///
/// `dispatch` routes an event name (such as `"tap"`) through the widget's declared
/// actions into the active `ActionDispatcher`. `state` is the page scoped store for
/// ephemeral values like stepper counts and expanded flags.
public struct WidgetContext {
    public let widgetID: String
    public let actions: WidgetActions
    public let state: WidgetStateStore
    private let dispatchAction: (ActionData, String) -> Void

    public init(
        widgetID: String,
        actions: WidgetActions,
        state: WidgetStateStore,
        dispatchAction: @escaping (ActionData, String) -> Void
    ) {
        self.widgetID = widgetID
        self.actions = actions
        self.state = state
        self.dispatchAction = dispatchAction
    }

    /// Fires the action registered for `event`, if the backend declared one.
    public func dispatch(event: String) {
        guard let action = actions[event] else { return }
        dispatchAction(action, widgetID)
    }

    /// Fires an explicit action, for content that embeds `ActionData` directly,
    /// like buttons and icons.
    public func dispatch(_ action: ActionData?) {
        guard let action else { return }
        dispatchAction(action, widgetID)
    }

    /// A context that goes nowhere, for previews and tests.
    public static func inert(widgetID: String = "preview", actions: WidgetActions = .none) -> WidgetContext {
        WidgetContext(widgetID: widgetID, actions: actions, state: WidgetStateStore()) { _, _ in }
    }
}

/// A SwiftUI view that renders one widget type.
///
/// Conforming is the second half of adding a widget; the first is the
/// `WidgetContent` payload model. Register the pair once:
///
/// ```swift
/// registry.register(OrderCardWidget.self)
/// ```
public protocol WidgetView: View {
    associatedtype Content: WidgetContent
    init(content: Content, context: WidgetContext)
}

/// Optional skeleton for a widget type, used by loading states and catalogs to
/// mirror the widget's real shape instead of a generic block.
public protocol WidgetSkeletonProviding {
    @MainActor static func skeleton() -> AnyView
}
