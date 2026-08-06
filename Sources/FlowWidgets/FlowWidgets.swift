import FlowRender

/// The starter widget library.
public enum FlowWidgets {
    /// Every widget type this module ships.
    ///
    /// Computed rather than stored: a stored array of existential metatypes is
    /// shared mutable global state under the Swift 6 language mode.
    public static var all: [any WidgetView.Type] {
        [
            TitleBlockWidget.self,
            ImageTextCardWidget.self,
            SeparatorWidget.self,
            ButtonRowWidget.self,
            TagRailWidget.self,
            BannerWidget.self,
            StepperRowWidget.self,
            AccordionWidget.self
        ]
    }

    /// Registers the whole library on a registry. Call once at startup, before
    /// or after registering your own widgets; last registration per type wins.
    public static func register(on registry: WidgetRegistry) {
        registry.register(all)
    }
}
