import Foundation

/// Names the envelope elements the backend left unnamed.
///
/// `AnyWidget`, `SectionModel` and `PageModel` are all `Identifiable`, and widget
/// ids additionally key the host's widget state store and address `replace_widget`
/// and `remove_widget` mutations. So the fallback used when the backend omits `id`
/// has to satisfy two properties at once:
///
/// - **Stable.** Two decodes of the same bytes must produce the same id. A random
///   fallback makes every refresh look like a completely new list to `ForEach`,
///   so SwiftUI throws the page away and rebuilds it rather than diffing it,
///   discarding scroll position and in flight image loads on the way.
/// - **Unique.** Two different elements in one response must never collide, or
///   `ForEach` renders incorrectly and mutations resolve to an arbitrary match.
///
/// A coding path is already exactly that: it names one position in the response
/// and nothing else, and the decoder hands us one for free.
///
/// Backends should still send real ids for anything interactive or replaceable.
/// This is the floor, not a replacement.
enum FlowIdentity {
    /// Builds `"<prefix>@<dotted coding path>"`, for example
    /// `"image_text_card@page.sections.0.widgets.2"`.
    static func positional(_ prefix: String, in codingPath: [CodingKey]) -> String {
        let path = codingPath
            .map { key in key.intValue.map(String.init) ?? key.stringValue }
            .joined(separator: ".")
        return path.isEmpty ? prefix : "\(prefix)@\(path)"
    }
}

/// Makes a collection of widget ids unique, renaming collisions rather than
/// letting them corrupt rendering.
struct WidgetIdentifierDeduplicator {
    private var seen: Set<String> = []
    private let diagnostics: DecodeDiagnostics?

    init(diagnostics: DecodeDiagnostics?) {
        self.diagnostics = diagnostics
    }

    /// Returns `id` when it is still free, otherwise a suffixed variant, recording
    /// the collision so the debug console can surface it.
    mutating func claim(_ id: String, type: String, at path: String) -> String {
        if seen.insert(id).inserted {
            return id
        }
        var counter = 2
        var candidate = "\(id)#\(counter)"
        while !seen.insert(candidate).inserted {
            counter += 1
            candidate = "\(id)#\(counter)"
        }
        diagnostics?.record(
            .duplicateID,
            widgetType: type,
            path: path,
            message: "Duplicate widget id '\(id)', renamed to '\(candidate)'. "
                + "Ids must be unique within a page, and mutations targeting '\(id)' are ambiguous."
        )
        return candidate
    }
}

public extension PageModel {
    /// Renames any widget that shares an id with an earlier one, so `ForEach`
    /// identity stays sound and mutations stay addressable.
    ///
    /// Applied automatically when a page decodes. `PageStore` applies it again
    /// after merging a paginated response, because two pages that were each
    /// internally consistent can still collide with one another.
    ///
    /// Widgets nested inside a payload, such as accordion items, are not visited:
    /// they are type erased behind `WidgetContent` and only ever iterated by their
    /// own parent, so their ids never have to be unique page wide.
    mutating func makeWidgetIdentifiersUnique(recordingTo diagnostics: DecodeDiagnostics? = nil) {
        var deduplicator = WidgetIdentifierDeduplicator(diagnostics: diagnostics)

        if header != nil {
            deduplicate(&header!.widgets, at: "header", with: &deduplicator)
        }
        for index in sections.indices {
            if sections[index].header != nil {
                sections[index].header!.id = deduplicator.claim(
                    sections[index].header!.id,
                    type: sections[index].header!.type,
                    at: "sections.\(index).header"
                )
            }
            deduplicate(&sections[index].widgets, at: "sections.\(index)", with: &deduplicator)
        }
        if footer != nil {
            deduplicate(&footer!.widgets, at: "footer", with: &deduplicator)
        }
    }

    private func deduplicate(
        _ widgets: inout [AnyWidget],
        at path: String,
        with deduplicator: inout WidgetIdentifierDeduplicator
    ) {
        for index in widgets.indices {
            widgets[index].id = deduplicator.claim(
                widgets[index].id,
                type: widgets[index].type,
                at: "\(path).widgets.\(index)"
            )
        }
    }
}
