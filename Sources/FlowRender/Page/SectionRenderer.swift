import SwiftUI
import FlowCore

/// Renders one section in its declared arrangement: vertical list, horizontal
/// carousel, or grid. The optional section header pins while its section scrolls
/// under it, courtesy of the parent `LazyVStack`'s pinned views.
public struct SectionRenderer: View {
    private let section: SectionModel

    public init(_ section: SectionModel) {
        self.section = section
    }

    public var body: some View {
        Section {
            arrangedContent
                .padding(insets.edgeInsets)
        } header: {
            if let header = section.header {
                WidgetRowView(header)
            }
        }
    }

    private var insets: EdgeInsetsData {
        section.layout.insets ?? .zero
    }

    private var spacing: CGFloat {
        section.layout.itemSpacing ?? 0
    }

    @ViewBuilder
    private var arrangedContent: some View {
        switch section.layout.arrangement {
        case .vertical:
            VStack(spacing: spacing) {
                ForEach(section.widgets) { widget in
                    WidgetRowView(widget)
                }
            }
        case .carousel:
            carousel
        case .grid:
            LazyVGrid(columns: gridColumns, spacing: spacing) {
                ForEach(section.widgets) { widget in
                    WidgetRowView(widget)
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        let count = max(section.layout.columns ?? 2, 1)
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(section.widgets) { widget in
                    WidgetRowView(widget)
                        .modifier(CarouselItemWidth(width: widget.layout.width))
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

/// Sizes a carousel item from its declared width: a fraction of the visible
/// container produces peeking cards, `fill` takes the full width, `hug` lets the
/// content decide.
private struct CarouselItemWidth: ViewModifier {
    let width: WidgetWidth?

    func body(content: Content) -> some View {
        switch width {
        case .fraction(let fraction):
            content.containerRelativeFrame(.horizontal) { length, _ in
                length * fraction
            }
        case .fill:
            content.containerRelativeFrame(.horizontal)
        case .hug, nil:
            content
        }
    }
}
