import Foundation

/// Corner rounding sent by the backend.
///
/// Accepts two JSON shapes so the common case stays terse:
/// a bare number (`"corner_radius": 12`) rounds every corner uniformly, and an
/// object (`{"top_left": 12, "top_right": 12}`) controls corners individually.
public struct CornerRadiusData: Codable, Hashable, Sendable {
    public var topLeft: Double
    public var topRight: Double
    public var bottomLeft: Double
    public var bottomRight: Double

    public static let zero = CornerRadiusData()

    public init(topLeft: Double = 0, topRight: Double = 0, bottomLeft: Double = 0, bottomRight: Double = 0) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }

    public init(uniform radius: Double) {
        self.init(topLeft: radius, topRight: radius, bottomLeft: radius, bottomRight: radius)
    }

    private enum CodingKeys: String, CodingKey {
        case topLeft = "top_left"
        case topRight = "top_right"
        case bottomLeft = "bottom_left"
        case bottomRight = "bottom_right"
    }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let uniform = try? single.decode(Double.self) {
            self.init(uniform: uniform)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            topLeft: try container.decodeIfPresent(Double.self, forKey: .topLeft) ?? 0,
            topRight: try container.decodeIfPresent(Double.self, forKey: .topRight) ?? 0,
            bottomLeft: try container.decodeIfPresent(Double.self, forKey: .bottomLeft) ?? 0,
            bottomRight: try container.decodeIfPresent(Double.self, forKey: .bottomRight) ?? 0
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(topLeft, forKey: .topLeft)
        try container.encode(topRight, forKey: .topRight)
        try container.encode(bottomLeft, forKey: .bottomLeft)
        try container.encode(bottomRight, forKey: .bottomRight)
    }

    public var isZero: Bool {
        topLeft == 0 && topRight == 0 && bottomLeft == 0 && bottomRight == 0
    }

    /// The single radius when all corners agree, useful for simple clip shapes.
    public var uniformValue: Double? {
        guard topLeft == topRight, topRight == bottomLeft, bottomLeft == bottomRight else { return nil }
        return topLeft
    }
}
