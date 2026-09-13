import Foundation

public struct WindowFrame: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public enum WindowPreset: String, Codable, Sendable, CaseIterable, Hashable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeftQuarter
    case topRightQuarter
    case bottomLeftQuarter
    case bottomRightQuarter
    case maximize
    case center

    public var displayName: String {
        switch self {
        case .leftHalf: return "left half"
        case .rightHalf: return "right half"
        case .topHalf: return "top half"
        case .bottomHalf: return "bottom half"
        case .topLeftQuarter: return "top-left quarter"
        case .topRightQuarter: return "top-right quarter"
        case .bottomLeftQuarter: return "bottom-left quarter"
        case .bottomRightQuarter: return "bottom-right quarter"
        case .maximize: return "maximized"
        case .center: return "centered"
        }
    }

    public var phraseSuffix: String {
        CommandLanguageCatalog.standard.arrangePresetPhrase(self)
    }

    public func targetFrame(in usable: WindowFrame, currentSize: WindowFrame) -> WindowFrame {
        let halfWidth = usable.width / 2
        let halfHeight = usable.height / 2
        let midX = usable.x + halfWidth
        let midY = usable.y + halfHeight

        switch self {
        case .leftHalf:
            return WindowFrame(x: usable.x, y: usable.y, width: halfWidth, height: usable.height)
        case .rightHalf:
            return WindowFrame(x: midX, y: usable.y, width: halfWidth, height: usable.height)
        case .topHalf:
            return WindowFrame(x: usable.x, y: usable.y, width: usable.width, height: halfHeight)
        case .bottomHalf:
            return WindowFrame(x: usable.x, y: midY, width: usable.width, height: halfHeight)
        case .topLeftQuarter:
            return WindowFrame(x: usable.x, y: usable.y, width: halfWidth, height: halfHeight)
        case .topRightQuarter:
            return WindowFrame(x: midX, y: usable.y, width: halfWidth, height: halfHeight)
        case .bottomLeftQuarter:
            return WindowFrame(x: usable.x, y: midY, width: halfWidth, height: halfHeight)
        case .bottomRightQuarter:
            return WindowFrame(x: midX, y: midY, width: halfWidth, height: halfHeight)
        case .maximize:
            return usable
        case .center:
            let width = min(currentSize.width, usable.width)
            let height = min(currentSize.height, usable.height)
            return WindowFrame(
                x: usable.x + (usable.width - width) / 2,
                y: usable.y + (usable.height - height) / 2,
                width: width,
                height: height
            )
        }
    }
}

public enum WindowDisplaySelection: Codable, Sendable, Hashable {
    case current
    case main
    case display(identifier: String)

    public var displayName: String {
        switch self {
        case .current: return "this window's display"
        case .main: return "the main display"
        case .display(let identifier): return identifier
        }
    }
}
