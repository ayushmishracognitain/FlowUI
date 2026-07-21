import SwiftUI

@main
struct FlowDemoApp: App {
    @State private var settings = DemoSettings.shared

    var body: some Scene {
        WindowGroup {
            Group {
                // FLOWDEMO_PAGE=home launches straight into a page, which keeps
                // screenshot automation and CI runs one command long.
                if let pageID = ProcessInfo.processInfo.environment["FLOWDEMO_PAGE"] {
                    RoutedNavigationStack {
                        DemoPageScreen(pageID: pageID, title: pageID)
                    }
                } else {
                    HomeView()
                }
            }
            .preferredColorScheme(settings.darkMode ? .dark : nil)
        }
    }
}

/// A navigation stack bound to the demo router, so deeplink actions can push
/// pages from anywhere in the tree.
struct RoutedNavigationStack<Root: View>: View {
    @Bindable private var router = DemoRouter.shared
    @ViewBuilder let root: Root

    var body: some View {
        NavigationStack(path: $router.path) {
            root
                .navigationDestination(for: String.self) { pageID in
                    DemoPageScreen(pageID: pageID, title: pageID.capitalized)
                }
        }
    }
}
