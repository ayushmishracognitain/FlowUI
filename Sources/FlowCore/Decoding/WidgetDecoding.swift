import Foundation

/// The payload model behind a widget type.
///
/// Conforming types are plain `Decodable` structs describing the `data` object the
/// backend sends for one widget type. The static `widgetType` string is the contract
/// key agreed with the backend, for example `"image_text_card"`.
public protocol WidgetContent: Decodable, Sendable {
    static var widgetType: String { get }
}

/// The JSON keys of a widget envelope. Public so registries can decode payloads
/// out of the same container the envelope was read from.
public enum WidgetCodingKeys: String, CodingKey {
    case type
    case id
    case layout
    case data
    case actions
    case tracking
}

/// Resolves a widget `type` string to a decoded payload.
///
/// FlowRender's `WidgetRegistry` is the standard implementation. The protocol lives
/// here so FlowCore can decode complete pages without importing SwiftUI, which keeps
/// the schema testable from the command line.
public protocol WidgetDecoding {
    /// Returns the decoded payload for `type`, or `nil` when the type is not registered.
    /// Throws when the type is known but its payload fails to decode.
    func decodeContent(type: String, from container: KeyedDecodingContainer<WidgetCodingKeys>) throws -> (any WidgetContent)?
}

public extension CodingUserInfoKey {
    /// Carries the `WidgetDecoding` implementation into `Decodable` initializers.
    static let flowWidgetDecoding = CodingUserInfoKey(rawValue: "flow.widgetDecoding")!
    /// Carries an optional `DecodeDiagnostics` collector into `Decodable` initializers.
    static let flowDiagnostics = CodingUserInfoKey(rawValue: "flow.diagnostics")!
}

/// Builds a `JSONDecoder` wired for FlowUI decoding.
public enum FlowDecoder {
    public static func make(
        widgetDecoding: WidgetDecoding? = nil,
        diagnostics: DecodeDiagnostics? = nil
    ) -> JSONDecoder {
        let decoder = JSONDecoder()
        if let widgetDecoding {
            decoder.userInfo[.flowWidgetDecoding] = widgetDecoding
        }
        if let diagnostics {
            decoder.userInfo[.flowDiagnostics] = diagnostics
        }
        return decoder
    }
}
