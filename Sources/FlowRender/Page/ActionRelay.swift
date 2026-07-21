import SwiftUI
import FlowCore

/// The thin pipe between widget views and whatever dispatches their actions.
///
/// `FlowPageView` and `FlowSheetView` install a relay that forwards into the
/// active `ActionDispatcher` with full page context. The default relay swallows
/// everything, which is what previews and isolated widget rendering want.
public struct FlowActionRelay {
    private let send: @MainActor (ActionData, String?) -> Void

    public init(send: @escaping @MainActor (ActionData, String?) -> Void) {
        self.send = send
    }

    @MainActor
    public func callAsFunction(_ action: ActionData, from widgetID: String?) {
        send(action, widgetID)
    }

    public static let inert = FlowActionRelay { _, _ in }
}

private struct FlowActionRelayKey: EnvironmentKey {
    static let defaultValue = FlowActionRelay.inert
}

public extension EnvironmentValues {
    var flowActionRelay: FlowActionRelay {
        get { self[FlowActionRelayKey.self] }
        set { self[FlowActionRelayKey.self] = newValue }
    }
}

private struct FlowStateStoreKey: EnvironmentKey {
    static let defaultValue = WidgetStateStore()
}

public extension EnvironmentValues {
    /// The widget state store for the current page or sheet.
    var flowStateStore: WidgetStateStore {
        get { self[FlowStateStoreKey.self] }
        set { self[FlowStateStoreKey.self] = newValue }
    }
}
