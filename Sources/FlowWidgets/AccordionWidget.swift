import SwiftUI
import FlowCore
import FlowRender

/// `accordion`: a tappable header that expands to reveal nested widgets.
///
/// The children are complete widgets in their own right, decoded through the same
/// registry as everything else. That makes the accordion a composition proof: any
/// registered widget, including host defined ones, can live inside it with zero
/// extra work. The expanded flag lives in the page's `WidgetStateStore`.
///
/// ```jsonc
/// {
///   "type": "accordion",
///   "id": "faq_1",
///   "data": {
///     "header": { "text": "How do refunds work?", "font": { "size": 16, "weight": "semibold" } },
///     "initially_expanded": false,
///     "items": [
///       { "type": "image_text_card", "data": { "title": "Refunds land in 5 to 7 days" } },
///       { "type": "button_row", "data": { "buttons": [{ "title": "Contact support" }] } }
///     ]
///   }
/// }
/// ```
public struct AccordionContent: WidgetContent {
    public static let widgetType = "accordion"
    public let header: TextData
    public let initiallyExpanded: Bool?
    public let items: [AnyWidget]

    private enum CodingKeys: String, CodingKey {
        case header
        case initiallyExpanded = "initially_expanded"
        case items
    }

    public init(header: TextData, initiallyExpanded: Bool? = nil, items: [AnyWidget]) {
        self.header = header
        self.initiallyExpanded = initiallyExpanded
        self.items = items
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            header: try container.decode(TextData.self, forKey: .header),
            initiallyExpanded: try container.decodeIfPresent(Bool.self, forKey: .initiallyExpanded),
            items: try container.decodeIfPresent(LossyArray<AnyWidget>.self, forKey: .items)?.elements ?? []
        )
    }
}

public struct AccordionWidget: WidgetView {
    private let content: AccordionContent
    private let context: WidgetContext

    public init(content: AccordionContent, context: WidgetContext) {
        self.content = content
        self.context = context
    }

    private var expanded: Binding<Bool> {
        context.state.binding(
            widgetID: context.widgetID,
            key: "expanded",
            default: content.initiallyExpanded ?? false
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    expanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    FlowText(content.header)
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expanded.wrappedValue ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded.wrappedValue {
                VStack(spacing: 8) {
                    ForEach(content.items) { item in
                        WidgetRowView(item)
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview("accordion", traits: .sizeThatFitsLayout) {
    AccordionWidget(
        content: AccordionContent(
            header: TextData(text: "How do refunds work?", font: FontData(size: 16, weight: "semibold")),
            initiallyExpanded: true,
            items: [
                AnyWidget(
                    id: "a",
                    type: "image_text_card",
                    content: ImageTextCardContent(title: TextData(text: "Refunds land in 5 to 7 business days"))
                )
            ]
        ),
        context: .inert()
    )
    .padding()
    .environment(\.flowRegistry, {
        let registry = WidgetRegistry()
        registry.register(ImageTextCardWidget.self)
        return registry
    }())
}
