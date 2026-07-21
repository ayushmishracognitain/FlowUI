import SwiftUI
import FlowCore

private struct FlowThemeKey: EnvironmentKey {
    static let defaultValue: any ThemeProvider = DefaultTheme()
}

private struct FlowImageLoaderKey: EnvironmentKey {
    static let defaultValue: any FlowImageLoader = DefaultImageLoader()
}

public extension EnvironmentValues {
    /// The active theme. Install a custom one with `.flowTheme(_:)` at the root.
    var flowTheme: any ThemeProvider {
        get { self[FlowThemeKey.self] }
        set { self[FlowThemeKey.self] = newValue }
    }

    /// The active image loader. Install a custom one with `.flowImageLoader(_:)`.
    var flowImageLoader: any FlowImageLoader {
        get { self[FlowImageLoaderKey.self] }
        set { self[FlowImageLoaderKey.self] = newValue }
    }
}

public extension View {
    /// Installs a theme for every FlowUI view below this point.
    func flowTheme(_ theme: any ThemeProvider) -> some View {
        environment(\.flowTheme, theme)
    }

    /// Installs an image loader for every FlowUI view below this point.
    func flowImageLoader(_ loader: any FlowImageLoader) -> some View {
        environment(\.flowImageLoader, loader)
    }
}
