import Foundation

/// What the backend returns from an `api` action: a list of page mutations and
/// an optional toast.
///
/// ```jsonc
/// {
///   "mutations": [
///     { "kind": "replace_widget", "id": "w_42", "widget": { ... } },
///     { "kind": "remove_widget", "id": "w_43" }
///   ],
///   "toast": { "message": "Saved" }
/// }
/// ```
public struct ActionResponse: Decodable, Sendable {
    public let mutations: [MutationInstruction]
    public let toast: ToastInstruction?

    private enum CodingKeys: String, CodingKey {
        case mutations
        case toast
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mutations = try container.decodeIfPresent(
            LossyArray<MutationInstruction>.self,
            forKey: .mutations
        )?.elements ?? []
        toast = try container.decodeIfPresent(ToastInstruction.self, forKey: .toast)
    }
}

public struct ToastInstruction: Decodable, Sendable {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

/// One backend instructed page change, discriminated by `kind`.
public enum MutationInstruction: Decodable, Sendable {
    case replacePage(PageModel)
    case appendSections([SectionModel])
    case prependSections([SectionModel])
    case replaceWidget(id: String, widget: AnyWidget)
    case removeWidget(id: String)

    private enum CodingKeys: String, CodingKey {
        case kind
        case id
        case widget
        case sections
        case page
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "replace_page":
            self = .replacePage(try container.decode(PageModel.self, forKey: .page))
        case "append_sections":
            self = .appendSections(try container.decode(LossyArray<SectionModel>.self, forKey: .sections).elements)
        case "prepend_sections":
            self = .prependSections(try container.decode(LossyArray<SectionModel>.self, forKey: .sections).elements)
        case "replace_widget":
            self = .replaceWidget(
                id: try container.decode(String.self, forKey: .id),
                widget: try container.decode(AnyWidget.self, forKey: .widget)
            )
        case "remove_widget":
            self = .removeWidget(id: try container.decode(String.self, forKey: .id))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "Unknown mutation kind '\(kind)'"
            )
        }
    }

    public var pageMutation: PageMutation {
        switch self {
        case .replacePage(let page): .replacePage(page)
        case .appendSections(let sections): .appendSections(sections)
        case .prependSections(let sections): .prependSections(sections)
        case .replaceWidget(let id, let widget): .replaceWidget(id: id, with: widget)
        case .removeWidget(let id): .removeWidget(id: id)
        }
    }
}
