import SwiftUI
import FlowCore
import FlowRender

/// `button_row`: one or more buttons side by side, each carrying its own action.
///
/// ```jsonc
/// {
///   "type": "button_row",
///   "data": {
///     "buttons": [
///       { "title": "Accept", "bg_color": "#15803D", "full_width": true,
///         "action": { "type": "api", "endpoint": "accept" } },
///       { "title": "Reject", "style": "outline", "action": { "type": "toast", "message": "Rejected" } }
///     ]
///   }
/// }
/// ```
public struct ButtonRowContent: WidgetContent, Hashable {
    public static let widgetType = "button_row"
    public let buttons: [ButtonData]

    private enum CodingKeys: String, CodingKey {
        case buttons
    }

    public init(buttons: [ButtonData]) {
        self.buttons = buttons
    }

    /// Hand written so one malformed button drops instead of taking the whole row
    /// with it. Synthesized decoding of `[ButtonData]` is all or nothing, which
    /// contradicts the promise that a bad element never blanks the page.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(buttons: try container.decodeIfPresent(LossyArray<ButtonData>.self, forKey: .buttons)?.elements ?? [])
    }
}

public struct ButtonRowWidget: WidgetView {
    private let content: ButtonRowContent
    private let context: WidgetContext

    public init(content: ButtonRowContent, context: WidgetContext) {
        self.content = content
        self.context = context
    }

    public var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(content.buttons.enumerated()), id: \.offset) { _, button in
                FlowButton(button) {
                    context.dispatch(button.action)
                }
            }
        }
    }
}

#Preview("button_row", traits: .sizeThatFitsLayout) {
    ButtonRowWidget(
        content: ButtonRowContent(buttons: [
            ButtonData(
                title: TextData(text: "Accept", color: ColorData(hex: "#FFFFFF")),
                backgroundColor: ColorData(hex: "#15803D"),
                isFullWidth: true
            ),
            ButtonData(title: TextData(text: "Reject"), style: "outline")
        ]),
        context: .inert()
    )
    .padding()
}
