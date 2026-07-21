import Foundation

/// A backend controlled icon, addressed as an SF Symbol name.
///
/// Hosts that ship a custom icon font can interpret `symbol` however they like by
/// overriding the icon resolution in their theme, but the default renderer treats
/// it as an SF Symbol.
public struct IconData: Codable, Hashable, Sendable {
    public var symbol: String
    public var size: Double?
    public var color: ColorData?
    public var action: ActionData?

    private enum CodingKeys: String, CodingKey {
        case symbol
        case size
        case color
        case action
    }

    public init(symbol: String, size: Double? = nil, color: ColorData? = nil, action: ActionData? = nil) {
        self.symbol = symbol
        self.size = size
        self.color = color
        self.action = action
    }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let value = try? single.decode(String.self) {
            self.init(symbol: value)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            symbol: try container.decode(String.self, forKey: .symbol),
            size: try container.decodeIfPresent(Double.self, forKey: .size),
            color: try container.decodeIfPresent(ColorData.self, forKey: .color),
            action: try container.decodeIfPresent(ActionData.self, forKey: .action)
        )
    }
}
