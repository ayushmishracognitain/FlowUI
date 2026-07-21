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
///       { "title": "Accept", "bg_color": "#267E3E", "full_width": true,
///         "action": { "type": "api", "endpoint": "accept" } },
///       { "title": "Reject", "style": "outline", "action": { "type": "toast", "message": "Rejected" } }
///     ]
///   }
/// }
/// ```
public struct ButtonRowContent: WidgetContent, Hashable {
    public static let widgetType = "button_row"
    public let buttons: [ButtonData]

    public init(buttons: [ButtonData]) {
        self.buttons = buttons
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
                backgroundColor: ColorData(hex: "#267E3E"),
                isFullWidth: true
            ),
            ButtonData(title: TextData(text: "Reject"), style: "outline")
        ]),
        context: .inert()
    )
    .padding()
}
