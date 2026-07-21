import SwiftUI
import FlowCore

/// Fallback styling used when the backend leaves something unspecified.
public struct ThemeDefaults: Sendable {
    public var textColor: Color
    public var secondaryTextColor: Color
    public var accentColor: Color
    public var surfaceColor: Color
    public var pageBackground: Color
    public var separatorColor: Color
    public var cornerRadius: Double
    public var spacing: Double
    public var bodyFont: Font

    public init(
        textColor: Color = .primary,
        secondaryTextColor: Color = .secondary,
        accentColor: Color = .accentColor,
        surfaceColor: Color = FlowPlatformColor.surface,
        pageBackground: Color = FlowPlatformColor.pageBackground,
        separatorColor: Color = FlowPlatformColor.separator,
        cornerRadius: Double = 12,
        spacing: Double = 8,
        bodyFont: Font = .body
    ) {
        self.textColor = textColor
        self.secondaryTextColor = secondaryTextColor
        self.accentColor = accentColor
        self.surfaceColor = surfaceColor
        self.pageBackground = pageBackground
        self.separatorColor = separatorColor
        self.cornerRadius = cornerRadius
        self.spacing = spacing
        self.bodyFont = bodyFont
    }
}

/// Resolves backend color and font descriptions into concrete SwiftUI values.
///
/// The default implementation understands hex values and system fonts. Hosts with
/// a design system implement this protocol once, map `token` strings to their own
/// palette and typography, and every widget in the app picks it up through the
/// environment.
public protocol ThemeProvider: Sendable {
    /// Resolution order by convention: `token` first, then `hex` and `dark_hex`, then `nil`.
    func color(_ data: ColorData?) -> Color?
    func font(_ data: FontData?) -> Font?
    var defaults: ThemeDefaults { get }
}

public extension ThemeProvider {
    /// Convenience that falls back to a default when resolution fails.
    func color(_ data: ColorData?, fallback: Color) -> Color {
        color(data) ?? fallback
    }

    func font(_ data: FontData?, fallback: Font) -> Font {
        font(data) ?? fallback
    }
}

/// The theme used when the host installs nothing: hex colors, system fonts,
/// no token knowledge.
public struct DefaultTheme: ThemeProvider {
    public var defaults: ThemeDefaults

    public init(defaults: ThemeDefaults = ThemeDefaults()) {
        self.defaults = defaults
    }

    public func color(_ data: ColorData?) -> Color? {
        guard let data else { return nil }
        // This theme has no token table, so hex is the only source.
        guard let resolved = Color.flowDynamic(hex: data.hex, darkHex: data.darkHex) else { return nil }
        if let alpha = data.alpha {
            return resolved.opacity(alpha)
        }
        return resolved
    }

    public func font(_ data: FontData?) -> Font? {
        guard let data else { return nil }
        guard let size = data.size else {
            return data.weight.map { Font.body.weight(Font.Weight(flowName: $0)) }
        }
        let weight = Font.Weight(flowName: data.weight ?? "regular")
        return .system(size: size, weight: weight)
    }
}
