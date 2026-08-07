# Flow-UI JSON Contract

This is the reference for backend developers. Everything the client renders comes
from these shapes. All keys are snake_case. Every field not marked required is
optional; the client has sensible defaults.

## The envelope

A screen is a **page**. A page holds **sections**. A section holds **widgets**.

```jsonc
{
  "page": {
    "id": "home",                          // required, stable identifier
    "nav": { /* NavModel */ },
    "header": { "sticky": true, "widgets": [ /* widgets */ ] },
    "sections": [ /* sections */ ],
    "footer": { "sticky": true, "widgets": [ /* widgets */ ] },
    "pagination": { "has_more": true, "postback": { /* anything */ } },
    "refresh": { "pull_to_refresh": true }
  }
}
```

- `header` and `footer` are widget strips. `sticky: true` pins them outside the
  scroll area; `false` scrolls them with the content.
- `pagination.postback` is opaque: whatever you send comes back untouched on the
  next page request. Use any cursor shape you like.
- `nav`: `{ "title": TextData, "subtitle": TextData, "bg_color": ColorData,
  "left_button": ButtonData, "right_buttons": [ButtonData] }`.

## Sections

```jsonc
{
  "id": "sec_popular",                     // recommended for stable identity
  "layout": {
    "arrangement": "vertical",             // "vertical" | "carousel" | "grid"
    "columns": 2,                          // grid only
    "item_spacing": 8,                     // points between widgets
    "insets": { "top": 12, "left": 16, "right": 16, "bottom": 0 }
  },
  "header": { /* one widget, pins while the section scrolls under it */ },
  "widgets": [ /* widgets */ ]
}
```

Unknown `arrangement` strings fall back to `vertical`, so you can introduce new
arrangements without breaking old clients.

## Widgets

```jsonc
{
  "type": "image_text_card",               // required, selects the component
  "id": "product_1",                          // recommended, used for state and mutations
  "layout": { /* WidgetLayout, see below */ },
  "data": { /* payload owned by the widget type */ },
  "actions": { "tap": { /* ActionData */ }, "long_press": { }, "change": { } },
  "tracking": { /* opaque, forwarded to the host's analytics */ }
}
```

A widget whose `type` the client does not know is skipped (debug builds show a
labelled placeholder instead). A widget whose `data` fails to decode is likewise
contained. The page always renders.

### About `id`

`id` is optional but you should send one for anything interactive, stateful or
replaceable. When you omit it the client derives one from the widget's position in
the response. That is stable across refreshes of the same payload, which is what
keeps scroll position and in flight images alive, but it moves if you reorder the
page and it cannot be targeted by a mutation.

**Ids must be unique within a page.** A repeat is renamed (`cart_row`, then
`cart_row#2`) and reported as a `duplicateID` diagnostic, because duplicate ids
break list rendering and make `replace_widget` ambiguous.

### WidgetLayout, the backend controlled chrome

Applied inside out: padding, background and gradient, corner clipping, border, margin.

```jsonc
{
  "margin":  { "top": 0, "left": 16, "right": 16, "bottom": 12 },   // outside the background
  "padding": { "top": 12, "left": 12, "right": 12, "bottom": 12 },  // inside the background
  "corner_radius": 12,                     // or { "top_left": 12, "top_right": 12, ... }
  "background": { "hex": "#FFFFFF", "dark_hex": "#1C1C1E" },
  "gradient": { "colors": [ { "hex": "#FF512F" }, { "hex": "#DD2476" } ], "angle": 90 },
  "border": { "width": 1, "color": { "hex": "#EAEAEA" }, "dash_width": 5, "dash_gap": 3 },
  "width": "fill"                          // "fill" | "hug" | fraction such as 0.75
}
```

`width` applies in every arrangement. `fill` stretches to the available width,
`hug` takes only what the content needs, and a fraction takes that share of the
container. Fractions inside carousels are what produce peeking cards.

## Atoms

These small shapes appear inside widget payloads everywhere.

| Atom | Shape | Notes |
| --- | --- | --- |
| TextData | `"Hello"` or `{ "text": "Hello", "font": FontData, "color": ColorData, "alignment": "leading\|center\|trailing", "max_lines": 2, "is_markdown": true }` | Bare string shorthand accepted |
| ColorData | `"#4F46E5"` or `{ "hex": "#4F46E5", "dark_hex": "#FF6B6B", "token": "surface.primary", "alpha": 0.8 }` | `token` wins when the host has a design system; 8 digit hex is alpha first |
| FontData | `{ "size": 16, "weight": "semibold", "token": "title.large" }` | Weights: regular, medium, semibold, bold, heavy, light |
| ImageData | `"https://..."` or `{ "url": "https://...", "aspect_ratio": 2.2, "scale_mode": "fill\|fit", "corner_radius": 12, "placeholder_color": ColorData, "shimmer": true, "alt": "AirPods in a case" }` | `aspect_ratio` reserves the shape before loading. `alt` is read by VoiceOver; an image without one is treated as decorative and hidden |
| IconData | `"star.fill"` or `{ "symbol": "star.fill", "size": 14, "color": ColorData, "action": ActionData }` | SF Symbol names |
| ButtonData | `{ "title": TextData, "style": "solid\|outline\|plain", "bg_color": ColorData, "corner_radius": 12, "icon": IconData, "full_width": true, "disabled": false, "action": ActionData }` | |
| TagData | `{ "text": TextData, "bg_color": ColorData, "border_color": ColorData, "corner_radius": 6, "icon": IconData, "action": ActionData }` | |
| SeparatorData | `{ "style": "line\|dashed\|space", "color": ColorData, "thickness": 1, "insets": Insets }` | |
| Insets | `{ "top": 0, "left": 0, "right": 0, "bottom": 0 }` | Send only the sides you need |

