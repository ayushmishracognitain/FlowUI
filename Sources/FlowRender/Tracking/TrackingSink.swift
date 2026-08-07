import SwiftUI
import FlowCore

/// Receives the opaque `tracking` object a widget carries.
///
/// Every widget envelope can carry a `tracking` blob that the framework never
/// interprets. This is the seam where it reaches the host, so the event schema
/// stays entirely the backend's and the analytics vendor stays entirely the app's.
///
/// ```swift
/// struct MyAnalytics: FlowTrackingSink {
///     func widgetDidAppear(_ impression: FlowImpression) {
///         Analytics.log("impression", properties: impression.tracking)
///     }
/// }
///
/// FlowPageView(store: store)
///     .flowTrackingSink(MyAnalytics())
/// ```
public protocol FlowTrackingSink: Sendable {
    /// Called once per widget appearance, after the widget has been on screen long
    /// enough to count as seen.
    @MainActor func widgetDidAppear(_ impression: FlowImpression)
}

/// One widget impression: who was seen, and whatever the backend attached to it.
public struct FlowImpression: Sendable {
    public let widgetID: String
    public let widgetType: String
    /// The untouched `tracking` fragment from the widget envelope.
    public let tracking: JSONValue

    public init(widgetID: String, widgetType: String, tracking: JSONValue) {
        self.widgetID = widgetID
        self.widgetType = widgetType
        self.tracking = tracking
    }
}

/// The sink installed when the host installs nothing. Drops everything.
public struct NoOpTrackingSink: FlowTrackingSink {
    public init() {}
    public func widgetDidAppear(_ impression: FlowImpression) {}
}

private struct FlowTrackingSinkKey: EnvironmentKey {
    static let defaultValue: any FlowTrackingSink = NoOpTrackingSink()
}

public extension EnvironmentValues {
    /// The active tracking sink. Defaults to one that discards impressions.
    var flowTrackingSink: any FlowTrackingSink {
        get { self[FlowTrackingSinkKey.self] }
        set { self[FlowTrackingSinkKey.self] = newValue }
    }
}

public extension View {
    /// Routes widget impressions to `sink` for every Flow-UI view below this point.
    func flowTrackingSink(_ sink: any FlowTrackingSink) -> some View {
        environment(\.flowTrackingSink, sink)
    }

    /// How long a widget must stay on screen before it counts as seen.
    ///
    /// The dwell is what keeps a fast scroll from reporting every row it flings
    /// past. Default is 250ms.
    func flowImpressionThreshold(_ duration: Duration) -> some View {
        environment(\.flowImpressionThreshold, duration)
    }
}

private struct FlowImpressionThresholdKey: EnvironmentKey {
    static let defaultValue: Duration = .milliseconds(250)
}

public extension EnvironmentValues {
    var flowImpressionThreshold: Duration {
        get { self[FlowImpressionThresholdKey.self] }
        set { self[FlowImpressionThresholdKey.self] = newValue }
    }
}

/// Reports a widget as seen once it has held the screen for the dwell threshold.
///
/// `.task` is tied to the view's lifetime, so scrolling a row out of a lazy stack
/// cancels the pending report for free. That is the whole debounce.
struct ImpressionReporting: ViewModifier {
    let widget: AnyWidget

    @Environment(\.flowTrackingSink) private var sink
    @Environment(\.flowImpressionThreshold) private var threshold
    @State private var reported = false

    func body(content: Content) -> some View {
        content.task(id: widget.id) {
            guard let tracking = widget.tracking, !reported else { return }
            try? await Task.sleep(for: threshold)
            guard !Task.isCancelled else { return }
            reported = true
            sink.widgetDidAppear(
                FlowImpression(widgetID: widget.id, widgetType: widget.type, tracking: tracking)
            )
        }
    }
}
