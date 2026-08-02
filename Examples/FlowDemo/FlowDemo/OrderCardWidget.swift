import SwiftUI
import FlowCore
import FlowRender

/// The demo's host defined widget, written exactly as a consumer app would:
/// a payload model, a view, one registration call in `Demo.makeRegistry()`.
/// The framework treats it identically to its own widgets.
struct OrderCardContent: WidgetContent, Hashable {
    static let widgetType = "order_card"
    let orderNumber: TextData
    let status: TagData?
    let items: [TextData]
    let total: TextData?

    private enum CodingKeys: String, CodingKey {
        case orderNumber = "order_number"
        case status
        case items
        case total
    }
}

struct OrderCardWidget: WidgetView {
    let content: OrderCardContent
    let context: WidgetContext

    init(content: OrderCardContent, context: WidgetContext) {
        self.content = content
        self.context = context
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                FlowText(content.orderNumber)
                if let status = content.status {
                    FlowTag(status)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(content.items.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.secondary)
                            .frame(width: 4, height: 4)
                        FlowText(item)
                    }
                }
            }
            if let total = content.total {
                Divider()
                FlowText(total)
            }
        }
    }
}

#Preview("order_card", traits: .sizeThatFitsLayout) {
    OrderCardWidget(
        content: OrderCardContent(
            orderNumber: TextData(text: "Order #1042", font: FontData(size: 16, weight: "semibold")),
            status: TagData(
                text: TextData(
                    text: "SHIPPED",
                    font: FontData(size: 10, weight: "bold"),
                    color: ColorData(hex: "#B7791F")
                ),
                backgroundColor: ColorData(hex: "#FEF3C7")
            ),
            items: [TextData(text: "2 x AirPods Pro 2"), TextData(text: "1 x USB C Cable")],
            total: TextData(text: "Total 1,258", font: FontData(size: 14, weight: "semibold"))
        ),
        context: .inert()
    )
    .padding()
}
