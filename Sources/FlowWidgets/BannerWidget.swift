import SwiftUI
import FlowCore
import FlowRender

/// `banner`: a full width image with optional overlaid text, for promotions and
/// campaign strips. Pairs naturally with a carousel section.
///
/// ```jsonc
/// {
///   "type": "banner",
///   "data": {
///     "image": { "url": "https://…", "aspect_ratio": 2.2, "shimmer": true },
///     "title": { "text": "50% off first order", "color": "#FFFFFF", "font": { "size": 22, "weight": "bold" } },
///     "subtitle": { "text": "Use code WELCOME", "color": "#FFFFFFCC" }
///   },
///   "actions": { "tap": { "type": "deeplink", "url": "app://offers" } }
/// }
/// ```
public struct BannerContent: WidgetContent, Hashable {
    public static let widgetType = "banner"
    public let image: ImageData
    public let title: TextData?
    public let subtitle: TextData?

    public init(image: ImageData, title: TextData? = nil, subtitle: TextData? = nil) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
    }
}

public struct BannerWidget: WidgetView, WidgetSkeletonProviding {
    private let content: BannerContent

    public init(content: BannerContent, context: WidgetContext) {
        self.content = content
    }

    public var body: some View {
        FlowImage(content.image)
            .overlay(alignment: .bottomLeading) {
                if content.title != nil || content.subtitle != nil {
                    VStack(alignment: .leading, spacing: 2) {
                        if let title = content.title {
                            FlowText(title)
                        }
                        if let subtitle = content.subtitle {
                            FlowText(subtitle)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.55)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            }
            .clipShape(UnevenRoundedRectangle(
                cornerRadii: (content.image.cornerRadius ?? .zero).rectangleCornerRadii
            ))
    }

    public static func skeleton() -> AnyView {
        AnyView(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.28))
                .aspectRatio(2.2, contentMode: .fit)
                .flowShimmer()
        )
    }
}

#Preview("banner", traits: .sizeThatFitsLayout) {
    BannerWidget(
        content: BannerContent(
            image: ImageData(url: "https://picsum.photos/800/360", aspectRatio: 2.2, cornerRadius: CornerRadiusData(uniform: 14)),
            title: TextData(
                text: "50% off first order",
                font: FontData(size: 22, weight: "bold"),
                color: ColorData(hex: "#FFFFFF")
            ),
            subtitle: TextData(text: "Use code WELCOME", color: ColorData(hex: "#FFFFFFCC"))
        ),
        context: .inert()
    )
    .padding()
}
