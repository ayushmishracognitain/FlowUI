import SwiftUI
import Observation
import FlowCore

/// A toast queued for display.
public struct ToastData: Identifiable, Sendable {
    public let id = UUID()
    public let message: String
    public let duration: TimeInterval

    public init(message: String, duration: TimeInterval = 2.5) {
        self.message = message
        self.duration = duration
    }
}

/// Presentation state owned by a `FlowPageView`: the active server driven sheet,
/// the visible toast, and a dismiss signal the host can observe.
@Observable
@MainActor
public final class FlowPresenter {
    public var activeSheet: SheetModel?
    public var toast: ToastData?
    /// Set to true by the `dismiss` action. Hosts embedding a page in their own
    /// navigation observe this to pop or dismiss the containing screen.
    public var dismissRequested = false

    /// Called when a `dismiss` action fires; the default clears the active sheet
    /// or raises `dismissRequested`.
    public var onDismiss: (() -> Void)?

    public init() {}

    public func show(_ toast: ToastData) {
        self.toast = toast
        Task { [weak self, id = toast.id] in
            try? await Task.sleep(for: .seconds(toast.duration))
            if self?.toast?.id == id {
                self?.toast = nil
            }
        }
    }

    public func present(sheet: SheetModel) {
        activeSheet = sheet
    }

    public func dismiss() {
        if let onDismiss {
            onDismiss()
        } else if activeSheet != nil {
            activeSheet = nil
        } else {
            dismissRequested = true
        }
    }
}
