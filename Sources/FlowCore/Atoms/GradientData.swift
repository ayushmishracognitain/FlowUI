import Foundation

/// A backend controlled linear gradient.
///
/// `angle` is in degrees, measured clockwise from a left to right sweep, so `0`
/// flows leading to trailing and `90` flows top to bottom.
public struct GradientData: Codable, Hashable, Sendable {
    public var colors: [ColorData]
    public var angle: Double?

    public init(colors: [ColorData], angle: Double? = nil) {
        self.colors = colors
        self.angle = angle
    }
}
