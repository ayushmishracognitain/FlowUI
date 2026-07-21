import Foundation

/// An array that survives bad elements.
///
/// Standard `Decodable` arrays are all or nothing: one malformed element fails the
/// whole response. `LossyArray` decodes what it can, drops what it cannot, and
/// reports every drop to the `DecodeDiagnostics` collector when one is attached.
public struct LossyArray<Element: Decodable>: Decodable {
    public var elements: [Element]

    public init(_ elements: [Element] = []) {
        self.elements = elements
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Element] = []
        let diagnostics = decoder.userInfo[.flowDiagnostics] as? DecodeDiagnostics

        while !container.isAtEnd {
            do {
                result.append(try container.decode(Element.self))
            } catch {
                diagnostics?.record(
                    .droppedElement,
                    widgetType: nil,
                    codingPath: container.codingPath,
                    message: describeDecodingError(error)
                )
                // Consume the failed element so the container advances. JSONValue
                // accepts any fragment; if even that fails, stop to avoid spinning.
                if (try? container.decode(JSONValue.self)) == nil {
                    break
                }
            }
        }
        elements = result
    }
}

extension LossyArray: Sendable where Element: Sendable {}
