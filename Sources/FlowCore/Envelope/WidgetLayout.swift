import Foundation

/// How wide a widget wants to be inside its arrangement.
///
/// JSON accepts `"fill"`, `"hug"`, or a fraction of the container width as a number
/// or numeric string, for example `0.75`. Fractions matter most inside carousels,
/// where they produce peeking cards.
public enum WidgetWidth: Hashable, Sendable, Codable {
    case fill
    case hug
    case fraction(Double)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) {
            self = .fraction(number)
            return
        }
        let string = try container.decode(String.self)
        switch string {
        case "fill":
            self = .fill
        case "hug":
            self = .hug
        default:
            if let number = Double(string) {
                self = .fraction(number)
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Width must be 'fill', 'hug' or a fraction, got '\(string)'"
                )
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fill: try container.encode("fill")
        case .hug: try container.encode("hug")
        case .fraction(let value): try container.encode(value)
        }
    }
}

/// Everything the backend controls about a widget's chrome: spacing, shape and fill.
///
/// The renderer applies these in a fixed order, from the inside out:
/// padding, then background or gradient, then corner clipping, then border, then margin.
public struct WidgetLayout: Codable, Hashable, Sendable {
    /// Space outside the widget's background.
    public var margin: EdgeInsetsData?
    /// Space between the widget's content and its background edge.
    public var padding: EdgeInsetsData?
    public var cornerRadius: CornerRadiusData?
    public var background: ColorData?
    /// Painted over `background` when present.
    public var gradient: GradientData?
    public var border: BorderData?
    public var width: WidgetWidth?

    private enum CodingKeys: String, CodingKey {
        case margin
        case padding
        case cornerRadius = "corner_radius"
        case background
        case gradient
        case border
        case width
    }

    public init(
        margin: EdgeInsetsData? = nil,
        padding: EdgeInsetsData? = nil,
        cornerRadius: CornerRadiusData? = nil,
        background: ColorData? = nil,
        gradient: GradientData? = nil,
        border: BorderData? = nil,
        width: WidgetWidth? = nil
    ) {
        self.margin = margin
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.background = background
        self.gradient = gradient
        self.border = border
        self.width = width
    }
}
