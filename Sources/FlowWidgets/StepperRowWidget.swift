import SwiftUI
import FlowCore
import FlowRender

/// `stepper_row`: a title with a quantity stepper.
///
/// The count is ephemeral UI state and lives in the page's `WidgetStateStore`, so
/// it survives scrolling out of a lazy container. Every change fires the widget's
/// `change` action with nothing extra to wire; the backend reads the new value
/// from the api action round trip.
///
/// ```jsonc
/// {
///   "type": "stepper_row",
///   "id": "item_42",
///   "data": { "title": "USB C Cable", "min": 0, "max": 10, "initial": 1 },
///   "actions": { "change": { "type": "api", "endpoint": "cart/update", "item": "42" } }
/// }
/// ```
public struct StepperRowContent: WidgetContent, Hashable {
    public static let widgetType = "stepper_row"
    public let title: TextData
    public let subtitle: TextData?
    public let min: Int?
    public let max: Int?
    public let initial: Int?

    public init(title: TextData, subtitle: TextData? = nil, min: Int? = nil, max: Int? = nil, initial: Int? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.min = min
        self.max = max
        self.initial = initial
    }
}

public struct StepperRowWidget: WidgetView {
    private let content: StepperRowContent
    private let context: WidgetContext
    @Environment(\.flowTheme) private var theme

    public init(content: StepperRowContent, context: WidgetContext) {
        self.content = content
        self.context = context
    }

    private var count: Binding<Int> {
        context.state.binding(widgetID: context.widgetID, key: "count", default: content.initial ?? 0)
    }

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                FlowText(content.title)
                if let subtitle = content.subtitle {
                    FlowText(subtitle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            stepper
        }
    }

    private var stepper: some View {
        HStack(spacing: 0) {
            stepButton(symbol: "minus", enabled: count.wrappedValue > (content.min ?? 0)) {
                update(count.wrappedValue - 1)
            }
            Text("\(count.wrappedValue)")
                .font(.subheadline.weight(.semibold))
                .frame(minWidth: 32)
                .monospacedDigit()
            stepButton(symbol: "plus", enabled: count.wrappedValue < (content.max ?? Int.max)) {
                update(count.wrappedValue + 1)
            }
        }
        .background(theme.defaults.surfaceColor, in: RoundedRectangle(cornerRadius: 8))
    }

    private func stepButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.footnote.weight(.bold))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? theme.defaults.accentColor : .secondary)
        .disabled(!enabled)
    }

    private func update(_ newValue: Int) {
        count.wrappedValue = newValue
        context.dispatch(event: "change")
    }
}

#Preview("stepper_row", traits: .sizeThatFitsLayout) {
    StepperRowWidget(
        content: StepperRowContent(
            title: TextData(text: "USB C Cable", font: FontData(size: 16, weight: "medium")),
            subtitle: TextData(text: "Braided, 1 m", color: ColorData(hex: "#767676")),
            min: 0,
            max: 10,
            initial: 1
        ),
        context: .inert()
    )
    .padding()
}
