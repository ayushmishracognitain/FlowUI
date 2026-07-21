import SwiftUI
import FlowCore

/// Applies a backend `WidgetLayout` to any view.
///
/// This one modifier is the whole chrome story: instead of widgets styling their
/// own containers, the backend describes spacing, fill, shape and stroke, and the
/// renderer applies it uniformly. The order is fixed, inside out:
/// padding, background and gradient, corner clipping, border, margin.
public struct WidgetLayoutModifier: ViewModifier {
    private let layout: WidgetLayout
    @Environment(\.flowTheme) private var theme

    public init(layout: WidgetLayout) {
        self.layout = layout
    }

    public func body(content: Content) -> some View {
        content
            .padding((layout.padding ?? .zero).edgeInsets)
            .frame(maxWidth: layout.width == .fill ? .infinity : nil)
            .background { backgroundFill }
            .clipShape(clipShape)
            .overlay { borderOverlay }
            .padding((layout.margin ?? .zero).edgeInsets)
    }

    private var cornerRadii: RectangleCornerRadii {
        (layout.cornerRadius ?? .zero).rectangleCornerRadii
    }

    private var clipShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(cornerRadii: cornerRadii)
    }

    @ViewBuilder
    private var backgroundFill: some View {
        ZStack {
            if let background = theme.color(layout.background) {
                background
            }
            if let gradient = layout.gradient {
                FlowGradient.linear(gradient, theme: theme)
            }
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if let border = layout.border, let color = theme.color(border.color) {
            let width = border.width ?? 1
            if let dashWidth = border.dashWidth, let dashGap = border.dashGap {
                clipShape.strokeBorder(color, style: StrokeStyle(lineWidth: width, dash: [dashWidth, dashGap]))
            } else {
                clipShape.strokeBorder(color, lineWidth: width)
            }
        }
    }
}

public extension View {
    /// Applies backend driven chrome. Passing `nil` leaves the view untouched.
    @ViewBuilder
    func widgetLayout(_ layout: WidgetLayout?) -> some View {
        if let layout {
            modifier(WidgetLayoutModifier(layout: layout))
        } else {
            self
        }
    }
}

#Preview("widgetLayout", traits: .sizeThatFitsLayout) {
    VStack(spacing: 0) {
        Text("Card with everything")
            .widgetLayout(WidgetLayout(
                margin: EdgeInsetsData(top: 12, left: 16, right: 16),
                padding: EdgeInsetsData(top: 16, left: 16, right: 16, bottom: 16),
                cornerRadius: CornerRadiusData(uniform: 14),
                background: ColorData(hex: "#FFF3F4"),
                border: BorderData(width: 1, color: ColorData(hex: "#E23744")),
                width: .fill
            ))
        Text("Gradient chip")
            .foregroundStyle(.white)
            .widgetLayout(WidgetLayout(
                margin: EdgeInsetsData(top: 12),
                padding: EdgeInsetsData(top: 8, left: 14, right: 14, bottom: 8),
                cornerRadius: CornerRadiusData(uniform: 20),
                gradient: GradientData(colors: [ColorData(hex: "#FF512F"), ColorData(hex: "#DD2476")], angle: 0)
            ))
        Text("Dashed, uneven corners")
            .widgetLayout(WidgetLayout(
                margin: EdgeInsetsData(top: 12, bottom: 12),
                padding: EdgeInsetsData(top: 12, left: 12, right: 12, bottom: 12),
                cornerRadius: CornerRadiusData(topLeft: 16, topRight: 0, bottomLeft: 0, bottomRight: 16),
                border: BorderData(width: 1, color: ColorData(hex: "#888888"), dashWidth: 5, dashGap: 3)
            ))
    }
}
