import Foundation
import Observation
import FlowCore
import FlowRender
import FlowWidgets

/// Knobs for simulating real network conditions from the Home screen.
@Observable
final class DemoSettings: @unchecked Sendable {
    static let shared = DemoSettings()

    var latencyMilliseconds: Double = 500
    var simulateFailure = false
    var simulateEmpty = false
}

enum Demo {
    /// One registry for the whole demo: the FlowWidgets library plus the app's
    /// own order_card, registered exactly the way a host app would.
    @MainActor
    static func makeRegistry() -> WidgetRegistry {
        let registry = WidgetRegistry()
        FlowWidgets.register(on: registry)
        registry.register(OrderCardWidget.self)
        return registry
    }

    /// A dispatcher with the demo's deeplink handler layered on the built ins.
    @MainActor
    static func makeDispatcher() -> ActionDispatcher {
        let dispatcher = ActionDispatcher()
        dispatcher.register(DemoDeeplinkHandler())
        return dispatcher
    }
}

/// The demo's stand in for a router. A real host would push a screen here;
/// the demo just proves the action arrived by showing where it would go.
struct DemoDeeplinkHandler: ActionHandler {
    private struct Payload: Decodable {
        let url: String
    }

    func handle(_ action: ActionData, context: ActionContext) async -> Bool {
        guard action.type == "deeplink", let payload = try? action.payload(Payload.self) else { return false }
        context.presenter?.show(ToastData(message: "Would navigate to \(payload.url)"))
        return true
    }
}
