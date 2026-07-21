import Foundation

/// Collects everything that went wrong, or was skipped, while decoding a response.
///
/// A malformed widget never fails a page. Instead the problem is recorded here with
/// enough detail to fix the JSON: the widget type, the coding path and the error text.
/// The debug overlay in FlowRender surfaces these entries at runtime.
public final class DecodeDiagnostics: @unchecked Sendable {
    public enum Kind: String, Sendable {
        /// The widget `type` string has no registered content model.
        case unknownType
        /// The type is registered but its payload failed to decode.
        case malformedPayload
        /// An array element could not be decoded at all and was dropped.
        case droppedElement
    }

    public struct Entry: Identifiable, Sendable {
        public let id = UUID()
        public let kind: Kind
        public let widgetType: String?
        public let codingPath: String
        public let message: String
    }

    private let lock = NSLock()
    private var storage: [Entry] = []

    public init() {}

    public var entries: [Entry] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage.isEmpty
    }

    public func record(_ kind: Kind, widgetType: String?, codingPath: [CodingKey], message: String) {
        let entry = Entry(
            kind: kind,
            widgetType: widgetType,
            codingPath: codingPath.map(\.stringValue).joined(separator: "."),
            message: message
        )
        lock.lock()
        storage.append(entry)
        lock.unlock()
    }

    public func reset() {
        lock.lock()
        storage.removeAll()
        lock.unlock()
    }
}

/// Produces a readable one line description of a decoding error, including the key path.
public func describeDecodingError(_ error: Error) -> String {
    guard let decodingError = error as? DecodingError else {
        return String(describing: error)
    }
    func path(_ context: DecodingError.Context) -> String {
        let joined = context.codingPath.map(\.stringValue).joined(separator: ".")
        return joined.isEmpty ? "(root)" : joined
    }
    switch decodingError {
    case .keyNotFound(let key, let context):
        return "Missing key '\(key.stringValue)' at \(path(context))"
    case .typeMismatch(let type, let context):
        return "Expected \(type) at \(path(context)): \(context.debugDescription)"
    case .valueNotFound(let type, let context):
        return "Null value, expected \(type) at \(path(context))"
    case .dataCorrupted(let context):
        return "Corrupted data at \(path(context)): \(context.debugDescription)"
    @unknown default:
        return String(describing: decodingError)
    }
}
