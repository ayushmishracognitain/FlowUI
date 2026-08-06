import Foundation

/// An in place change to a loaded page, typically produced by an `api` action response.
public enum PageMutation: Sendable {
    case replacePage(PageModel)
    case appendSections([SectionModel])
    case prependSections([SectionModel])
    case replaceWidget(id: String, with: AnyWidget)
    case removeWidget(id: String)
}

public extension PageModel {
    mutating func apply(_ mutation: PageMutation) {
        switch mutation {
        case .replacePage(let page):
            self = page
        case .appendSections(let newSections):
            sections.append(contentsOf: newSections)
        case .prependSections(let newSections):
            sections.insert(contentsOf: newSections, at: 0)
        case .replaceWidget(let id, let widget):
            replaceWidget(id: id, with: widget)
        case .removeWidget(let id):
            removeWidget(id: id)
        }
    }

    /// Swaps the widget carrying `id` wherever it lives: the page header, a section
    /// header, a section body, or the page footer. A sticky footer button is as
    /// replaceable as a card in the middle of the list.
    private mutating func replaceWidget(id: String, with widget: AnyWidget) {
        if let index = header?.widgets.firstIndex(where: { $0.id == id }) {
            header?.widgets[index] = widget
        }
        for index in sections.indices {
            if sections[index].header?.id == id {
                sections[index].header = widget
            }
            if let widgetIndex = sections[index].widgets.firstIndex(where: { $0.id == id }) {
                sections[index].widgets[widgetIndex] = widget
            }
        }
        if let index = footer?.widgets.firstIndex(where: { $0.id == id }) {
            footer?.widgets[index] = widget
        }
    }

    /// Removes the widget carrying `id` from every location `replaceWidget` reaches.
    private mutating func removeWidget(id: String) {
        header?.widgets.removeAll { $0.id == id }
        for index in sections.indices {
            if sections[index].header?.id == id {
                sections[index].header = nil
            }
            sections[index].widgets.removeAll { $0.id == id }
        }
        footer?.widgets.removeAll { $0.id == id }
    }
}
