#if canImport(UIKit)
import SwiftUI
import UIKit
import FlowCore

/// One line embedding for UIKit hosts.
///
/// ```swift
/// let controller = FlowHostingController(store: store, dispatcher: dispatcher)
/// navigationController?.pushViewController(controller, animated: true)
/// ```
///
/// Pure SwiftUI apps never need this type.
public final class FlowHostingController: UIHostingController<AnyView> {
    public init(
        store: PageStore,
        dispatcher: ActionDispatcher? = nil,
        theme: (any ThemeProvider)? = nil
    ) {
        var root = AnyView(FlowPageView(store: store, dispatcher: dispatcher))
        if let theme {
            root = AnyView(root.flowTheme(theme))
        }
        super.init(rootView: root)
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
#endif
