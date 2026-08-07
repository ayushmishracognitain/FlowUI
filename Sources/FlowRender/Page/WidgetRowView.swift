import SwiftUI
import FlowCore

/// Renders one `AnyWidget`: resolves the view through the registry, applies the
/// backend layout, and attaches envelope level gestures.
///
/// Unknown and malformed content is handled here according to the registry's
/// `unknownPolicy`, so a bad widget renders as a labelled card in debug builds
/// and disappears silently in release.
public struct WidgetRowView: View {
    private let widget: AnyWidget

    @Environment(\.flowRegistry) private var registry
    @Environment(\.flowStateStore) private var stateStore
    @Environment(\.flowActionRelay) private var relay

    public init(_ widget: AnyWidget) {
        self.widget = widget
    }

    public var body: some View {
        switch widget.content {
        case let unknown as UnknownWidgetContent:
            problemCard(
                title: "Unknown widget '\(unknown.type)'",
                message: "Nothing is registered for this type.",
                tint: .orange
            )
        case let malformed as MalformedWidgetContent:
            problemCard(
                title: "Malformed '\(malformed.type)'",
                message: malformed.message,
                tint: .red
            )
        default:
            if let view = registry.view(for: widget, context: context) {
                view
                    .widgetLayout(widget.layout)
                    .modifier(EnvelopeGestures(widget: widget, context: context))
                    .modifier(ImpressionReporting(widget: widget))
                    .modifier(LayoutInspection(widget: widget))
            }
        }
    }

    private var context: WidgetContext {
        WidgetContext(
            widgetID: widget.id,
            actions: widget.actions,
            state: stateStore
        ) { action, widgetID in
            relay(action, from: widgetID)
        }
    }

    @ViewBuilder
    private func problemCard(title: String, message: String, tint: Color) -> some View {
        if registry.unknownPolicy == .placeholder {
            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(tint.opacity(0.5), lineWidth: 1)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}

/// Applies tap and long press actions declared on the widget envelope.
/// Gestures are only attached for events the backend actually sent, so widgets
/// without actions stay completely passive.
///
/// A raw `onTapGesture` is invisible to assistive technology: it carries no trait
/// and exposes no action, so a VoiceOver user has no way to know the widget does
/// anything, let alone activate it. Every gesture attached here is mirrored as an
/// accessibility trait and action, and the widget's subviews are combined into one
/// element so it is announced as a single control rather than loose fragments.
private struct EnvelopeGestures: ViewModifier {
    let widget: AnyWidget
    let context: WidgetContext

    private var isTappable: Bool { widget.actions.tap != nil }
    private var isLongPressable: Bool { widget.actions.longPress != nil }
    private var isInteractive: Bool { isTappable || isLongPressable }

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .flowIf(isTappable) { view in
                view.onTapGesture { context.dispatch(event: "tap") }
            }
            .flowIf(isLongPressable) { view in
                view.onLongPressGesture { context.dispatch(event: "long_press") }
            }
            .flowIf(isInteractive) { view in
                view
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(isTappable ? .isButton : [])
                    .flowIf(isTappable) { inner in
                        inner.accessibilityAction { context.dispatch(event: "tap") }
                    }
                    .flowIf(isLongPressable) { inner in
                        inner.accessibilityAction(named: Text("Long press")) {
                            context.dispatch(event: "long_press")
                        }
                    }
            }
    }
}

private extension View {
    @ViewBuilder
    func flowIf<Modified: View>(_ condition: Bool, transform: (Self) -> Modified) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// Draws the widget's bounds, type and id when the debug layout inspector is on.
private struct LayoutInspection: ViewModifier {
    let widget: AnyWidget
    @Environment(\.flowLayoutInspection) private var inspecting

    func body(content: Content) -> some View {
        content
            .overlay {
                if inspecting {
                    Rectangle()
                        .strokeBorder(Color.blue.opacity(0.7), lineWidth: 1)
                        .overlay(alignment: .topLeading) {
                            Text("\(widget.type) · \(widget.id)")
                                .font(.system(size: 8).monospaced())
                                .padding(2)
                                .background(Color.blue.opacity(0.85))
                                .foregroundStyle(.white)
                        }
                        .allowsHitTesting(false)
                }
            }
    }
}
