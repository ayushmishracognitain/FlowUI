import Foundation

/// A backend controlled piece of text.
///
/// The smallest and most common atom. A bare JSON string is accepted as shorthand
/// (`"title": "Hello"`), so simple payloads stay simple while full control remains
/// available through the object form.
public struct TextData: Codable, Hashable, Sendable {
    public var text: String
    public var font: FontData?
    public var color: ColorData?
    /// One of `leading`, `center`, `trailing`. Also accepts `left` and `right`.
    public var alignment: String?
    /// Maximum number of lines, `nil` or `0` means unlimited.
    public var maxLines: Int?
    /// When true the text is parsed as Markdown before rendering.
    public var isMarkdown: Bool?

    private enum CodingKeys: String, CodingKey {
        case text
        case font
        case color
        case alignment
        case maxLines = "max_lines"
        case isMarkdown = "is_markdown"
    }

    public init(
        text: String,
        font: FontData? = nil,
        color: ColorData? = nil,
        alignment: String? = nil,
        maxLines: Int? = nil,
        isMarkdown: Bool? = nil
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.alignment = alignment
        self.maxLines = maxLines
        self.isMarkdown = isMarkdown
    }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(), let value = try? single.decode(String.self) {
            self.init(text: value)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            text: try container.decode(String.self, forKey: .text),
            font: try container.decodeIfPresent(FontData.self, forKey: .font),
            color: try container.decodeIfPresent(ColorData.self, forKey: .color),
            alignment: try container.decodeIfPresent(String.self, forKey: .alignment),
            maxLines: try container.decodeIfPresent(Int.self, forKey: .maxLines),
            isMarkdown: try container.decodeIfPresent(Bool.self, forKey: .isMarkdown)
        )
    }
}
