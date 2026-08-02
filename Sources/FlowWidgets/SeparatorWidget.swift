import SwiftUI
import FlowCore
import FlowRender

/// `separator`: a backend placed divider.
///
/// ```jsonc
/// { "type": "separator", "data": { "style": "dashed", "insets": { "left": 16, "right": 16 } } }
/// ```
public struct SeparatorContent: WidgetContent, Hashable {
    public static let widgetType = "separator"
    public let separator: SeparatorData

    public init(separator: SeparatorData = SeparatorData()) {
        self.separator = separator
    }

    public init(from decoder: Decoder) throws {
        // The data object is the separator itself, no extra nesting.
        self.init(separator: try SeparatorData(from: decoder))
    }
}

public struct SeparatorWidget: WidgetView {
    private let content: SeparatorContent

    public init(content: SeparatorContent, context: WidgetContext) {
        self.content = content
    }

    public var body: some View {
        FlowSeparator(content.separator)
    }
}

#Preview("separator", traits: .sizeThatFitsLayout) {
    VStack(spacing: 24) {
        SeparatorWidget(content: SeparatorContent(), context: .inert())
        SeparatorWidget(
            content: SeparatorContent(
                separator: SeparatorData(
                    style: "dashed",
                    insets: EdgeInsetsData(left: 16, right: 16)
                )
            ),
            context: .inert()
        )
    }
    .padding(.vertical)
}
