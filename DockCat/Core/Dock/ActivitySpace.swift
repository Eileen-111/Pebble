import CoreGraphics
import Foundation

enum DockEdge: Equatable {
    case bottomVisible
    case bottomHidden
    case left
    case right
    case unknown
}

struct ActivitySpace: Equatable {
    var screenFrame: CGRect
    var visibleFrame: CGRect
    var dockEdge: DockEdge
    var walkRange: ClosedRange<CGFloat>
    var baselineY: CGFloat
    var entrancePoint: CGPoint

    static func make(screenFrame: CGRect, visibleFrame: CGRect, startPositionPercent: CGFloat = 75) -> ActivitySpace {
        let edge = inferredDockEdge(screenFrame: screenFrame, visibleFrame: visibleFrame)
        let dockHeight = max(0, visibleFrame.minY - screenFrame.minY)

        let baselineY: CGFloat
        let walkRange: ClosedRange<CGFloat>
        switch edge {
        case .bottomVisible:
            baselineY = visibleFrame.minY
            walkRange = visibleFrame.minX ... visibleFrame.maxX
        case .bottomHidden, .left, .right, .unknown:
            baselineY = screenFrame.minY + max(4, min(8, dockHeight))
            walkRange = screenFrame.minX ... screenFrame.maxX
        }

        let normalizedPercent = GeometryUtils.clamped(startPositionPercent, to: 0 ... 100) / 100
        let projectedX = screenFrame.minX + screenFrame.width * normalizedPercent

        let clampedX = GeometryUtils.clamped(projectedX, to: walkRange)
        return ActivitySpace(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            dockEdge: edge,
            walkRange: walkRange,
            baselineY: baselineY,
            entrancePoint: CGPoint(x: clampedX, y: baselineY)
        )
    }

    func clampedPoint(_ point: CGPoint, contentWidth: CGFloat = 0) -> CGPoint {
        let range = walkRangeForContent(width: contentWidth)
        return CGPoint(
            x: GeometryUtils.clamped(point.x, to: range),
            y: baselineY
        )
    }

    func walkRangeForContent(width: CGFloat) -> ClosedRange<CGFloat> {
        let safeWidth = max(0, width)
        let upperBound = walkRange.upperBound - safeWidth
        if upperBound < walkRange.lowerBound {
            return walkRange.lowerBound ... walkRange.lowerBound
        }
        return walkRange.lowerBound ... upperBound
    }

    private static func inferredDockEdge(screenFrame: CGRect, visibleFrame: CGRect) -> DockEdge {
        let bottomInset = visibleFrame.minY - screenFrame.minY
        let leftInset = visibleFrame.minX - screenFrame.minX
        let rightInset = screenFrame.maxX - visibleFrame.maxX
        let threshold: CGFloat = 24

        if bottomInset > threshold { return .bottomVisible }
        if leftInset > threshold { return .left }
        if rightInset > threshold { return .right }
        return .bottomHidden
    }
}
