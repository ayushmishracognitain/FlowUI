import SwiftUI
import FlowCore

/// Renders a `TextData` atom: font, color, alignment, line limit and optional Markdown.
public struct FlowText: View {
    private let data: TextData
    @Environment(\.flowTheme) private var theme
    // Read so the body re-evaluates when the user changes their text size, which
    // is what lets a backend supplied point size actually scale.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(_ data: TextData) {
        self.data = data
    }

    public var body: some View {
        textView
            .font(theme.font(data.font, fallback: theme.defaults.bodyFont))
            .foregroundStyle(theme.color(data.color, fallback: theme.defaults.textColor))
            .multilineTextAlignment(data.textAlignment)
            .lineLimit(lineLimit)
            .frame(maxWidth: .infinity, alignment: data.frameAlignment)
    }

    private var textView: Text {
        if data.isMarkdown == true,
           let attributed = try? AttributedString(
               markdown: data.text,
               options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
           ) {
            return Text(attributed)
        }
        return Text(data.text)
    }

    private var lineLimit: Int? {
        guard let maxLines = data.maxLines, maxLines > 0 else { return nil }
        return maxLines
    }
}

#Preview("FlowText", traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        FlowText(TextData(text: "Plain body text"))
        FlowText(TextData(
            text: "Big semibold title",
            font: FontData(size: 22, weight: "semibold")
        ))
        FlowText(TextData(
            text: "Colored, centered, two line maximum. This line is intentionally long "
                + "enough to wrap and then truncate somewhere sensible.",
            font: FontData(size: 14),
            color: ColorData(hex: "#E23744"),
            alignment: "center",
            maxLines: 2
        ))
        FlowText(TextData(text: "Supports **bold** and *italic* Markdown", isMarkdown: true))
    }
    .padding()
}
