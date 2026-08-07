import SwiftUI
import FlowCore

/// Renders a `ButtonData` atom in one of three styles: `solid`, `outline`, `plain`.
///
/// The tap handler is injected. Widgets normally pass the button's `action` to the
/// dispatcher through their `WidgetContext`; previews and tests can pass anything.
public struct FlowButton: View {
    private let data: ButtonData
    private let onTap: () -> Void
    @Environment(\.flowTheme) private var theme

    public init(_ data: ButtonData, onTap: @escaping () -> Void = {}) {
        self.data = data
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            label
        }
        .buttonStyle(.plain)
        .disabled(data.isDisabled ?? false)
        .opacity(data.isDisabled == true ? 0.5 : 1)
    }

    private var accent: Color {
        theme.color(data.backgroundColor, fallback: theme.defaults.accentColor)
    }

    private var cornerRadii: RectangleCornerRadii {
        (data.cornerRadius ?? CornerRadiusData(uniform: theme.defaults.cornerRadius)).rectangleCornerRadii
    }

    @ViewBuilder
    private var label: some View {
        let content = HStack(spacing: 6) {
            if let icon = data.icon {
                FlowIcon(icon)
            }
            Text(data.title.text)
                .font(theme.font(data.title.font, fallback: .body.weight(.semibold)))
        }
        .frame(maxWidth: data.isFullWidth == true ? .infinity : nil)

        switch data.style ?? "solid" {
        case "outline":
            content
                .foregroundStyle(theme.color(data.title.color, fallback: accent))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .overlay {
                    UnevenRoundedRectangle(cornerRadii: cornerRadii)
                        .strokeBorder(accent, lineWidth: 1.5)
                }
                .contentShape(UnevenRoundedRectangle(cornerRadii: cornerRadii))
        case "plain":
            content
                .foregroundStyle(theme.color(data.title.color, fallback: accent))
        default:
            content
                .foregroundStyle(theme.color(data.title.color, fallback: .white))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(accent, in: UnevenRoundedRectangle(cornerRadii: cornerRadii))
        }
    }
}

#Preview("FlowButton", traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        FlowButton(ButtonData(
            title: TextData(text: "Place order"),
            backgroundColor: ColorData(hex: "#4F8CFF"),
            isFullWidth: true
        ))
        FlowButton(ButtonData(title: TextData(text: "Outlined"), style: "outline"))
        FlowButton(ButtonData(title: TextData(text: "Plain link"), style: "plain"))
        FlowButton(ButtonData(title: TextData(text: "Disabled"), isDisabled: true))
    }
    .padding()
}
