import Foundation

/// A backend controlled color.
///
/// Resolution is a host concern (see `ThemeProvider` in FlowRender). The intended
/// priority is: design token first, then explicit hex values, then nothing.
/// `dark_hex` lets the backend pin a different color for dark appearance when it
/// is not using tokens.
public struct ColorData: Codable, Hashable, Sendable {
    /// Hex string such as `"#FF5722"` or `"#80FF5722"` (alpha first when 8 digits).
    public var hex: String?
    /// Optional dark appearance override for `hex`.
    public var darkHex: String?
    /// A design system token such as `"surface.primary"`, resolved by the host theme.
    public var token: String?
    /// Opacity multiplier in the 0...1 range applied after resolution.
    public var alpha: Double?

    private enum CodingKeys: String, CodingKey {
        case hex
        case darkHex = "dark_hex"
        case token
        case alpha
    }

    public init(hex: String? = nil, darkHex: String? = nil, token: String? = nil, alpha: Double? = nil) {
        self.hex = hex
        self.darkHex = darkHex
        self.token = token
        self.alpha = alpha
    }

    public init(from decoder: Decoder) throws {
        // A bare string is accepted as shorthand for a hex color.
        if let single = try? decoder.singleValueContainer(), let value = try? single.decode(String.self) {
            self.init(hex: value)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            hex: try container.decodeIfPresent(String.self, forKey: .hex),
            darkHex: try container.decodeIfPresent(String.self, forKey: .darkHex),
            token: try container.decodeIfPresent(String.self, forKey: .token),
            alpha: try container.decodeIfPresent(Double.self, forKey: .alpha)
        )
    }
}
