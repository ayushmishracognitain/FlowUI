import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Semantic system colors expressed once for both UIKit and AppKit platforms.
public enum FlowPlatformColor {
    public static var surface: Color {
        #if canImport(UIKit)
        Color(uiColor: .secondarySystemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    public static var pageBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemBackground)
        #else
        Color(nsColor: .textBackgroundColor)
        #endif
    }

    public static var separator: Color {
        #if canImport(UIKit)
        Color(uiColor: .separator)
        #else
        Color(nsColor: .separatorColor)
        #endif
    }
}

public extension Color {
    /// Builds a color from `#RRGGBB` or `#AARRGGBB` hex notation. The leading `#`
    /// is optional. Returns `nil` for anything unparseable.
    init?(flowHex: String) {
        var cleaned = flowHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6 || cleaned.count == 8, let value = UInt64(cleaned, radix: 16) else {
            return nil
        }
        let hasAlpha = cleaned.count == 8
        let alpha = hasAlpha ? Double((value >> 24) & 0xFF) / 255 : 1
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Builds a color that adapts to light and dark appearance from a hex pair.
    /// Falls back to the light value when no dark variant is provided.
    static func flowDynamic(hex: String?, darkHex: String?) -> Color? {
        guard let hex, let light = Color(flowHex: hex) else {
            // A dark-only color is unusual but valid.
            if let darkHex { return Color(flowHex: darkHex) }
            return nil
        }
        guard let darkHex, let dark = Color(flowHex: darkHex) else {
            return light
        }
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        return Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
        #else
        return light
        #endif
    }
}

public extension Font.Weight {
    /// Maps the backend weight vocabulary to a concrete weight, defaulting to regular.
    init(flowName: String) {
        switch flowName {
        case "medium": self = .medium
        case "semibold": self = .semibold
        case "bold": self = .bold
        case "heavy": self = .heavy
        case "light": self = .light
        default: self = .regular
        }
    }
}
