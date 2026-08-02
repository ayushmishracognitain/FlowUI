import SwiftUI
import FlowCore

public extension EdgeInsetsData {
    /// Maps the backend's four sided inset atom to SwiftUI's EdgeInsets.
    var edgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

public extension CornerRadiusData {
    var rectangleCornerRadii: RectangleCornerRadii {
        RectangleCornerRadii(
            topLeading: topLeft,
            bottomLeading: bottomLeft,
            bottomTrailing: bottomRight,
            topTrailing: topRight
        )
    }
}

public extension TextData {
    var textAlignment: TextAlignment {
        switch alignment {
        case "center": .center
        case "trailing", "right": .trailing
        default: .leading
        }
    }

    var frameAlignment: Alignment {
        switch alignment {
        case "center": .center
        case "trailing", "right": .trailing
        default: .leading
        }
    }
}
