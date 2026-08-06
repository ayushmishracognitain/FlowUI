import Foundation

/// How a section arranges its widgets.
public struct SectionLayout: Codable, Hashable, Sendable {
    public enum Arrangement: String, Codable, Sendable {
        case vertical
        case carousel
        case grid

        /// Unknown strings fall back to `vertical` so old clients render new
        /// arrangements as a plain list instead of nothing.
        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Arrangement(rawValue: raw) ?? .vertical
        }
    }

    public var arrangement: Arrangement
    /// Grid column count, ignored by other arrangements. Defaults to 2.
    public var columns: Int?
    /// Spacing between widgets in points.
    public var itemSpacing: Double?
    /// Space around the whole section.
    public var insets: EdgeInsetsData?

    private enum CodingKeys: String, CodingKey {
        case arrangement
        case columns
        case itemSpacing = "item_spacing"
        case insets
    }

    public init(
        arrangement: Arrangement = .vertical,
        columns: Int? = nil,
        itemSpacing: Double? = nil,
        insets: EdgeInsetsData? = nil
    ) {
        self.arrangement = arrangement
        self.columns = columns
        self.itemSpacing = itemSpacing
        self.insets = insets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        arrangement = try container.decodeIfPresent(Arrangement.self, forKey: .arrangement) ?? .vertical
        columns = try container.decodeIfPresent(Int.self, forKey: .columns)
        itemSpacing = try container.decodeIfPresent(Double.self, forKey: .itemSpacing)
        insets = try container.decodeIfPresent(EdgeInsetsData.self, forKey: .insets)
    }
}

/// A group of widgets sharing one arrangement, with an optional pinned header widget.
public struct SectionModel: Identifiable, Decodable, Sendable {
    public var id: String
    public var layout: SectionLayout
    /// Rendered as a sticky header that pins while the section scrolls under it.
    public var header: AnyWidget?
    public var widgets: [AnyWidget]

    private enum CodingKeys: String, CodingKey {
        case id
        case layout
        case header
        case widgets
    }

    public init(
        id: String,
        layout: SectionLayout = SectionLayout(),
        header: AnyWidget? = nil,
        widgets: [AnyWidget] = []
    ) {
        self.id = id
        self.layout = layout
        self.header = header
        self.widgets = widgets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? FlowIdentity.positional("section", in: container.codingPath)
        layout = try container.decodeIfPresent(SectionLayout.self, forKey: .layout) ?? SectionLayout()
        header = try container.decodeIfPresent(AnyWidget.self, forKey: .header)
        widgets = try container.decodeIfPresent(LossyArray<AnyWidget>.self, forKey: .widgets)?.elements ?? []
    }
}
