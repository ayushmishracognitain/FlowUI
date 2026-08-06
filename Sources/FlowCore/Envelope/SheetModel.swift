import Foundation

/// Presentation options for a server driven bottom sheet.
public struct SheetConfig: Decodable, Sendable {
    /// Any of `"medium"`, `"large"`, or a height fraction such as `0.4`.
    public var detents: [JSONValue]?
    public var showsGrabber: Bool
    public var isDismissible: Bool
    public var cornerRadius: Double?

    private enum CodingKeys: String, CodingKey {
        case detents
        case showsGrabber = "grabber"
        case isDismissible = "dismissible"
        case cornerRadius = "corner_radius"
    }

    public init(
        detents: [JSONValue]? = nil,
        showsGrabber: Bool = true,
        isDismissible: Bool = true,
        cornerRadius: Double? = nil
    ) {
        self.detents = detents
        self.showsGrabber = showsGrabber
        self.isDismissible = isDismissible
        self.cornerRadius = cornerRadius
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        detents = try container.decodeIfPresent([JSONValue].self, forKey: .detents)
        showsGrabber = try container.decodeIfPresent(Bool.self, forKey: .showsGrabber) ?? true
        isDismissible = try container.decodeIfPresent(Bool.self, forKey: .isDismissible) ?? true
        cornerRadius = try container.decodeIfPresent(Double.self, forKey: .cornerRadius)
    }
}

/// One complete server driven bottom sheet: fixed header, scrolling sections, fixed footer.
public struct SheetModel: Identifiable, Decodable, Sendable {
    public var id: String
    public var header: PageBar?
    public var sections: [SectionModel]
    public var footer: PageBar?
    public var config: SheetConfig

    private enum CodingKeys: String, CodingKey {
        case id
        case header
        case sections
        case footer
        case config
    }

    public init(
        id: String = UUID().uuidString,
        header: PageBar? = nil,
        sections: [SectionModel] = [],
        footer: PageBar? = nil,
        config: SheetConfig = SheetConfig()
    ) {
        self.id = id
        self.header = header
        self.sections = sections
        self.footer = footer
        self.config = config
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Deliberately not the positional id used for widgets and sections. A sheet
        // id is presentation identity for `.sheet(item:)`, not list identity: two
        // different inline sheets both decoded from an action's `sheet` key sit at
        // the same coding path, and giving them a shared id would stop SwiftUI from
        // swapping one for the other.
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? "sheet.\(UUID().uuidString.prefix(8))"
        header = try container.decodeIfPresent(PageBar.self, forKey: .header)
        sections = try container.decodeIfPresent(LossyArray<SectionModel>.self, forKey: .sections)?.elements ?? []
        footer = try container.decodeIfPresent(PageBar.self, forKey: .footer)
        config = try container.decodeIfPresent(SheetConfig.self, forKey: .config) ?? SheetConfig()
    }
}

/// The root envelope of a bottom sheet response.
public struct SheetResponse: Decodable, Sendable {
    public let sheet: SheetModel

    public init(sheet: SheetModel) {
        self.sheet = sheet
    }
}
