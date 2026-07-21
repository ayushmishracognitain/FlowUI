import Foundation

/// One decoded widget: envelope plus typed payload.
///
/// The envelope fields (`type`, `id`, `layout`, `actions`, `tracking`) are uniform
/// across every widget. The payload under `data` is decoded through the
/// `WidgetDecoding` implementation found in `decoder.userInfo`, which is how the
/// open registry participates in plain `Codable` decoding.
///
/// Decoding never throws for content problems. An unregistered type produces
/// `UnknownWidgetContent` and a registered type with a bad payload produces
/// `MalformedWidgetContent`, so a single bad widget cannot take down a page.
public struct AnyWidget: Identifiable, Decodable, Sendable {
    public let id: String
    public let type: String
    public let layout: WidgetLayout
    public let actions: WidgetActions
    public let tracking: JSONValue?
    public let content: any WidgetContent

    public init(
        id: String,
        type: String,
        layout: WidgetLayout = WidgetLayout(),
        actions: WidgetActions = .none,
        tracking: JSONValue? = nil,
        content: any WidgetContent
    ) {
        self.id = id
        self.type = type
        self.layout = layout
        self.actions = actions
        self.tracking = tracking
        self.content = content
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: WidgetCodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        self.type = type
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? "\(type).\(UUID().uuidString.prefix(8))"
        layout = try container.decodeIfPresent(WidgetLayout.self, forKey: .layout) ?? WidgetLayout()
        actions = try container.decodeIfPresent(WidgetActions.self, forKey: .actions) ?? .none
        tracking = try container.decodeIfPresent(JSONValue.self, forKey: .tracking)

        let diagnostics = decoder.userInfo[.flowDiagnostics] as? DecodeDiagnostics
        guard let decoding = decoder.userInfo[.flowWidgetDecoding] as? WidgetDecoding else {
            content = UnknownWidgetContent(type: type, data: try? container.decodeIfPresent(JSONValue.self, forKey: .data))
            return
        }
        do {
            if let decoded = try decoding.decodeContent(type: type, from: container) {
                content = decoded
            } else {
                diagnostics?.record(
                    .unknownType,
                    widgetType: type,
                    codingPath: container.codingPath,
                    message: "No widget registered for type '\(type)'"
                )
                content = UnknownWidgetContent(type: type, data: try? container.decodeIfPresent(JSONValue.self, forKey: .data))
            }
        } catch {
            let message = describeDecodingError(error)
            diagnostics?.record(
                .malformedPayload,
                widgetType: type,
                codingPath: container.codingPath,
                message: message
            )
            content = MalformedWidgetContent(type: type, message: message)
        }
    }
}

/// Placeholder content for a widget type nothing has registered.
///
/// The raw `data` fragment is preserved so tooling can still inspect it.
public struct UnknownWidgetContent: WidgetContent, Hashable {
    public static let widgetType = "_flow.unknown"
    public let type: String
    public let data: JSONValue?

    public init(type: String, data: JSONValue? = nil) {
        self.type = type
        self.data = data
    }
}

/// Placeholder content for a registered widget whose payload failed to decode.
public struct MalformedWidgetContent: WidgetContent, Hashable {
    public static let widgetType = "_flow.malformed"
    public let type: String
    public let message: String

    public init(type: String, message: String) {
        self.type = type
        self.message = message
    }
}
