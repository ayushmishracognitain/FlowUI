import SwiftUI
import FlowCore

/// The generic server driven bottom sheet: fixed header, scrolling sections,
/// fixed footer, with detents, grabber and dismissibility all backend controlled.
///
/// Present it from anything; `FlowPageView` does so automatically for the
/// `open_bottom_sheet` action. The presenting view's Flow-UI environment (registry,
/// theme, relay) carries into the sheet.
public struct FlowSheetView: View {
    private let model: SheetModel
    @Environment(\.flowTheme) private var theme

    public init(_ model: SheetModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let header = model.header {
                bar(header)
            }
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(model.sections) { section in
                        SectionRenderer(section)
                    }
                }
            }
            if let footer = model.footer {
                bar(footer)
            }
        }
        .background(theme.defaults.pageBackground)
        .presentationDetents(detents)
        .presentationDragIndicator(model.config.showsGrabber ? .visible : .hidden)
        .presentationCornerRadius(model.config.cornerRadius.map { CGFloat($0) })
        .interactiveDismissDisabled(!model.config.isDismissible)
    }

    private func bar(_ bar: PageBar) -> some View {
        VStack(spacing: 0) {
            ForEach(bar.widgets) { widget in
                WidgetRowView(widget)
            }
        }
    }

    private var detents: Set<PresentationDetent> {
        guard let declared = model.config.detents, !declared.isEmpty else {
            return [.medium, .large]
        }
        var result: Set<PresentationDetent> = []
        for value in declared {
            switch value {
            case .string("medium"):
                result.insert(.medium)
            case .string("large"):
                result.insert(.large)
            case .number(let fraction):
                result.insert(.fraction(fraction))
            case .string(let text):
                if let fraction = Double(text) {
                    result.insert(.fraction(fraction))
                }
            default:
                break
            }
        }
        return result.isEmpty ? [.medium, .large] : result
    }
}
