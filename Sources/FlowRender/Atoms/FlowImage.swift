import SwiftUI
import FlowCore

/// Renders an `ImageData` atom: async loading through the environment's
/// `FlowImageLoader`, aspect ratio reservation, corner rounding and an optional
/// shimmer placeholder.
public struct FlowImage: View {
    private enum Phase {
        case loading
        case loaded(Image)
        case failed
    }

    private let data: ImageData
    @State private var phase: Phase = .loading
    @Environment(\.flowTheme) private var theme
    @Environment(\.flowImageLoader) private var loader

    public init(_ data: ImageData) {
        self.data = data
    }

    public var body: some View {
        content
            .clipShape(UnevenRoundedRectangle(cornerRadii: (data.cornerRadius ?? .zero).rectangleCornerRadii))
            .task(id: data.url) {
                await load()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            placeholder
                .flowShimmer(active: data.showShimmer ?? false)
        case .loaded(let image):
            sized(image)
        case .failed:
            placeholder
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        let color = theme.color(data.placeholderColor, fallback: theme.defaults.surfaceColor)
        if let aspect = data.aspectRatio {
            color.aspectRatio(aspect, contentMode: .fit)
        } else {
            color
        }
    }

    @ViewBuilder
    private func sized(_ image: Image) -> some View {
        let resizable = image.resizable()
        if let aspect = data.aspectRatio {
            if data.scaleMode == "fit" {
                resizable.aspectRatio(aspect, contentMode: .fit)
            } else {
                // Reserve the aspect shape, fill it, crop the overflow.
                Color.clear
                    .aspectRatio(aspect, contentMode: .fit)
                    .overlay { resizable.scaledToFill() }
                    .clipped()
            }
        } else if data.scaleMode == "fit" {
            resizable.scaledToFit()
        } else {
            resizable.scaledToFill()
        }
    }

    private func load() async {
        guard let url = URL(string: data.url) else {
            phase = .failed
            return
        }
        do {
            let bytes = try await loader.imageData(for: url)
            if let image = Image(flowData: bytes) {
                phase = .loaded(image)
            } else {
                phase = .failed
            }
        } catch {
            phase = .failed
        }
    }
}

#Preview("FlowImage", traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        FlowImage(ImageData(
            url: "https://picsum.photos/600/300",
            aspectRatio: 2,
            cornerRadius: CornerRadiusData(uniform: 12),
            showShimmer: true
        ))
        FlowImage(ImageData(
            url: "https://picsum.photos/300",
            aspectRatio: 1,
            cornerRadius: CornerRadiusData(uniform: 60)
        ))
        .frame(width: 120)
    }
    .padding()
}
