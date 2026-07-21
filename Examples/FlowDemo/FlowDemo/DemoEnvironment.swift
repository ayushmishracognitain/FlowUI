import SwiftUI
import Observation
import FlowCore
import FlowRender
import FlowWidgets

/// Knobs for simulating real network conditions from the Home screen, plus the
/// app wide appearance flag the toggle_theme action flips.
@Observable
final class DemoSettings: @unchecked Sendable {
    static let shared = DemoSettings()

    var latencyMilliseconds: Double = 500
    var simulateFailure = false
    var simulateEmpty = false
    var darkMode = false
}

/// App level navigation state. Deeplink actions push page ids onto this path,
/// which the root `NavigationStack` renders as `DemoPageScreen`s. This is the
/// demo's whole router: a real host would map URLs to its own destinations.
@Observable
@MainActor
final class DemoRouter {
    static let shared = DemoRouter()
    var path: [String] = []

    func push(pageID: String) {
        path.append(pageID)
    }
}

enum Demo {
    /// One registry for the whole demo: the FlowWidgets library plus the app's
    /// own widgets, registered exactly the way a host app would.
    @MainActor
    static func makeRegistry() -> WidgetRegistry {
        let registry = WidgetRegistry()
        FlowWidgets.register(on: registry)
        registry.register(OrderCardWidget.self)
        registry.register(DatePickerRowWidget.self)
        return registry
    }

    /// A dispatcher with the demo's handlers layered on the built ins.
    @MainActor
    static func makeDispatcher() -> ActionDispatcher {
        let dispatcher = ActionDispatcher()
        dispatcher.register(DemoDeeplinkHandler())
        dispatcher.register(ThemeToggleHandler())
        return dispatcher
    }
}

/// The demo's router bridge. `flowdemo://page/<id>` pushes that page onto the
/// navigation stack; anything else just proves the action arrived.
struct DemoDeeplinkHandler: ActionHandler {
    private struct Payload: Decodable {
        let url: String
    }

    func handle(_ action: ActionData, context: ActionContext) async -> Bool {
        guard action.type == "deeplink", let payload = try? action.payload(Payload.self) else { return false }
        let pagePrefix = "flowdemo://page/"
        if payload.url.hasPrefix(pagePrefix) {
            DemoRouter.shared.push(pageID: String(payload.url.dropFirst(pagePrefix.count)))
        } else {
            context.presenter?.show(ToastData(message: "Would navigate to \(payload.url)"))
        }
        return true
    }
}

/// `{"type": "toggle_theme"}`: a custom action type owned entirely by the host.
/// The backend can flip the whole app between light and dark.
struct ThemeToggleHandler: ActionHandler {
    func handle(_ action: ActionData, context: ActionContext) async -> Bool {
        guard action.type == "toggle_theme" else { return false }
        DemoSettings.shared.darkMode.toggle()
        return true
    }
}
