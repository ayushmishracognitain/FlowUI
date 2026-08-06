import SwiftUI
import Observation

/// Page scoped storage for ephemeral widget state.
///
/// Server data is immutable; what the user is doing right now (a stepper count,
/// an expanded accordion, an input draft) lives here, keyed by widget id and a
/// name the widget chooses. Keeping it outside the views means state survives
/// lazy container recycling and scrolling.
///
/// A page refresh clears the store; pagination appends leave it untouched.
///
/// Main actor isolated: the store is read and written from view bodies and from
/// SwiftUI control callbacks, and the isolation is what makes it `Sendable` so it
/// can be carried in `WidgetContext` and in the environment.
@Observable
@MainActor
public final class WidgetStateStore {
    private var storage: [String: [String: Any]] = [:]

    public nonisolated init() {}

    public func value<T>(widgetID: String, key: String) -> T? {
        storage[widgetID]?[key] as? T
    }

    public func set<T>(_ value: T, widgetID: String, key: String) {
        storage[widgetID, default: [:]][key] = value
    }

    /// A binding into the store with a default, ready to hand to SwiftUI controls.
    public func binding<T>(widgetID: String, key: String, default defaultValue: T) -> Binding<T> {
        Binding(
            get: { [weak self] in
                self?.value(widgetID: widgetID, key: key) ?? defaultValue
            },
            set: { [weak self] newValue in
                self?.set(newValue, widgetID: widgetID, key: key)
            }
        )
    }

    public func reset() {
        storage.removeAll()
    }
}
