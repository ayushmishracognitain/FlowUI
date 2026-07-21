import SwiftUI
import FlowCore

/// Renders a `TagData` atom: a compact pill with optional icon and border.
public struct FlowTag: View {
    private let data: TagData
    @Environment(\.flowTheme) private var theme

    public init(_ data: TagData) {
        self.data = data
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon = data.icon {
                FlowIcon(icon)
            }
            Text(data.text.text)
                .font(theme.font(data.text.font, fallback: .caption.weight(.medium)))
        }
        .foregroundStyle(theme.color(data.text.color, fallback: theme.defaults.textColor))
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            theme.color(data.backgroundColor, fallback: theme.defaults.surfaceColor),
            in: UnevenRoundedRectangle(cornerRadii: cornerRadii)
        )
        .overlay {
            if let borderColor = theme.color(data.borderColor) {
                UnevenRoundedRectangle(cornerRadii: cornerRadii)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
        }
    }

    private var cornerRadii: RectangleCornerRadii {
        (data.cornerRadius ?? CornerRadiusData(uniform: 6)).rectangleCornerRadii
    }
}

#Preview("FlowTag", traits: .sizeThatFitsLayout) {
    HStack(spacing: 8) {
        FlowTag(TagData(
            text: TextData(text: "BESTSELLER", color: ColorData(hex: "#FFFFFF")),
            backgroundColor: ColorData(hex: "#E23744")
        ))
        FlowTag(TagData(
            text: TextData(text: "4.2", color: ColorData(hex: "#267E3E")),
            borderColor: ColorData(hex: "#267E3E"),
            icon: IconData(symbol: "star.fill", size: 10, color: ColorData(hex: "#267E3E"))
        ))
        FlowTag(TagData(text: TextData(text: "New")))
    }
    .padding()
}
