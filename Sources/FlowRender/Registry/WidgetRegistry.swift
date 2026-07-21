import SwiftUI
import FlowCore

/// What to render for a widget type nothing has registered.
public enum UnknownWidgetPolicy: Sendable {
    /// Render nothing, the page flows on as if the widget was not there.
    case skip
    /// Render a labelled placeholder card. The default in debug builds.
    case placeholder
}

/// The open registration table at the heart of FlowUI.
///
/// One call per widget type connects three things: the `type` string from the
/// backend, the `WidgetContent` payload model, and the `WidgetView` that renders
/// it. Decoding and view creation both flow through here, so adding a widget
/// never touches framework code.
///
/// This is also the single place type erasure happens. `register` is generic and
/// fully type checked; the stored closures pair a decode and a view builder created
/// in the same generic scope, so the internal cast cannot fail.
public final class WidgetRegistry: @unchecked Sendable, WidgetDecoding {
    private struct Entry {
        let decode: (KeyedDecodingContainer<WidgetCodingKeys>) throws -> any WidgetContent
        let makeView: @MainActor (any WidgetContent, WidgetContext) -> AnyView
        let makeSkeleton: (@MainActor () -> AnyView)?
    }

    private let lock = NSLock()
    private var entries: [String: Entry] = [:]

    public var unknownPolicy: UnknownWidgetPolicy

    public init(unknownPolicy: UnknownWidgetPolicy? = nil) {
        #if DEBUG
        self.unknownPolicy = unknownPolicy ?? .placeholder
        #else
        self.unknownPolicy = unknownPolicy ?? .skip
        #endif
    }

    /// Registers a widget view for its content's `widgetType`.
    public func register<V: WidgetView>(_ viewType: V.Type) {
        let skeleton: (@MainActor () -> AnyView)? = (viewType as? any WidgetSkeletonProviding.Type)
            .map { provider in { @MainActor in provider.skeleton() } }
        let entry = Entry(
            decode: { container in
                try container.decode(V.Content.self, forKey: .data)
            },
            makeView: { content, context in
                guard let typed = content as? V.Content else { return AnyView(EmptyView()) }
                return AnyView(V(content: typed, context: context))
            },
            makeSkeleton: skeleton
        )
        lock.lock()
        entries[V.Content.widgetType] = entry
        lock.unlock()
    }

    /// Registers several widget views at once.
    public func register(_ viewTypes: [any WidgetView.Type]) {
        for viewType in viewTypes {
            registerErased(viewType)
        }
    }

    private func registerErased(_ viewType: any WidgetView.Type) {
        func open<V: WidgetView>(_ type: V.Type) {
            register(type)
        }
        open(viewType)
    }

    public var registeredTypes: [String] {
        lock.lock()
        defer { lock.unlock() }
        return entries.keys.sorted()
    }

    private func entry(for type: String) -> Entry? {
        lock.lock()
        defer { lock.unlock() }
        return entries[type]
    }

    // MARK: - WidgetDecoding

    public func decodeContent(
        type: String,
        from container: KeyedDecodingContainer<WidgetCodingKeys>
    ) throws -> (any WidgetContent)? {
        guard let entry = entry(for: type) else { return nil }
        return try entry.decode(container)
    }

    // MARK: - View building

    @MainActor
    public func view(for widget: AnyWidget, context: WidgetContext) -> AnyView? {
        guard let entry = entry(for: widget.type) else { return nil }
        return entry.makeView(widget.content, context)
    }

    @MainActor
    public func skeleton(forType type: String) -> AnyView {
        if let makeSkeleton = entry(for: type)?.makeSkeleton {
            return makeSkeleton()
        }
        return AnyView(DefaultSkeletonBlock())
    }
}

private struct FlowRegistryKey: EnvironmentKey {
    static let defaultValue = WidgetRegistry()
}

public extension EnvironmentValues {
    /// The active widget registry. `FlowPageView` and `FlowSheetView` install the
    /// one they were created with; reads outside them get an empty registry.
    var flowRegistry: WidgetRegistry {
        get { self[FlowRegistryKey.self] }
        set { self[FlowRegistryKey.self] = newValue }
    }
}
