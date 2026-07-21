import Foundation

/// An in place change to a loaded page, typically produced by an `api` action response.
public enum PageMutation: Sendable {
    case replacePage(PageModel)
    case appendSections([SectionModel])
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
        case .replaceWidget(let id, let widget):
            forEachSection { section in
                if let index = section.widgets.firstIndex(where: { $0.id == id }) {
                    section.widgets[index] = widget
                }
            }
        case .removeWidget(let id):
            forEachSection { section in
                section.widgets.removeAll { $0.id == id }
            }
            header?.widgets.removeAll { $0.id == id }
            footer?.widgets.removeAll { $0.id == id }
        }
    }

    private mutating func forEachSection(_ body: (inout SectionModel) -> Void) {
        for index in sections.indices {
            body(&sections[index])
        }
    }
}
