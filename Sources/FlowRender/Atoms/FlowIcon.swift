import SwiftUI
import FlowCore

/// Renders an `IconData` atom as an SF Symbol.
public struct FlowIcon: View {
    private let data: IconData
    @Environment(\.flowTheme) private var theme
    // Read so the glyph rescales with the user's text size instead of staying
    // pinned while the text beside it grows.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(_ data: IconData) {
        self.data = data
    }

    public var body: some View {
        Image(systemName: data.symbol)
            .font(.system(size: scaledSize))
            .foregroundStyle(theme.color(data.color, fallback: theme.defaults.textColor))
            // Icons sit next to the text they describe and are decorative by
            // default; a backend that needs one announced gives it an action.
            .accessibilityHidden(data.action == nil)
    }

    private var scaledSize: Double {
        let size = data.size ?? 17
        guard theme.defaults.scalesFontsWithDynamicType else { return size }
        return FlowFontScaling.scaledIcon(size)
    }
}

#Preview("FlowIcon", traits: .sizeThatFitsLayout) {
    HStack(spacing: 16) {
        FlowIcon(IconData(symbol: "star.fill", size: 24, color: ColorData(hex: "#F5A623")))
        FlowIcon(IconData(symbol: "chevron.right", size: 14))
        FlowIcon(IconData(symbol: "cart", size: 20, color: ColorData(hex: "#4F8CFF")))
    }
    .padding()
}
