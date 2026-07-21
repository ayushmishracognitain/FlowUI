import SwiftUI

/// Turns any view into a shimmering skeleton of itself.
///
/// Uses the system redaction so text becomes bars and images become blocks, then
/// sweeps a shimmer over the result. Interaction is disabled while active.
public struct SkeletonModifier: ViewModifier {
    private let active: Bool

    public init(active: Bool = true) {
        self.active = active
    }

    public func body(content: Content) -> some View {
        content
            .redacted(reason: active ? .placeholder : [])
            .flowShimmer(active: active)
            .allowsHitTesting(!active)
    }
}

public extension View {
    /// Redacts the view into placeholder shapes with a shimmer while `active` is true.
    func flowSkeleton(active: Bool = true) -> some View {
        modifier(SkeletonModifier(active: active))
    }
}

/// A generic skeleton block used when a widget provides no skeleton of its own.
public struct DefaultSkeletonBlock: View {
    private let height: CGFloat

    public init(height: CGFloat = 84) {
        self.height = height
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.25))
            .frame(height: height)
            .flowShimmer()
    }
}

#Preview("flowSkeleton", traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Circle().fill(Color.gray.opacity(0.4)).frame(width: 48, height: 48)
            VStack(alignment: .leading) {
                Text("A realistic title")
                Text("And a smaller subtitle under it")
            }
        }
        .flowSkeleton()

        DefaultSkeletonBlock()
    }
    .padding()
}
