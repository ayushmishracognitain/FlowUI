import SwiftUI
import FlowCore

/// Renders an `IconData` atom as an SF Symbol.
public struct FlowIcon: View {
    private let data: IconData
    @Environment(\.flowTheme) private var theme

    public init(_ data: IconData) {
        self.data = data
    }

    public var body: some View {
        Image(systemName: data.symbol)
            .font(.system(size: data.size ?? 17))
            .foregroundStyle(theme.color(data.color, fallback: theme.defaults.textColor))
    }
}

#Preview("FlowIcon", traits: .sizeThatFitsLayout) {
    HStack(spacing: 16) {
        FlowIcon(IconData(symbol: "star.fill", size: 24, color: ColorData(hex: "#F5A623")))
        FlowIcon(IconData(symbol: "chevron.right", size: 14))
        FlowIcon(IconData(symbol: "cart", size: 20, color: ColorData(hex: "#E23744")))
    }
    .padding()
}
