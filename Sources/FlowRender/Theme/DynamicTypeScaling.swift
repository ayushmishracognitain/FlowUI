import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Scales a backend supplied point size to the user's text size setting.
///
/// Every font in the framework used to be `.system(size:)`, which is a pinned
/// point size: a page built with Flow-UI ignored Dynamic Type entirely, so a user
/// who had raised their text size saw no change anywhere. Sizes now go through the
/// metrics of whichever built in text style sits closest, which is what gives them
/// the scaling curve the platform uses for text of that size.
///
/// Views that render scaled text declare `@Environment(\.dynamicTypeSize)` so
/// SwiftUI re-evaluates their body when the setting changes. Reading the value is
/// the whole point of that property; without it the scaling would be computed once
/// and then go stale for the life of the view.
enum FlowFontScaling {
    static func scaled(_ size: Double) -> Double {
        #if canImport(UIKit)
        return UIFontMetrics(forTextStyle: uiTextStyle(closestTo: size)).scaledValue(for: size)
        #else
        // AppKit has no metrics equivalent, so sizes stay as sent on macOS.
        return size
        #endif
    }

    #if canImport(UIKit)
    private static func uiTextStyle(closestTo size: Double) -> UIFont.TextStyle {
        switch size {
        case ..<12: .caption2
        case ..<13: .caption1
        case ..<15: .footnote
        case ..<16: .subheadline
        case ..<17: .callout
        case ..<20: .body
        case ..<22: .title3
        case ..<28: .title2
        case ..<34: .title1
        default: .largeTitle
        }
    }
    #endif
}

/// Scales an icon's point size the same way, so glyphs keep pace with the text
/// they sit beside instead of staying stubbornly small.
extension FlowFontScaling {
    static func scaledIcon(_ size: Double) -> Double {
        scaled(size)
    }
}
