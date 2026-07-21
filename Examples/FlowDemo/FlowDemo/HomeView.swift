import SwiftUI
import FlowRender

/// The demo's table of contents: fixture pages, tools and network simulation.
struct HomeView: View {
    @State private var settings = DemoSettings.shared
    @State private var remoteURL = "http://localhost:8080"

    var body: some View {
        NavigationStack {
            List {
                Section("Pages") {
                    NavigationLink("Home feed") {
                        DemoPageScreen(pageID: "home", title: "Home feed")
                    }
                    NavigationLink("Layouts: carousel, grid, vertical") {
                        DemoPageScreen(pageID: "layouts", title: "Layouts")
                    }
                    NavigationLink("Paginated feed") {
                        DemoPageScreen(pageID: "feed", title: "Paginated feed")
                    }
                    NavigationLink("Problem widgets") {
                        DemoPageScreen(pageID: "problems", title: "Problem widgets")
                    }
                }

                Section("Tools") {
                    NavigationLink("Playground") {
                        PlaygroundView()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remote mode")
                            .font(.subheadline.weight(.semibold))
                        Text("Serve JSON from any URL, for example: python3 -m http.server 8080 in a folder with home.json. Edit the file, pull to refresh, no rebuild.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Base URL", text: $remoteURL)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption.monospaced())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        NavigationLink("Open remote home page") {
                            if let url = URL(string: remoteURL) {
                                DemoPageScreen(
                                    pageID: "home",
                                    title: "Remote",
                                    loader: RemotePageLoader(baseURL: url)
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Network simulation") {
                    VStack(alignment: .leading) {
                        Text("Latency: \(Int(settings.latencyMilliseconds)) ms")
                            .font(.subheadline)
                        Slider(value: $settings.latencyMilliseconds, in: 0...3000, step: 100)
                    }
                    Toggle("Simulate failure", isOn: $settings.simulateFailure)
                    Toggle("Simulate empty response", isOn: $settings.simulateEmpty)
                    Text("Open any page to see the shimmer skeleton, the error state with retry, or the empty state.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("FlowUI Demo")
        }
    }
}

#Preview {
    HomeView()
}
