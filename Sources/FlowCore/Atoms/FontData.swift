import Foundation

/// A backend controlled font.
///
/// Either a raw `size` plus `weight` pair, or a design system `token` such as
/// `"title.large"` that the host theme resolves. When both are present the token wins.
public struct FontData: Codable, Hashable, Sendable {
    public var size: Double?
    /// One of `regular`, `medium`, `semibold`, `bold`, `heavy`. Unknown values fall back to regular.
    public var weight: String?
    public var token: String?

    public init(size: Double? = nil, weight: String? = nil, token: String? = nil) {
        self.size = size
        self.weight = weight
        self.token = token
    }
}
