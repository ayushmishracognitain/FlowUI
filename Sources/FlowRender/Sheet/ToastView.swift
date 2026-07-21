import SwiftUI

/// The default toast: a floating capsule near the bottom of the screen.
struct ToastView: View {
    let toast: ToastData

    var body: some View {
        Text(toast.message)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(.black.opacity(0.85), in: Capsule())
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
