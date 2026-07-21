import SwiftUI

@main
struct FlowDemoApp: App {
    var body: some Scene {
        WindowGroup {
            // FLOWDEMO_PAGE=home launches straight into a page, which keeps
            // screenshot automation and CI runs one command long.
            if let pageID = ProcessInfo.processInfo.environment["FLOWDEMO_PAGE"] {
                NavigationStack {
                    DemoPageScreen(pageID: pageID, title: pageID)
                }
            } else {
                HomeView()
            }
        }
    }
}
