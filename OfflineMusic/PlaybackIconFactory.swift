import UIKit

enum PlaybackIconKind: Equatable {
    case shuffle
    case previous
    case play
    case pause
    case next
    case repeatAll
    case repeatOne
}

final class PlaybackIconButton: UIButton {
    var iconKind: PlaybackIconKind = .play { didSet { setNeedsLayout() } }
    var iconColor: UIColor = .white { didSet { setNeedsLayout() } }
    var dominant = false { didSet { updateAppearance() } }

    private let iconLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        layer.addSublayer(iconLayer)
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize { CGSize(width: dominant ? 60 : 44, height: dominant ? 60 : 44) }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateAppearance()
        let side = min(bounds.width, bounds.height)
        let iconSide = dominant ? min(30, side - 20) : min(28, side - 12)
        iconLayer.frame = CGRect(x: (bounds.width - iconSide) / 2, y: (bounds.height - iconSide) / 2, width: iconSide, height: iconSide)
        iconLayer.path = PlaybackIconFactory.path(for: iconKind, in: iconLayer.bounds)
        iconLayer.strokeColor = iconColor.cgColor
        iconLayer.fillColor = iconColor.cgColor
    }

    private func updateAppearance() {
        backgroundColor = dominant ? .white : .clear
        layer.cornerRadius = dominant ? 30 : 0
        layer.masksToBounds = dominant
        accessibilityLabel = PlaybackIconFactory.accessibilityLabel(for: iconKind)
    }
}

enum PlaybackIconFactory {
    static func accessibilityLabel(for kind: PlaybackIconKind) -> String {
        switch kind {
        case .shuffle: return "Shuffle"
        case .previous: return "Previous track"
        case .play: return "Play"
        case .pause: return "Pause"
        case .next: return "Next track"
        case .repeatAll: return "Repeat all"
        case .repeatOne: return "Repeat one"
        }
    }

    static func path(for kind: PlaybackIconKind, in rect: CGRect) -> CGPath {
        switch kind {
        case .shuffle: return shufflePath(in: rect)
        case .previous: return previousPath(in: rect)
        case .play: return playPath(in: rect)
        case .pause: return pausePath(in: rect)
        case .next: return nextPath(in: rect)
        case .repeatAll: return repeatPath(in: rect, withOne: false)
        case .repeatOne: return repeatPath(in: rect, withOne: true)
        }
    }

    private static func shufflePath(in rect: CGRect) -> CGPath {
        let p = UIBezierPath()
        let x0 = rect.minX + rect.width * 0.08
        let x1 = rect.maxX - rect.width * 0.08
        let yTop = rect.minY + rect.height * 0.28
        let yBottom = rect.maxY - rect.height * 0.28
        let mid = rect.midX
        p.move(to: CGPoint(x: x0, y: yTop)); p.addLine(to: CGPoint(x: x0 + rect.width * 0.18, y: yTop)); p.addLine(to: CGPoint(x: x1 - rect.width * 0.18, yBottom)); p.addLine(to: CGPoint(x: x1, y: yBottom))
        p.move(to: CGPoint(x: x0, y: yBottom)); p.addLine(to: CGPoint(x: x0 + rect.width * 0.18, y: yBottom)); p.addLine(to: CGPoint(x: mid, y: rect.midY)); p.addLine(to: CGPoint(x: x1 - rect.width * 0.18, y: yTop)); p.addLine(to: CGPoint(x: x1, y: yTop))
        addArrow(to: p, tip: CGPoint(x: x1, y: yBottom), direction: CGPoint(x: -1, y: 0))
        addArrow(to: p, tip: CGPoint(x: x1, y: yTop), direction: CGPoint(x: -1, y: 0))
        p.lineWidth = max(1.8, rect.width * 0.09); p.lineCapStyle = .round; p.lineJoinStyle = .round
        return p.cgPath
    }

