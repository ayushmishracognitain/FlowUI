import SwiftUI
import FlowCore
import FlowRender

/// `title_block`: a heading with an optional subtitle. The usual section opener.
///
/// ```jsonc
/// {
///   "type": "title_block",
///   "data": {
///     "title": { "text": "Popular this week", "font": { "size": 20, "weight": "bold" } },
///     "subtitle": "Curated for your taste"
///   }
/// }
/// ```
public struct TitleBlockContent: WidgetContent, Hashable {
    public static let widgetType = "title_block"
    public let title: TextData
    public let subtitle: TextData?

    private enum CodingKeys: String, CodingKey {
        case title
        case subtitle
    }

    public init(title: TextData, subtitle: TextData? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            title: try container.decode(TextData.self, forKey: .title),
            subtitle: try container.decodeIfPresent(TextData.self, forKey: .subtitle)
        )
    }
}

public struct TitleBlockWidget: WidgetView, WidgetSkeletonProviding {
    private let content: TitleBlockContent

    public init(content: TitleBlockContent, context: WidgetContext) {
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FlowText(content.title)
            if let subtitle = content.subtitle {
                FlowText(subtitle)
            }
        }
    }

    public static func skeleton() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 18)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .flowShimmer()
        )
    }
}

#Preview("title_block", traits: .sizeThatFitsLayout) {
    TitleBlockWidget(
        content: TitleBlockContent(
            title: TextData(text: "Popular this week", font: FontData(size: 20, weight: "bold")),
            subtitle: TextData(text: "Curated for your taste", color: ColorData(hex: "#767676"))
        ),
        context: .inert()
    )
    .padding()
}
