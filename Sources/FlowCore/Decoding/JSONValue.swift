import Foundation

/// A type safe representation of an arbitrary JSON fragment.
///
/// Server driven responses always contain regions the client should treat as opaque:
/// pagination cursors, tracking blobs, action payloads agreed between a widget and its
/// backend. `JSONValue` carries those regions through `Codable` without falling back to
/// `Any`, so the whole schema stays value typed, hashable and sendable.
public enum JSONValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Value is not a valid JSON fragment"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Convenience accessors

public extension JSONValue {
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var doubleValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var intValue: Int? {
        guard let double = doubleValue else { return nil }
        return Int(double)
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    /// Looks up a key when the value is an object, otherwise `nil`.
    subscript(key: String) -> JSONValue? {
        objectValue?[key]
    }

    /// Looks up an index when the value is an array, otherwise `nil`.
    subscript(index: Int) -> JSONValue? {
        guard let array = arrayValue, array.indices.contains(index) else { return nil }
        return array[index]
    }

    /// Re-decodes this fragment into a concrete `Decodable` type.
    ///
    /// This is the bridge that lets opaque payloads become typed models at the edge
    /// that understands them, for example an action handler decoding its own payload.
    func decoded<T: Decodable>(as type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        let data = try JSONEncoder().encode(self)
        return try decoder.decode(type, from: data)
    }
}
