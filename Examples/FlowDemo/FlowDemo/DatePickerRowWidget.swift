import SwiftUI
import FlowCore
import FlowRender

/// A second host defined widget: a date picker driven by the backend.
///
/// `style` chooses between an inline calendar and a compact field. The picked
/// date lives in the page's `WidgetStateStore` (so it survives scrolling) and
/// every change fires the widget's `change` action.
///
/// ```jsonc
/// {
///   "type": "date_picker_row",
///   "id": "delivery_date",
///   "data": { "title": "Delivery date", "style": "calendar" },
///   "actions": { "change": { "type": "toast", "message": "Date updated" } }
/// }
/// ```
struct DatePickerRowContent: WidgetContent, Hashable {
    static let widgetType = "date_picker_row"
    let title: TextData
    /// `calendar` for the inline graphical picker, anything else for compact.
    let style: String?
}

struct DatePickerRowWidget: WidgetView {
    let content: DatePickerRowContent
    let context: WidgetContext

    init(content: DatePickerRowContent, context: WidgetContext) {
        self.content = content
        self.context = context
    }

    private var date: Binding<Date> {
        context.state.binding(widgetID: context.widgetID, key: "date", default: Date())
    }

    var body: some View {
        Group {
            if content.style == "calendar" {
                VStack(alignment: .leading, spacing: 0) {
                    FlowText(content.title)
                    DatePicker("", selection: changeReporting, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                }
            } else {
                HStack {
                    FlowText(content.title)
                    Spacer()
                    DatePicker("", selection: changeReporting, in: Date()..., displayedComponents: .date)
                        .labelsHidden()
                }
            }
        }
    }

    /// Wraps the stored binding so every user change also fires the action.
    private var changeReporting: Binding<Date> {
        Binding(
            get: { date.wrappedValue },
            set: { newValue in
                date.wrappedValue = newValue
                context.dispatch(event: "change")
            }
        )
    }
}

#Preview("date_picker_row", traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        DatePickerRowWidget(
            content: DatePickerRowContent(
                title: TextData(text: "Delivery date", font: FontData(size: 16, weight: "semibold")),
                style: "calendar"
            ),
            context: .inert()
        )
        DatePickerRowWidget(
            content: DatePickerRowContent(title: TextData(text: "Compact style"), style: nil),
            context: .inert()
        )
    }
    .padding()
}
