import Foundation
import FlowCore

/// A `PageLoader` backed by bundled JSON, with adjustable latency and failure
/// simulation. This is the whole "backend" of the demo.
struct FixturePageLoader: PageLoader {
    func loadPage(_ request: PageRequest) async throws -> Data {
        let settings = DemoSettings.shared
        try await Task.sleep(for: .milliseconds(Int(settings.latencyMilliseconds)))

        if settings.simulateFailure {
            throw DemoLoaderError.simulated
        }
        if settings.simulateEmpty {
            return Data(#"{"page": {"id": "empty", "sections": []}}"#.utf8)
        }

        switch request.kind {
        case .initial, .refresh:
            return try fixture(named: request.pageID)
        case .nextPage(let postback):
            // A real backend reads the cursor; the fixture backend has one next page.
            if postback?["next_page"]?.intValue == 2 {
                return try fixture(named: "feed_page_2")
            }
            return try fixture(named: request.pageID)
        case .action(let payload):
            return try actionResponse(for: payload)
        }
    }

    private func fixture(named name: String) throws -> Data {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw DemoLoaderError.missingFixture(name)
        }
        return try Data(contentsOf: url)
    }

    /// Canned `ActionResponse` payloads for the demo's `api` actions.
    private func actionResponse(for payload: JSONValue) throws -> Data {
        switch payload["endpoint"]?.stringValue {
        case "favourite":
            let widgetID = payload["widget_id"]?.stringValue ?? "product_1"
            let response = """
            {
              "mutations": [
                {
                  "kind": "replace_widget",
                  "id": "\(widgetID)",
                  "widget": {
                    "type": "image_text_card",
                    "id": "\(widgetID)",
                    "layout": {
                      "margin": { "top": 4, "left": 16, "right": 16, "bottom": 4 },
                      "padding": { "top": 10, "left": 10, "right": 10, "bottom": 10 },
                      "corner_radius": 12,
                      "background": { "hex": "#FFF7E6", "dark_hex": "#3A2E14" },
                      "border": { "width": 1, "color": "#F5A623" }
                    },
                    "data": {
                      "image": { "url": "https://picsum.photos/id/9/144", "aspect_ratio": 1, "corner_radius": 10 },
                      "title": { "text": "AirPods Pro 2", "font": { "size": 16, "weight": "semibold" } },
                      "subtitle": { "text": "Now in your favourites", "color": "#B7791F" },
                      "trailing_icon": { "symbol": "heart.fill", "size": 16, "color": "#4F8CFF" }
                    }
                  }
                }
              ],
              "toast": { "message": "Added to favourites" }
            }
            """
            return Data(response.utf8)
        case "cart/update":
            return Data(#"{"mutations": [], "toast": {"message": "Quantity updated"}}"#.utf8)
        default:
            return Data(#"{"mutations": [], "toast": {"message": "Action received"}}"#.utf8)
        }
    }
}

/// A `PageLoader` that fetches `<baseURL>/<pageID>.json`, so a local mock server
/// (or any static host) can drive the demo. Pair it with the reload button for a
/// tight edit and rerun loop without a rebuild.
struct RemotePageLoader: PageLoader {
    let baseURL: URL

    func loadPage(_ request: PageRequest) async throws -> Data {
        let url = baseURL.appending(path: "\(request.pageID).json")
        let (data, _) = try await URLSession.shared.data(
            from: url.appending(queryItems: [URLQueryItem(name: "t", value: "\(Date().timeIntervalSince1970)")])
        )
        return data
    }
}

/// Serves whatever JSON the playground editor currently holds.
struct StaticPageLoader: PageLoader {
    let data: Data

    func loadPage(_ request: PageRequest) async throws -> Data {
        data
    }
}

enum DemoLoaderError: LocalizedError {
    case simulated
    case missingFixture(String)

    var errorDescription: String? {
        switch self {
        case .simulated:
            "Simulated network failure. Turn it off from the Home screen."
        case .missingFixture(let name):
            "No bundled fixture named \(name).json"
        }
    }
}
