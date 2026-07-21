import Foundation

/// Directional spacing sent by the backend, used for margins, padding and section insets.
///
/// Every side is optional in JSON and defaults to zero, so the backend only sends
/// the sides it wants to control.
public struct EdgeInsetsData: Codable, Hashable, Sendable {
    public var top: Double
    public var left: Double
    public var right: Double
    public var bottom: Double

    public static let zero = EdgeInsetsData()

    public init(top: Double = 0, left: Double = 0, right: Double = 0, bottom: Double = 0) {
        self.top = top
        self.left = left
        self.right = right
        self.bottom = bottom
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        top = try container.decodeIfPresent(Double.self, forKey: .top) ?? 0
        left = try container.decodeIfPresent(Double.self, forKey: .left) ?? 0
        right = try container.decodeIfPresent(Double.self, forKey: .right) ?? 0
        bottom = try container.decodeIfPresent(Double.self, forKey: .bottom) ?? 0
    }

    public var isZero: Bool {
        top == 0 && left == 0 && right == 0 && bottom == 0
    }
}
