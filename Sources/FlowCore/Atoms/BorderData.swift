import Foundation

/// A backend controlled border stroke.
public struct BorderData: Codable, Hashable, Sendable {
    public var width: Double?
    public var color: ColorData?
    /// When both dash values are present the stroke renders dashed.
    public var dashWidth: Double?
    public var dashGap: Double?

    private enum CodingKeys: String, CodingKey {
        case width
        case color
        case dashWidth = "dash_width"
        case dashGap = "dash_gap"
    }

    public init(width: Double? = nil, color: ColorData? = nil, dashWidth: Double? = nil, dashGap: Double? = nil) {
        self.width = width
        self.color = color
        self.dashWidth = dashWidth
        self.dashGap = dashGap
    }
}
