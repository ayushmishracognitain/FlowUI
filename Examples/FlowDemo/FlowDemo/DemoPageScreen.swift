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
                    .flowTrackingSink(DemoTrackingSink())
                    .flowDebugOverlay(store: store)
            } else {
                Color.clear
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { impressionBadge }
        }
        .onAppear {
            if store == nil {
                store = PageStore(pageID: pageID, loader: loader, registry: Demo.makeRegistry())
                dispatcher = Demo.makeDispatcher()
            }
        }
    }

    /// Shows the impressions the tracking sink has received, so the seam is
    /// visible rather than something you have to take on faith.
    private var impressionBadge: some View {
        Label("\(DemoImpressionLog.shared.seen.count)", systemImage: "eye")
            .labelStyle(.titleAndIcon)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .accessibilityLabel("\(DemoImpressionLog.shared.seen.count) impressions tracked")
    }
}
