import Foundation

/// A backend controlled remote image.
public struct ImageData: Codable, Hashable, Sendable {
    public var url: String
    /// Width divided by height. When present the image reserves this shape before loading.
    public var aspectRatio: Double?
    /// `fill` (default) or `fit`.
    public var scaleMode: String?
    public var cornerRadius: CornerRadiusData?
    /// Placeholder color shown while loading, resolved by the host theme.
    public var placeholderColor: ColorData?
    /// When true the placeholder animates with a shimmer sweep while loading.
    public var showShimmer: Bool?
    /// Alternative text announced by VoiceOver. An image with no `alt` is treated
    /// as decorative and hidden from assistive technology, which is the right
    /// default for backdrops but wrong for anything carrying meaning.
    public var alt: String?

    private enum CodingKeys: String, CodingKey {
        case url
        case aspectRatio = "aspect_ratio"
        case scaleMode = "scale_mode"
        case cornerRadius = "corner_radius"
        case placeholderColor = "placeholder_color"
        case showShimmer = "shimmer"
        case alt
    }

    public init(
        url: String,
        aspectRatio: Double? = nil,
        scaleMode: String? = nil,
        cornerRadius: CornerRadiusData? = nil,
        placeholderColor: ColorData? = nil,
        showShimmer: Bool? = nil,
        alt: String? = nil
    ) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.scaleMode = scaleMode
        self.cornerRadius = cornerRadius
        self.placeholderColor = placeholderColor
        self.showShimmer = showShimmer
        self.alt = alt
    }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let value = try? single.decode(String.self) {
            self.init(url: value)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            url: try container.decode(String.self, forKey: .url),
            aspectRatio: try container.decodeIfPresent(Double.self, forKey: .aspectRatio),
            scaleMode: try container.decodeIfPresent(String.self, forKey: .scaleMode),
            cornerRadius: try container.decodeIfPresent(CornerRadiusData.self, forKey: .cornerRadius),
            placeholderColor: try container.decodeIfPresent(ColorData.self, forKey: .placeholderColor),
            showShimmer: try container.decodeIfPresent(Bool.self, forKey: .showShimmer),
            alt: try container.decodeIfPresent(String.self, forKey: .alt)
        )
    }
}
