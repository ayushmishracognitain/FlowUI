# FlowUI

A server driven UI framework for SwiftUI. The backend describes screens as JSON
(pages, sections, widgets); FlowUI decodes, lays out and renders them, routes
every interaction, and stays open for any widget your app needs to add.

- **iOS 17+ / macOS 14+, pure SwiftUI, zero dependencies.** No networking stack,
  no image library, no design system baked in: those are seams your app plugs into.
- **Open widget registry.** One call registers a widget type: the backend `type`
  string, its payload model and its SwiftUI view. Adding a widget never touches
  framework code.
- **Backend controlled chrome.** Margins, padding, corner radii, backgrounds,
  gradients, borders and widths all come from the JSON and are applied by a single
  layout modifier.
- **Pages that refuse to die.** Unknown widget types and malformed payloads are
  skipped (or shown as labelled cards in debug builds) with every problem recorded
  in diagnostics. One bad widget never blanks a screen.
- **Actions as data.** Taps, long presses and change events carry declarative
  actions (`toast`, `dismiss`, `refresh_page`, `open_bottom_sheet`, `api`, or
  anything you define) routed through an extensible handler chain.
- **Loading aesthetics built in.** Shimmer, skeletons and gradients work out of
  the box, per widget and per page, backend toggleable.

## Quick start

```swift
import FlowUI

// 1. Register widgets once at startup.
let registry = WidgetRegistry()
FlowWidgets.register(on: registry)          // the starter library
registry.register(OrderCardWidget.self)     // your own widgets

// 2. Implement PageLoader with whatever networking you already have.
struct APILoader: PageLoader {
    func loadPage(_ request: PageRequest) async throws -> Data {
        try await myClient.fetch("/pages/\(request.pageID)")
    }
}

// 3. Render.
let store = PageStore(pageID: "home", loader: APILoader(), registry: registry)
FlowPageView(store: store)
```

UIKit hosts use `FlowHostingController(store:)` instead of `FlowPageView`.

## The JSON contract

A page is sections of widgets. Every widget carries a `type`, an optional `id`,
backend controlled `layout` chrome, its `data` payload, declarative `actions`
and opaque `tracking`. See [SCHEMA.md](SCHEMA.md) for the full contract with
copy ready examples, and [ADDING_A_WIDGET.md](ADDING_A_WIDGET.md) for the three
step recipe to add your own widget.

```jsonc
{
  "page": {
    "id": "home",
    "sections": [
      {
        "layout": { "arrangement": "vertical", "item_spacing": 8 },
        "widgets": [
          {
            "type": "image_text_card",
            "layout": { "margin": { "left": 16, "right": 16 }, "corner_radius": 12,
                        "background": { "hex": "#F8F8F8", "dark_hex": "#1C1C1E" } },
            "data": { "title": "AirPods Pro 2" },
            "actions": { "tap": { "type": "open_bottom_sheet", "sheet": { "...": "..." } } }
          }
        ]
      }
    ]
  }
}
```

## Modules

| Module | What it holds |
| --- | --- |
| `FlowCore` | The schema: atoms, envelopes, actions, forgiving decode pipeline. Foundation only. |
| `FlowRender` | SwiftUI: registry, page and sheet renderers, layout modifier, atoms, action dispatch, theming, debug console. |
| `FlowWidgets` | Eight starter widgets, each one a worked example. |

Import `FlowUI` for everything, or `FlowCore` alone for tooling and tests.

## The demo app

`Examples/FlowDemo` is the living catalog: fixture driven pages for every layout,
pagination, sheets and api mutations, a JSON playground that renders anything you
paste, remote mode for serving JSON from a local http server with no rebuild, and
network simulation for exercising shimmer, error and empty states. The floating
debug console shows decode diagnostics with exact key paths, the action log and a
layout inspector.

## Testing

```
swift test
```

`FlowCore` is UI free and fully covered by fixture based decode tests.
