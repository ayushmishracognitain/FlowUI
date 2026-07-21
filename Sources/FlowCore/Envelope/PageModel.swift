import Foundation

/// Navigation bar configuration for a page.
public struct NavModel: Decodable, Sendable {
    public var title: TextData?
    public var subtitle: TextData?
    public var backgroundColor: ColorData?
    public var leftButton: ButtonData?
    public var rightButtons: [ButtonData]?

    private enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case backgroundColor = "bg_color"
        case leftButton = "left_button"
        case rightButtons = "right_buttons"
    }

    public init(
        title: TextData? = nil,
        subtitle: TextData? = nil,
        backgroundColor: ColorData? = nil,
        leftButton: ButtonData? = nil,
        rightButtons: [ButtonData]? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.backgroundColor = backgroundColor
        self.leftButton = leftButton
        self.rightButtons = rightButtons
    }
}

/// A widget strip used for page headers and footers.
///
/// When `sticky` is true the bar pins outside the scrolling area; otherwise it
/// scrolls with the content.
public struct PageBar: Decodable, Sendable {
    public var widgets: [AnyWidget]
    public var sticky: Bool

    private enum CodingKeys: String, CodingKey {
        case widgets
        case sticky
    }

    public init(widgets: [AnyWidget] = [], sticky: Bool = true) {
        self.widgets = widgets
        self.sticky = sticky
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        widgets = try container.decodeIfPresent(LossyArray<AnyWidget>.self, forKey: .widgets)?.elements ?? []
        sticky = try container.decodeIfPresent(Bool.self, forKey: .sticky) ?? true
    }
}

/// Backend controlled pagination.
///
/// `postback` is opaque to the client: whatever the backend sends here is echoed
/// on the next page request, so cursors can be any shape the backend likes.
public struct PaginationModel: Decodable, Sendable {
    public var hasMore: Bool
    public var postback: JSONValue?

    private enum CodingKeys: String, CodingKey {
        case hasMore = "has_more"
        case postback
    }

    public init(hasMore: Bool, postback: JSONValue? = nil) {
        self.hasMore = hasMore
        self.postback = postback
    }
}

/// Backend controlled refresh behavior.
public struct RefreshModel: Decodable, Sendable {
    public var pullToRefresh: Bool

    private enum CodingKeys: String, CodingKey {
        case pullToRefresh = "pull_to_refresh"
    }

    public init(pullToRefresh: Bool = true) {
        self.pullToRefresh = pullToRefresh
    }
}

/// One complete server driven screen.
public struct PageModel: Decodable, Sendable {
    public var id: String
    public var nav: NavModel?
    public var header: PageBar?
    public var sections: [SectionModel]
    public var footer: PageBar?
    public var pagination: PaginationModel?
    public var refresh: RefreshModel?

    private enum CodingKeys: String, CodingKey {
        case id
        case nav
        case header
        case sections
        case footer
        case pagination
        case refresh
    }

    public init(
        id: String,
        nav: NavModel? = nil,
        header: PageBar? = nil,
        sections: [SectionModel] = [],
        footer: PageBar? = nil,
        pagination: PaginationModel? = nil,
        refresh: RefreshModel? = nil
    ) {
        self.id = id
        self.nav = nav
        self.header = header
        self.sections = sections
        self.footer = footer
        self.pagination = pagination
        self.refresh = refresh
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? "page.\(UUID().uuidString.prefix(8))"
        nav = try container.decodeIfPresent(NavModel.self, forKey: .nav)
        header = try container.decodeIfPresent(PageBar.self, forKey: .header)
        sections = try container.decodeIfPresent(LossyArray<SectionModel>.self, forKey: .sections)?.elements ?? []
        footer = try container.decodeIfPresent(PageBar.self, forKey: .footer)
        pagination = try container.decodeIfPresent(PaginationModel.self, forKey: .pagination)
        refresh = try container.decodeIfPresent(RefreshModel.self, forKey: .refresh)
    }

    /// All widgets across header, sections and footer, in render order.
    public var allWidgets: [AnyWidget] {
        (header?.widgets ?? []) + sections.flatMap { widgets(in: $0) } + (footer?.widgets ?? [])
    }

    private func widgets(in section: SectionModel) -> [AnyWidget] {
        if let header = section.header {
            return [header] + section.widgets
        }
        return section.widgets
    }
}

/// The root envelope of a page response.
public struct PageResponse: Decodable, Sendable {
    public let page: PageModel

    public init(page: PageModel) {
        self.page = page
    }
}
