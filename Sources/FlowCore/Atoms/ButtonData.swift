import Foundation

/// A backend controlled button.
public struct ButtonData: Codable, Hashable, Sendable {
    public var title: TextData
    /// One of `solid` (default), `outline`, `plain`.
    public var style: String?
    public var backgroundColor: ColorData?
    public var cornerRadius: CornerRadiusData?
    public var icon: IconData?
    /// When true the button stretches to the full available width.
    public var isFullWidth: Bool?
    public var isDisabled: Bool?
    public var action: ActionData?

    private enum CodingKeys: String, CodingKey {
        case title
        case style
        case backgroundColor = "bg_color"
        case cornerRadius = "corner_radius"
        case icon
        case isFullWidth = "full_width"
        case isDisabled = "disabled"
        case action
    }

    public init(
        title: TextData,
        style: String? = nil,
        backgroundColor: ColorData? = nil,
        cornerRadius: CornerRadiusData? = nil,
        icon: IconData? = nil,
        isFullWidth: Bool? = nil,
        isDisabled: Bool? = nil,
        action: ActionData? = nil
    ) {
        self.title = title
        self.style = style
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.icon = icon
        self.isFullWidth = isFullWidth
        self.isDisabled = isDisabled
        self.action = action
    }
}
