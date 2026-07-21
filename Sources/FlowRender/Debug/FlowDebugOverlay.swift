import SwiftUI
import FlowCore

private struct FlowLayoutInspectionKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// When true, every widget row draws its bounds, type and id on screen.
    var flowLayoutInspection: Bool {
        get { self[FlowLayoutInspectionKey.self] }
        set { self[FlowLayoutInspectionKey.self] = newValue }
    }
}

public extension View {
    /// Attaches the in app debug console for a page.
    ///
    /// Debug builds get a floating bug button that opens a panel with three tools:
    /// decode diagnostics (exact key paths and errors for every problem widget),
    /// the action log (what fired and who handled it), and a layout inspector that
    /// outlines every widget with its type and id. Release builds compile to the
    /// unmodified view.
    func flowDebugOverlay(store: PageStore) -> some View {
        #if DEBUG
        modifier(FlowDebugOverlayModifier(store: store))
        #else
        self
        #endif
    }
}

#if DEBUG
private struct FlowDebugOverlayModifier: ViewModifier {
    let store: PageStore
    @State private var showPanel = false
    @State private var inspecting = false
    @Environment(\.flowDispatcher) private var dispatcher

    func body(content: Content) -> some View {
        content
            .environment(\.flowLayoutInspection, inspecting)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showPanel = true
                } label: {
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.7), in: Circle())
                }
                .padding(16)
                .accessibilityLabel("Flow-UI debug console")
            }
            .sheet(isPresented: $showPanel) {
                FlowDebugPanel(store: store, dispatcher: dispatcher, inspecting: $inspecting)
            }
    }
}

private struct FlowDebugPanel: View {
    let store: PageStore
    let dispatcher: ActionDispatcher?
    @Binding var inspecting: Bool
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tool", selection: $tab) {
                    Text("Diagnostics").tag(0)
                    Text("Actions").tag(1)
                    Text("Inspector").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                switch tab {
                case 0: diagnosticsList
                case 1: actionLog
                default: inspector
                }
            }
            .navigationTitle("Flow-UI Debug")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .presentationDetents([.medium, .large])
    }

    private var diagnosticsList: some View {
        List {
            let entries = store.diagnostics.entries
            if entries.isEmpty {
                Text("The last decode was clean.")
                    .foregroundStyle(.secondary)
            }
            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.kind.rawValue)
                            .font(.caption.weight(.bold))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(color(for: entry.kind).opacity(0.15), in: Capsule())
                            .foregroundStyle(color(for: entry.kind))
                        if let type = entry.widgetType {
                            Text(type).font(.caption.monospaced())
                        }
                    }
                    Text(entry.message)
                        .font(.caption)
                    Text(entry.codingPath)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }

    private var actionLog: some View {
        List {
            let log = dispatcher?.log ?? []
            if log.isEmpty {
                Text("No actions dispatched yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(log.reversed()) { entry in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(entry.type).font(.caption.monospaced().weight(.semibold))
                        Spacer()
                        Text(entry.date, style: .time).font(.caption2).foregroundStyle(.secondary)
                    }
                    Text(entry.handledBy.map { "Handled by \($0)" } ?? "Unhandled")
                        .font(.caption2)
                        .foregroundStyle(entry.handledBy == nil ? .red : .secondary)
                    if let source = entry.sourceWidgetID {
                        Text("From widget \(source)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var inspector: some View {
        Form {
            Toggle("Outline widgets", isOn: $inspecting)
            Text("Outlines every widget with its type and id so you can match what you see to the JSON that produced it.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func color(for kind: DecodeDiagnostics.Kind) -> Color {
        switch kind {
        case .unknownType: .orange
        case .malformedPayload: .red
        case .droppedElement: .purple
        }
    }
}
#endif
