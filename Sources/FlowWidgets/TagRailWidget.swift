import SwiftUI
import FlowCore
import FlowRender

/// `tag_rail`: a horizontally scrolling strip of tags, each optionally tappable.
///
/// ```jsonc
/// {
///   "type": "tag_rail",
///   "data": {
///     "tags": [
///       { "text": "All", "bg_color": "#E23744", "action": { "type": "api", "filter": "all" } },
///       { "text": "Audio" },
///       { "text": "Wearables" }
///     ]
///   }
/// }
/// ```
public struct TagRailContent: WidgetContent, Hashable {
    public static let widgetType = "tag_rail"
    public let tags: [TagData]

    public init(tags: [TagData]) {
        self.tags = tags
    }
}

public struct TagRailWidget: WidgetView {
    private let content: TagRailContent
    private let context: WidgetContext

    public init(content: TagRailContent, context: WidgetContext) {
        self.content = content
        self.context = context
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(content.tags.enumerated()), id: \.offset) { _, tag in
                    Button {
                        context.dispatch(tag.action)
                    } label: {
                        FlowTag(tag)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview("tag_rail", traits: .sizeThatFitsLayout) {
    TagRailWidget(
        content: TagRailContent(tags: [
            TagData(
                text: TextData(text: "All", color: ColorData(hex: "#FFFFFF")),
                backgroundColor: ColorData(hex: "#E23744"),
                cornerRadius: CornerRadiusData(uniform: 14)
            ),
            TagData(text: TextData(text: "Audio"), cornerRadius: CornerRadiusData(uniform: 14)),
            TagData(text: TextData(text: "Wearables"), cornerRadius: CornerRadiusData(uniform: 14)),
            TagData(text: TextData(text: "Laptops"), cornerRadius: CornerRadiusData(uniform: 14))
        ]),
        context: .inert()
    )
    .padding()
}
