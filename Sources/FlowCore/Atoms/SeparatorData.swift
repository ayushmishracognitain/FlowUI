import Foundation

/// A backend controlled separator between widgets.
public struct SeparatorData: Codable, Hashable, Sendable {
    /// One of `line` (default), `dashed`, `space`.
    public var style: String?
    public var color: ColorData?
    public var thickness: Double?
    public var insets: EdgeInsetsData?

    public init(
        style: String? = nil,
        color: ColorData? = nil,
        thickness: Double? = nil,
        insets: EdgeInsetsData? = nil
    ) {
        self.style = style
        self.color = color
        self.thickness = thickness
        self.insets = insets
    }
}
