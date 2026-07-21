import Foundation

/// A backend controlled tag or pill, for statuses, badges and filters.
public struct TagData: Codable, Hashable, Sendable {
    public var text: TextData
    public var backgroundColor: ColorData?
    public var borderColor: ColorData?
    public var cornerRadius: CornerRadiusData?
    public var icon: IconData?
    public var action: ActionData?

    private enum CodingKeys: String, CodingKey {
        case text
        case backgroundColor = "bg_color"
        case borderColor = "border_color"
        case cornerRadius = "corner_radius"
        case icon
        case action
    }

    public init(
        text: TextData,
        backgroundColor: ColorData? = nil,
        borderColor: ColorData? = nil,
        cornerRadius: CornerRadiusData? = nil,
        icon: IconData? = nil,
        action: ActionData? = nil
    ) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.icon = icon
        self.action = action
    }
}
