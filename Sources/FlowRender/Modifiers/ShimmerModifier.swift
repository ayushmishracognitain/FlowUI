import SwiftUI

/// An animated highlight sweep for loading placeholders.
///
/// Works in both appearances: the highlight is a translucent band moving across
/// the view, masked to the view's own bounds.
///
/// The sweep is masked to a rectangle rather than to `content`. Masking with the
/// content itself put the whole widget in the view tree a second time, doubling
/// its layout and render cost for what is only ever a decorative band. The
/// animation is also driven by `.task` rather than `.onAppear`, so a row scrolled
/// out of a lazy stack stops animating instead of running forever offscreen.
public struct ShimmerModifier: ViewModifier {
    private let active: Bool
    @State private var phase: CGFloat = -1.5

    public init(active: Bool = true) {
        self.active = active
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    sweep
                }
            }
            .task(id: active) {
                guard active else { return }
                phase = -1.5
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }

    private var sweep: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: [.clear, .white.opacity(0.55), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: proxy.size.width * 0.9)
            .offset(x: phase * proxy.size.width)
            .blendMode(.plusLighter)
        }
        .allowsHitTesting(false)
        .clipped()
    }
}

public extension View {
    /// Sweeps an animated highlight across the view while `active` is true.
    func flowShimmer(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}

#Preview("flowShimmer", traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 20)
            .flowShimmer()
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 120)
            .flowShimmer()
    }
    .padding()
}