## Actions

An action is `{ "type": "...", ...anything }`. The whole object reaches the
handler for that type, so each type defines its own extra keys.

Built in types:

```jsonc
{ "type": "toast", "message": "Saved", "duration": 2.5 }
{ "type": "dismiss" }
{ "type": "refresh_page" }
{ "type": "open_bottom_sheet", "sheet": { /* SheetModel, see below */ } }
{ "type": "api", /* any keys you need, echoed to your endpoint */ }
```

Anything else (`deeplink` included) is handled by the host app, which registers
its own handlers. Send whatever contract you agree on.

### The api action and mutations

An `api` action sends its full object to the backend, which answers with page
mutations. This is how a tap updates one widget in place with no reload:

```jsonc
// response to an api action
{
  "mutations": [
    { "kind": "replace_widget", "id": "product_1", "widget": { /* full widget */ } },
    { "kind": "remove_widget", "id": "product_2" },
    { "kind": "append_sections", "sections": [ /* sections */ ] },
    { "kind": "prepend_sections", "sections": [ /* sections */ ] },
    { "kind": "replace_page", "page": { /* full page */ } }
  ],
  "toast": { "message": "Added to favourites" }
}
```

## Bottom sheets

Same widgets, different chrome. The header and footer stay fixed while sections scroll.

```jsonc
{
  "sheet": {
    "id": "confirm",
    "config": {
      "detents": ["medium", "large", 0.4],   // named detents or height fractions
      "grabber": true,
      "dismissible": true,
      "corner_radius": 24
    },
    "header": { "widgets": [ /* widgets */ ] },
    "sections": [ /* sections */ ],
    "footer": { "widgets": [ /* widgets */ ] }
  }
}
```

Inline sheets ride inside an `open_bottom_sheet` action under the `sheet` key.

## Starter widget payloads

The `data` object for each widget in the FlowWidgets library:

```jsonc
// title_block
{ "title": TextData, "subtitle": TextData }

// image_text_card
{ "image": ImageData, "title": TextData, "subtitle": TextData,
  "tags": [TagData], "trailing_icon": IconData }

// separator: the data object IS a SeparatorData
{ "style": "dashed", "insets": { "left": 16, "right": 16 } }

// button_row
{ "buttons": [ButtonData] }

// tag_rail
{ "tags": [TagData] }

// banner
{ "image": ImageData, "title": TextData, "subtitle": TextData }

// stepper_row (count changes fire the widget's "change" action)
{ "title": TextData, "subtitle": TextData, "min": 0, "max": 10, "initial": 1 }

// accordion (items are full widgets, any registered type nests)
{ "header": TextData, "initially_expanded": false, "items": [ /* widgets */ ] }
```

## Tracking

Every widget can carry an opaque `tracking` object. The client never reads it. It
is handed to the host's `FlowTrackingSink` once the widget has held the screen long
enough to count as seen, so your event schema stays yours:

```jsonc
{
  "type": "image_text_card",
  "id": "product_1",
  "tracking": { "impression_id": "imp_1", "surface": "home_feed", "slot": 3 },
  "data": { "title": "AirPods Pro 2" }
}
```

Hosts that install no sink discard impressions.

## Accessibility

Two things the backend controls:

- **`alt` on images.** Anything carrying meaning needs one. Images without `alt`
  are hidden from VoiceOver as decorative, which is right for backdrops and wrong
  for product photos.
- **`actions.tap`.** A widget with a tap action is automatically announced as a
  button with an activation action. You get this for free by declaring the action
  rather than by any extra field.

Backend `font.size` values scale with the user's text size setting.

## Compatibility rules

1. New widget types can ship any time; old clients skip them cleanly.
2. New optional fields on existing payloads are always safe.
3. Never repurpose an existing key's meaning; add a new key instead.
4. Keep `id` stable across responses for widgets that mutate or hold state, and
   unique within a page.
5. A malformed element inside a payload array is dropped, not fatal. One bad
   button does not empty a `button_row`.
