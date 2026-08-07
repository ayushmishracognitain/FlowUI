# Adding a Widget

Three steps, all in your app. The framework never changes.

## 1. Model the payload

Agree a `type` string and a `data` shape with your backend team, then write a
plain `Decodable` struct for it. Reuse the FlowCore atoms (`TextData`,
`ImageData`, `TagData`, `ColorData`, ...) wherever they fit; they buy you fonts,
colors, dark mode and theming for free.

```swift
import FlowCore

struct OrderCardContent: WidgetContent, Hashable {
    static let widgetType = "order_card"    // the string your backend sends

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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orderNumber = try container.decode(TextData.self, forKey: .orderNumber)
        status = try container.decodeIfPresent(TagData.self, forKey: .status)
        // LossyArray, not [TextData]: a synthesized array is all or nothing, so one
        // bad element would take the whole widget with it.
        items = try container.decodeIfPresent(LossyArray<TextData>.self, forKey: .items)?.elements ?? []
        total = try container.decodeIfPresent(TextData.self, forKey: .total)
    }
}
```

Write the initializer by hand and use `decodeIfPresent` with a default for every
optional field. Required fields stay required, which is what lets a genuinely
unusable payload be contained as a malformed widget instead of rendering nonsense.
Arrays go through `LossyArray` so one bad element drops rather than emptying the
widget.

## 2. Write the view

A `WidgetView` is an ordinary SwiftUI view initialized with your typed content
and a context. Use the Flow atoms for rendering and `context` for interactions
and state.

`WidgetView` is `@MainActor` isolated, the same as `View` itself, so your
conformance needs nothing special. The package builds in the Swift 6 language
mode and your widget will too.

```swift
import SwiftUI
import FlowRender

struct OrderCardWidget: WidgetView {
    let content: OrderCardContent
    let context: WidgetContext

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                FlowText(content.orderNumber)
                if let status = content.status { FlowTag(status) }
            }
            ForEach(Array(content.items.enumerated()), id: \.offset) { _, item in
                FlowText(item)
            }
            if let total = content.total {
                Divider()
                FlowText(total)
            }
        }
    }
}
```

Do not apply margins, padding, backgrounds, corners or borders yourself; the
backend sends them in the widget's `layout` and the renderer applies them around
your view. Your view owns only what is inside.

## 3. Register it

```swift
registry.register(OrderCardWidget.self)
```

Done. The widget now works everywhere: vertical sections, carousels, grids,
page headers and footers, bottom sheets, and nested inside containers like the
accordion. Envelope level `tap` and `long_press` actions, layout chrome, the
debug console and diagnostics all apply automatically.

## Interactions

- **Envelope actions.** `actions.tap` and `actions.long_press` on the widget
  JSON are dispatched by the renderer; you write nothing.
- **Actions inside your payload.** For buttons and other controls that carry
  their own `ActionData`, dispatch explicitly:

  ```swift
  FlowButton(content.cta) { context.dispatch(content.cta.action) }
  ```

- **Named events.** `context.dispatch(event: "change")` fires whatever action
  the backend declared under that event name.

## Ephemeral state

State the server does not own (counts, expansion, drafts) goes in the page's
state store so it survives lazy container recycling:

```swift
private var count: Binding<Int> {
    context.state.binding(widgetID: context.widgetID, key: "count", default: 0)
}
```

Refreshing a page clears the store; pagination appends keep it.

The store is keyed by widget id, so **send a stable `id` for any widget that holds
state or is a mutation target**. Widgets with no `id` are given one derived from
their position in the response, which is stable across refreshes but moves if the
backend reorders the page.

## Accessibility

The renderer handles the envelope for you: a widget carrying `actions.tap` is
exposed as a button with a matching accessibility action, and its subviews are
combined into one element. Inside your view, two things are yours:

- Give meaningful images an `alt` in the JSON. Images without one are treated as
  decorative and hidden from VoiceOver.
- Label any control you build yourself, the way `StepperRowWidget` labels its
  plus and minus buttons.

Backend supplied font sizes scale with Dynamic Type by default. If a widget must
be pinned, set `scalesFontsWithDynamicType: false` on your theme's `ThemeDefaults`.

## Impressions

Widgets can carry an opaque `tracking` object. Implement `FlowTrackingSink` and
install it once to receive it:

```swift
struct MyAnalytics: FlowTrackingSink {
    func widgetDidAppear(_ impression: FlowImpression) {
        Analytics.log("impression", properties: impression.tracking)
    }
}

FlowPageView(store: store)
    .flowTrackingSink(MyAnalytics())
```

An impression fires once the widget has held the screen for a dwell threshold
(250ms by default, `.flowImpressionThreshold(_:)` to change it), so a fast scroll
does not report every row it passes.

## Custom actions

Backend wants `{ "type": "deeplink", "url": "app://orders/42" }`? Register a
handler; the newest registration wins, so you can also override built ins.

```swift
struct DeeplinkHandler: ActionHandler {
    struct Payload: Decodable { let url: String }

    func handle(_ action: ActionData, context: ActionContext) async -> Bool {
        guard action.type == "deeplink",
              let payload = try? action.payload(Payload.self) else { return false }
        await router.open(payload.url)
        return true
    }
}

let dispatcher = ActionDispatcher()
dispatcher.register(DeeplinkHandler())
FlowPageView(store: store, dispatcher: dispatcher)
```

## Skeletons (optional)

Conform to `WidgetSkeletonProviding` and loading states mirror your widget's
real shape instead of a generic block:

```swift
extension OrderCardWidget: WidgetSkeletonProviding {
    static func skeleton() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(.gray.opacity(0.3)).frame(width: 120, height: 14)
                RoundedRectangle(cornerRadius: 4).fill(.gray.opacity(0.2)).frame(height: 12)
            }
            .flowShimmer()
        )
    }
}
```

## Theming

If your app has a design system, implement `ThemeProvider` once and install it
with `.flowTheme(MyTheme())`. Backend `token` strings then resolve through your
palette and typography, with hex values as the fallback.

## Try it live

Run the demo app (`Examples/FlowDemo`), open the Playground, and paste your
widget's JSON. The demo's `order_card` is this exact recipe in working form:
`Examples/FlowDemo/FlowDemo/OrderCardWidget.swift`.
