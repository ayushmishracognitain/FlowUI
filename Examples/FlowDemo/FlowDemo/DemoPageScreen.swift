import SwiftUI
import FlowCore
import FlowRender

/// Hosts one server driven page from a loader, with the debug console attached.
struct DemoPageScreen: View {
    let pageID: String
    let title: String
    var loader: any PageLoader = FixturePageLoader()

    @State private var store: PageStore?
    @State private var dispatcher: ActionDispatcher?

    var body: some View {
        Group {
            if let store, let dispatcher {
                FlowPageView(store: store, dispatcher: dispatcher)
                    .flowDebugOverlay(store: store)
            } else {
                Color.clear
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if store == nil {
                store = PageStore(pageID: pageID, loader: loader, registry: Demo.makeRegistry())
                dispatcher = Demo.makeDispatcher()
            }
        }
    }
}
