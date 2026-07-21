import SwiftUI
import FlowCore

/// `{"type": "toast", "message": "Saved"}`
public struct ToastActionHandler: ActionHandler {
    private struct Payload: Decodable {
        let message: String
        let duration: TimeInterval?
    }

    public init() {}

    public func handle(_ action: ActionData, context: ActionContext) async -> Bool {
        guard action.type == "toast", let payload = try? action.payload(Payload.self) else { return false }
        context.presenter?.show(ToastData(message: payload.message, duration: payload.duration ?? 2.5))
        return true
    }
}

/// `{"type": "dismiss"}` closes the active sheet, or asks the host to dismiss the page.
public struct DismissActionHandler: ActionHandler {
    public init() {}

    public func handle(_ action: ActionData, context: ActionContext) async -> Bool {
        guard action.type == "dismiss" else { return false }
        context.presenter?.dismiss()
        return true
    }
}

/// `{"type": "refresh_page"}` reloads the current page from the loader.
public struct RefreshPageActionHandler: ActionHandler {
    public init() {}

    public func handle(_ action: ActionData, context: ActionContext) async -> Bool {
        guard action.type == "refresh_page" else { return false }
        await context.pageStore?.refresh()
        return true
    }
}

/// `{"type": "open_bottom_sheet", "sheet": { ... }}` presents an inline server
/// driven sheet. Sheets that need a network round trip are a host concern: register
/// a handler for your own type, fetch, then redispatch with the inline payload.
public struct OpenBottomSheetActionHandler: ActionHandler {
    public init() {}

    public func handle(_ action: ActionData, context: ActionContext) async -> Bool {
        guard action.type == "open_bottom_sheet" else { return false }
        guard let fragment = action.raw["sheet"], let registry = context.pageStore?.registry else { return false }
        do {
            let sheet = try fragment.decoded(
                as: SheetModel.self,
                decoder: FlowDecoder.make(widgetDecoding: registry, diagnostics: context.pageStore?.diagnostics)
            )
            context.presenter?.present(sheet: sheet)
            return true
        } catch {
            return false
        }
    }
}

/// `{"type": "api", ...}` sends the whole action object to the loader and applies
/// the mutations the backend returns. This is how a tap can update a widget in
/// place without reloading the page.
public struct APIActionHandler: ActionHandler {
    public init() {}

    public func handle(_ action: ActionData, context: ActionContext) async -> Bool {
        guard action.type == "api", let store = context.pageStore else { return false }
        do {
            let data = try await store.performAction(payload: action.raw)
            let response = try FlowDecoder.make(
                widgetDecoding: store.registry,
                diagnostics: store.diagnostics
            ).decode(ActionResponse.self, from: data)

            for instruction in response.mutations {
                store.apply(instruction.pageMutation)
            }
            if let toast = response.toast {
                context.presenter?.show(ToastData(message: toast.message))
            }
            return true
        } catch {
            context.presenter?.show(ToastData(message: "Something went wrong"))
            return true
        }
    }
}
