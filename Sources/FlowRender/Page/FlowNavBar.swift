import SwiftUI
import FlowCore

/// The backend driven navigation bar rendered at the top of a `FlowPageView`.
///
/// Deliberately a plain view rather than a `NavigationStack` toolbar, so pages can
/// be dropped into whatever navigation container the host already uses.
public struct FlowNavBar: View {
    private let nav: NavModel
    @Environment(\.flowTheme) private var theme
    @Environment(\.flowActionRelay) private var relay

    public init(_ nav: NavModel) {
        self.nav = nav
    }

    public var body: some View {
        HStack(spacing: 12) {
            if let left = nav.leftButton {
                FlowButton(left) {
                    relay(leftAction, from: nil)
                }
            }
            VStack(spacing: 2) {
                if let title = nav.title {
                    Text(title.text)
                        .font(theme.font(title.font, fallback: .headline))
                        .foregroundStyle(theme.color(title.color, fallback: theme.defaults.textColor))
                }
                if let subtitle = nav.subtitle {
                    Text(subtitle.text)
                        .font(theme.font(subtitle.font, fallback: .caption))
                        .foregroundStyle(theme.color(subtitle.color, fallback: theme.defaults.secondaryTextColor))
                }
            }
            .frame(maxWidth: .infinity)
            HStack(spacing: 8) {
                ForEach(Array((nav.rightButtons ?? []).enumerated()), id: \.offset) { _, button in
                    FlowButton(button) {
                        // A button with no action does nothing. Dispatching a
                        // synthetic "none" only put an unhandled entry in the log.
                        guard let action = button.action else { return }
                        relay(action, from: nil)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.color(nav.backgroundColor, fallback: theme.defaults.pageBackground))
    }

    private var leftAction: ActionData {
        nav.leftButton?.action ?? ActionData(type: "dismiss")
    }
}
