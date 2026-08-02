import SwiftUI
import FlowCore

/// Renders a `SeparatorData` atom: a solid line, a dashed line, or empty space.
public struct FlowSeparator: View {
    private let data: SeparatorData
    @Environment(\.flowTheme) private var theme

    public init(_ data: SeparatorData = SeparatorData()) {
        self.data = data
    }

    public var body: some View {
        let thickness = data.thickness ?? 1
        let color = theme.color(data.color, fallback: theme.defaults.separatorColor)

        Group {
            switch data.style ?? "line" {
            case "space":
                Color.clear.frame(height: thickness)
            case "dashed":
                DashedLine()
                    .stroke(color, style: StrokeStyle(lineWidth: thickness, dash: [4, 4]))
                    .frame(height: thickness)
            default:
                color.frame(height: thickness)
            }
        }
        .padding((data.insets ?? .zero).edgeInsets)
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

#Preview("FlowSeparator", traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        FlowSeparator()
        FlowSeparator(SeparatorData(style: "dashed", color: ColorData(hex: "#B5B5B5"), thickness: 1))
        FlowSeparator(SeparatorData(
            color: ColorData(hex: "#E23744"),
            thickness: 3,
            insets: EdgeInsetsData(left: 40, right: 40)
        ))
    }
    .padding()
}
