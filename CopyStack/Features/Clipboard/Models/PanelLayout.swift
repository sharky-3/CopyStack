import SwiftUI

enum PanelLayout {
    case strip
    case column
    case grid
}

enum PanelPosition: String, CaseIterable, Identifiable, Codable {
    case top
    case left
    case bottom
    case right
    case center

    var id: String { rawValue }

    var title: String {
        switch self {
        case .top: return "Top"
        case .left: return "Left"
        case .bottom: return "Bottom"
        case .right: return "Right"
        case .center: return "Center"
        }
    }

    var symbol: String {
        switch self {
        case .top: return "rectangle.topthird.inset.filled"
        case .left: return "rectangle.leadingthird.inset.filled"
        case .bottom: return "rectangle.bottomthird.inset.filled"
        case .right: return "rectangle.trailingthird.inset.filled"
        case .center: return "rectangle.center.inset.filled"
        }
    }

    var layout: PanelLayout {
        switch self {
        case .top, .bottom: return .strip
        case .left, .right: return .column
        case .center: return .grid
        }
    }

    var anchor: UnitPoint {
        switch self {
        case .top: return .top
        case .left: return .leading
        case .bottom: return .bottom
        case .right: return .trailing
        case .center: return .center
        }
    }

    var hiddenOffset: CGSize {
        switch self {
        case .top: return CGSize(width: 0, height: -40)
        case .left: return CGSize(width: -40, height: 0)
        case .bottom: return CGSize(width: 0, height: 40)
        case .right: return CGSize(width: 40, height: 0)
        case .center: return .zero
        }
    }

    var summary: String {
        switch self {
        case .top: return "A wide shelf slides down from the top edge."
        case .left: return "A tall column glides in from the left edge."
        case .bottom: return "A wide shelf rises from the bottom edge."
        case .right: return "A tall column glides in from the right edge."
        case .center: return "A roomy grid appears in the middle of your screen."
        }
    }
}

enum CardSize: String, CaseIterable, Identifiable {
    case compact
    case comfortable
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: return "Compact"
        case .comfortable: return "Comfortable"
        case .large: return "Large"
        }
    }

    var columnWidth: CGFloat {
        switch self {
        case .compact: return 340
        case .comfortable: return 390
        case .large: return 450
        }
    }

    func metrics(for layout: PanelLayout) -> CardMetrics {
        switch layout {
        case .strip:
            switch self {
            case .compact: return CardMetrics(width: 220, height: 200, textLines: 7, thumbPixel: 480)
            case .comfortable: return CardMetrics(width: 270, height: 250, textLines: 11, thumbPixel: 560)
            case .large: return CardMetrics(width: 330, height: 300, textLines: 15, thumbPixel: 700)
            }
        case .column:
            switch self {
            case .compact: return CardMetrics(width: nil, height: 130, textLines: 3, thumbPixel: 640)
            case .comfortable: return CardMetrics(width: nil, height: 165, textLines: 5, thumbPixel: 760)
            case .large: return CardMetrics(width: nil, height: 210, textLines: 7, thumbPixel: 900)
            }
        case .grid:
            switch self {
            case .compact: return CardMetrics(width: nil, height: 180, textLines: 6, thumbPixel: 520)
            case .comfortable: return CardMetrics(width: nil, height: 220, textLines: 9, thumbPixel: 600)
            case .large: return CardMetrics(width: nil, height: 270, textLines: 12, thumbPixel: 720)
            }
        }
    }
}

struct CardMetrics: Equatable {
    var width: CGFloat?
    var height: CGFloat
    var textLines: Int
    var thumbPixel: CGFloat
}

enum PanelGeometry {
    static func size(position: PanelPosition, cardSize: CardSize, in frame: CGRect, margin: CGFloat) -> CGSize {
        let metrics = cardSize.metrics(for: position.layout)
        switch position.layout {
        case .strip:
            return CGSize(width: frame.width - margin * 2, height: metrics.height + 196)
        case .column:
            return CGSize(width: min(cardSize.columnWidth, frame.width - margin * 2), height: frame.height - margin * 2)
        case .grid:
            return CGSize(width: min(frame.width - margin * 2, 900), height: min(frame.height - margin * 2, 600))
        }
    }

    static func origin(position: PanelPosition, size: CGSize, in frame: CGRect, margin: CGFloat) -> CGPoint {
        switch position {
        case .top:
            return CGPoint(x: frame.midX - size.width / 2, y: frame.maxY - size.height - margin)
        case .bottom:
            return CGPoint(x: frame.midX - size.width / 2, y: frame.minY + margin)
        case .left:
            return CGPoint(x: frame.minX + margin, y: frame.midY - size.height / 2)
        case .right:
            return CGPoint(x: frame.maxX - size.width - margin, y: frame.midY - size.height / 2)
        case .center:
            return CGPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2)
        }
    }
}
