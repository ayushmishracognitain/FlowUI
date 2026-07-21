import SwiftUI
import FlowCore

/// The generic server driven screen.
///
/// Give it a `PageStore` and it does the rest: loading skeleton, error and empty
/// states, backend driven nav bar, sticky or scrolling header and footer bars,
/// sections in every arrangement, pull to refresh and cursor pagination.
///
/// ```swift
/// let registry = WidgetRegistry()
/// registry.register(MyCardWidget.self)
/// let store = PageStore(pageID: "home", loader: MyLoader(), registry: registry)
/// FlowPageView(store: store)
/// ```
public struct FlowPageView<LoadingView: View>: View {
    private let store: PageStore
    private let loadingView: LoadingView

    @State private var dispatcher: ActionDispatcher
    @State private var presenter = FlowPresenter()
    @Environment(\.flowTheme) private var theme

    /// Creates a page with a custom loading view. Pass a preconfigured dispatcher
    /// to add host handlers (deeplinks, custom action types); omitting it uses the
    /// built in handlers alone.
    public init(
        store: PageStore,
        dispatcher: ActionDispatcher? = nil,
        @ViewBuilder loadingView: () -> LoadingView
    ) {
        self.store = store
        self.loadingView = loadingView()
        _dispatcher = State(initialValue: dispatcher ?? ActionDispatcher())
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let nav = store.page?.nav {
                FlowNavBar(nav)
            }
            content
        }
        .background(theme.defaults.pageBackground)
        .environment(\.flowRegistry, store.registry)
        .environment(\.flowStateStore, store.stateStore)
        .environment(\.flowDispatcher, dispatcher)
        .environment(\.flowActionRelay, relay)
        .sheet(item: sheetBinding) { sheet in
            FlowSheetView(sheet)
                .environment(\.flowRegistry, store.registry)
                .environment(\.flowStateStore, store.stateStore)
                .environment(\.flowDispatcher, dispatcher)
                .environment(\.flowActionRelay, relay)
        }
        .overlay(alignment: .bottom) {
            if let toast = presenter.toast {
                ToastView(toast: toast)
            }
        }
        .animation(.spring(duration: 0.3), value: presenter.toast?.id)
        .task {
            if case .loading = store.state, store.page == nil {
                await store.loadInitial()
            }
        }
    }

    /// The presenter driving sheets, toasts and dismissal for this page. Hosts can
    /// observe `dismissRequested` through this to pop their own navigation.
    public var pagePresenter: FlowPresenter { presenter }

    private var relay: FlowActionRelay {
        FlowActionRelay { [store, dispatcher, presenter] action, widgetID in
            dispatcher.dispatch(
                action,
                context: ActionContext(sourceWidgetID: widgetID, pageStore: store, presenter: presenter)
            )
        }
    }

    private var sheetBinding: Binding<SheetModel?> {
        Binding(
            get: { presenter.activeSheet },
            set: { presenter.activeSheet = $0 }
        )
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            loadingView
        case .failed(let message):
            DefaultErrorView(message: message) {
                Task { await store.retry() }
            }
        case .empty:
            DefaultEmptyView()
        case .loaded(let page):
            loadedContent(page)
        }
    }

    @ViewBuilder
    private func loadedContent(_ page: PageModel) -> some View {
        if let header = page.header, header.sticky {
            bar(header)
        }
        scrollContent(page)
        if let footer = page.footer, footer.sticky {
            bar(footer)
        }
    }

    private func scrollContent(_ page: PageModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if let header = page.header, !header.sticky {
                    bar(header)
                }
                ForEach(page.sections) { section in
                    SectionRenderer(section)
                }
                if let footer = page.footer, !footer.sticky {
                    bar(footer)
                }
                if page.pagination?.hasMore == true {
                    paginationSentinel
                }
            }
        }
        .flowIfRefreshable(page.refresh?.pullToRefresh ?? false) {
            await store.refresh()
        }
    }

    private func bar(_ bar: PageBar) -> some View {
        VStack(spacing: 0) {
            ForEach(bar.widgets) { widget in
                WidgetRowView(widget)
            }
        }
    }

    private var paginationSentinel: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .task {
                await store.loadNextPage()
            }
    }
}

public extension FlowPageView where LoadingView == DefaultPageSkeleton {
    /// Creates a page with the default shimmering skeleton as its loading view.
    init(store: PageStore, dispatcher: ActionDispatcher? = nil) {
        self.init(store: store, dispatcher: dispatcher) { DefaultPageSkeleton() }
    }
}

private extension View {
    @ViewBuilder
    func flowIfRefreshable(_ enabled: Bool, action: @escaping @Sendable () async -> Void) -> some View {
        if enabled {
            refreshable(action: action)
        } else {
            self
        }
    }
}
