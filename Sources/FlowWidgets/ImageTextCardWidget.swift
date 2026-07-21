import SwiftUI
import FlowCore
import FlowRender

/// `image_text_card`: the workhorse list row. Leading image, title, subtitle,
/// optional tags and a trailing chevron or icon.
///
/// ```jsonc
/// {
///   "type": "image_text_card",
///   "data": {
///     "image": { "url": "https://…", "aspect_ratio": 1, "corner_radius": 10 },
///     "title": "AirPods Pro 2",
///     "subtitle": { "text": "Active noise cancellation", "color": "#767676" },
///     "tags": [{ "text": "BESTSELLER" }],
///     "trailing_icon": "chevron.right"
///   },
///   "actions": { "tap": { "type": "open_bottom_sheet", "sheet": { … } } }
/// }
/// ```
public struct ImageTextCardContent: WidgetContent, Hashable {
    public static let widgetType = "image_text_card"
    public let image: ImageData?
    public let title: TextData
    public let subtitle: TextData?
    public let tags: [TagData]?
    public let trailingIcon: IconData?

    private enum CodingKeys: String, CodingKey {
        case image
        case title
        case subtitle
        case tags
        case trailingIcon = "trailing_icon"
    }

    public init(
        image: ImageData? = nil,
        title: TextData,
        subtitle: TextData? = nil,
        tags: [TagData]? = nil,
        trailingIcon: IconData? = nil
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.tags = tags
        self.trailingIcon = trailingIcon
    }
}

public struct ImageTextCardWidget: WidgetView, WidgetSkeletonProviding {
    private let content: ImageTextCardContent

    public init(content: ImageTextCardContent, context: WidgetContext) {
        self.content = content
    }

    public var body: some View {
        HStack(spacing: 12) {
            if let image = content.image {
                FlowImage(image)
                    .frame(width: 72, height: 72)
            }
            VStack(alignment: .leading, spacing: 4) {
                FlowText(content.title)
                if let subtitle = content.subtitle {
                    FlowText(subtitle)
                }
                if let tags = content.tags, !tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                            FlowTag(tag)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let trailing = content.trailingIcon {
                FlowIcon(trailing)
            }
        }
    }

    public static func skeleton() -> AnyView {
        AnyView(
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                        .padding(.trailing, 60)
                }
            }
            .flowShimmer()
        )
    }
}

#Preview("image_text_card", traits: .sizeThatFitsLayout) {
    ImageTextCardWidget(
        content: ImageTextCardContent(
            image: ImageData(url: "https://picsum.photos/id/9/144", aspectRatio: 1, cornerRadius: CornerRadiusData(uniform: 10)),
            title: TextData(text: "AirPods Pro 2", font: FontData(size: 16, weight: "semibold")),
            subtitle: TextData(text: "Active noise cancellation", color: ColorData(hex: "#767676")),
            tags: [TagData(
                text: TextData(text: "BESTSELLER", color: ColorData(hex: "#FFFFFF")),
                backgroundColor: ColorData(hex: "#E23744")
            )],
            trailingIcon: IconData(symbol: "chevron.right", size: 13, color: ColorData(hex: "#B5B5B5"))
        ),
        context: .inert()
    )
    .padding()
}
