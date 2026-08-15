# Changelog

Flow-UI follows [semantic versioning](https://semver.org). The JSON contract is part
of the public API: additive schema changes ship in minor versions, and anything that
would break an existing payload waits for a major.

## 1.0.0 - 2026-08-16

The first Flow-UI release. The complete schema layer with lossy
decoding and diagnostics, the SwiftUI renderer with pages, carousels, grids, sticky bars,
bottom sheets, shimmer and skeletons, the open widget registry, the action dispatcher with
api mutations, the theming protocol, the widget state store, and eight starter widgets.
Ships with a fixture driven demo app, a JSON playground and a debug console.

### Added

- `FlowTrackingSink`, the seam that delivers a widget's opaque `tracking` object to the
  host once the widget has held the screen past a dwell threshold. Install with
  `.flowTrackingSink(_:)`, tune with `.flowImpressionThreshold(_:)`.
- `alt` on `ImageData`, read by VoiceOver. An image without one is treated as
  decorative and hidden from assistive technology.
- Dynamic Type. Backend `font.size` values scale through `UIFontMetrics`. Opt out per
  theme with `ThemeDefaults.scalesFontsWithDynamicType`.
- Accessibility on the widget envelope: a widget carrying `actions.tap` is exposed as a
  button with a matching accessibility action, and its subviews combine into one element.
- `DecodeDiagnostics.Kind.duplicateID`, reported when two widgets in one page claim the
  same `id`.
- A `FlowWidgets` test target covering the starter payloads.

### Changed

- **The package now builds in the Swift 6 language mode.** `swift-tools-version` is 6.0
  and every target sets `.swiftLanguageMode(.v6)`, so Xcode 16 or newer is required.
- **`WidgetView` is `@MainActor` isolated**, matching `View`. This is the one signature
  a host feels. Existing conformances compile unchanged.
- **Widget, section and page ids no longer fall back to a random UUID.** The fallback is
  derived from the element's coding path, so the same bytes decode to the same ids and a
  refresh diffs the page instead of rebuilding it. Duplicates are renamed and reported.
- `replace_widget` and `remove_widget` now reach a widget in the page header, a section
  header, a section body or the page footer. Previously `replace_widget` only searched
  section bodies.
- `PageStore` cancels superseded fetches and re-reads its state after an await, so a
  mutation applied during a pagination fetch is no longer discarded.
- `WidgetStateStore` is `@MainActor` isolated, which makes it `Sendable`.
- `width` is honoured in every arrangement. `hug` and fractional widths previously worked
  only inside carousels.
- Widget payload arrays decode losslessly. One malformed button no longer empties a
  `button_row`.
- Images decode off the main actor and go through an in memory decoded-image cache.
- A widget is only clipped when it actually declares a `corner_radius`.

### Fixed

- A retain cycle in `ActionDispatcher`, one per dispatched action.
- `FlowImage` showing the previous image when its URL changed while the view kept identity.
- `APIActionHandler` decoding on the main actor and reporting cancellation as failure.
- Shimmer rendering its content twice and animating offscreen rows forever.
- A dashed `FlowSeparator` being clipped to half its stroke.
- A nav bar button with no action dispatching a junk `none` action.
- A malformed `toast` payload falling through the whole handler chain unreported.
