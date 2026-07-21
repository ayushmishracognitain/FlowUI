import Foundation

/// A backend declared interaction.
///
/// Actions are open by design: `type` is a free string agreed with the backend, and
/// the full JSON object is preserved so the handler that understands the type can
/// decode its own payload. FlowRender ships handlers for the common types
/// (`toast`, `dismiss`, `refresh_page`, `open_bottom_sheet`, `api`) and hosts
/// register handlers for everything else, deeplinks included.
public struct ActionData: Codable, Hashable, Sendable {
    public var type: String
    /// The complete action object, including `type`, kept for handler side decoding.
    public var raw: JSONValue

    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(type: String, raw: JSONValue? = nil) {
        self.type = type
        self.raw = raw ?? .object(["type": .string(type)])
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        raw = try JSONValue(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try raw.encode(to: encoder)
    }

    /// Decodes the whole action object into a typed payload model.
    public func payload<T: Decodable>(_ payloadType: T.Type) throws -> T {
        try raw.decoded(as: payloadType)
    }
}

/// The set of interactions a widget carries, keyed by event name.
///
/// Standard event names are `tap`, `long_press` and `change`; anything else the
/// backend sends is preserved and reachable through the subscript.
public struct WidgetActions: Codable, Hashable, Sendable {
    public var all: [String: ActionData]

    public static let none = WidgetActions(all: [:])

    public init(all: [String: ActionData] = [:]) {
        self.all = all
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        all = try container.decode([String: ActionData].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(all)
    }

    public subscript(event: String) -> ActionData? {
        all[event]
    }

    public var tap: ActionData? { all["tap"] }
    public var longPress: ActionData? { all["long_press"] }
    public var change: ActionData? { all["change"] }
}