    private static func previousPath(in rect: CGRect) -> CGPath {
        let p = UIBezierPath(); let barX = rect.minX + rect.width * 0.18
        p.move(to: CGPoint(x: barX, y: rect.minY + rect.height * 0.16)); p.addLine(to: CGPoint(x: barX, y: rect.maxY - rect.height * 0.16))
        p.move(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.16)); p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.midY)); p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.maxY - rect.height * 0.16)); p.close()
        p.lineWidth = max(1.8, rect.width * 0.08); p.lineCapStyle = .round; p.lineJoinStyle = .round
        return p.cgPath
    }

    private static func playPath(in rect: CGRect) -> CGPath {
        let p = UIBezierPath(); p.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.12)); p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.14, y: rect.midY)); p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.maxY - rect.height * 0.12)); p.close(); return p.cgPath
    }

    private static func pausePath(in rect: CGRect) -> CGPath {
        let p = UIBezierPath(roundedRect: CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.12, width: rect.width * 0.2, height: rect.height * 0.76), cornerRadius: rect.width * 0.06)
        p.append(UIBezierPath(roundedRect: CGRect(x: rect.minX + rect.width * 0.6, y: rect.minY + rect.height * 0.12, width: rect.width * 0.2, height: rect.height * 0.76), cornerRadius: rect.width * 0.06)); return p.cgPath
    }

    private static func nextPath(in rect: CGRect) -> CGPath {
        let p = UIBezierPath(); p.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.16)); p.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.38, y: rect.midY)); p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY - rect.height * 0.16)); p.close(); let barX = rect.maxX - rect.width * 0.18
        p.move(to: CGPoint(x: barX, y: rect.minY + rect.height * 0.16)); p.addLine(to: CGPoint(x: barX, y: rect.maxY - rect.height * 0.16)); p.lineWidth = max(1.8, rect.width * 0.08); p.lineCapStyle = .round; p.lineJoinStyle = .round; return p.cgPath
    }

    private static func repeatPath(in rect: CGRect, withOne: Bool) -> CGPath {
        let p = UIBezierPath(); let inset = rect.width * 0.16; let radius = rect.width * 0.28; let center = CGPoint(x: rect.midX, y: rect.midY)
        p.addArc(withCenter: CGPoint(x: center.x, y: center.y - rect.height * 0.12), radius: radius, startAngle: .pi * 0.15, endAngle: .pi * 1.2, clockwise: true)
        p.move(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.18)); p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.42)); p.addLine(to: CGPoint(x: rect.maxX - inset - rect.width * 0.2, y: rect.minY + rect.height * 0.3))
        p.addArc(withCenter: CGPoint(x: center.x, y: center.y + rect.height * 0.12), radius: radius, startAngle: .pi * 1.15, endAngle: .pi * 0.2, clockwise: true)
        p.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY - rect.height * 0.18)); p.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - rect.height * 0.42)); p.addLine(to: CGPoint(x: rect.minX + inset + rect.width * 0.2, y: rect.maxY - rect.height * 0.3))
        if withOne { p.move(to: CGPoint(x: rect.midX + rect.width * 0.02, y: rect.midY - rect.height * 0.05)); p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.02, y: rect.midY + rect.height * 0.26)); p.move(to: CGPoint(x: rect.midX - rect.width * 0.05, y: rect.midY - rect.height * 0.02)); p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.02, y: rect.midY - rect.height * 0.05)) }
        p.lineWidth = max(1.7, rect.width * 0.08); p.lineCapStyle = .round; p.lineJoinStyle = .round; return p.cgPath
    }

    private static func addArrow(to path: UIBezierPath, tip: CGPoint, direction: CGPoint) {
        let size: CGFloat = 4.5; path.move(to: tip); path.addLine(to: CGPoint(x: tip.x + direction.x * size, y: tip.y - size)); path.move(to: tip); path.addLine(to: CGPoint(x: tip.x + direction.x * size, y: tip.y + size))
    }
}
