import SwiftUI
import FlowCore

/// Builds SwiftUI gradients from `GradientData`.
public enum FlowGradient {
    /// Converts the backend's degree based angle into a linear gradient.
    /// `0` flows leading to trailing, `90` flows top to bottom.
    public static func linear(_ data: GradientData, theme: any ThemeProvider) -> LinearGradient {
        let colors = data.colors.compactMap { theme.color($0) }
        let radians = (data.angle ?? 0) * .pi / 180
        let dx = cos(radians) / 2
        let dy = sin(radians) / 2
        return LinearGradient(
            colors: colors.isEmpty ? [.clear] : colors,
            startPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy),
            endPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy)
        )
    }
}

/// A view rendering a `GradientData` fill, handy inside custom widgets.
public struct FlowGradientView: View {
    private let data: GradientData
    @Environment(\.flowTheme) private var theme

    public init(_ data: GradientData) {
        self.data = data
    }

    public var body: some View {
        FlowGradient.linear(data, theme: theme)
    }
}

#Preview("FlowGradient", traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        FlowGradientView(GradientData(
            colors: [ColorData(hex: "#FF512F"), ColorData(hex: "#DD2476")],
            angle: 0
        ))
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        FlowGradientView(GradientData(
            colors: [ColorData(hex: "#1D976C"), ColorData(hex: "#93F9B9")],
            angle: 90
        ))
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}
