import AppKit

@MainActor
final class CatInteractionController {
    private let threshold: CGFloat
    private var mouseDownScreenPoint: CGPoint?
    private var dragging = false

    var onClick: ((NSEvent) -> Void)?
    var onContextMenu: ((NSEvent) -> Void)?
    var onBeginDrag: (() -> Void)?
    var onDrag: ((CGPoint) -> Void)?
    var onEndDrag: ((CGPoint) -> Void)?

    init(catView: CatView, threshold: CGFloat = 20) {
        self.threshold = threshold
        catView.onMouseDown = { [weak self] event in self?.mouseDown(event) }
        catView.onMouseDragged = { [weak self] event in self?.mouseDragged(event) }
        catView.onMouseUp = { [weak self] event in self?.mouseUp(event) }
        catView.onRightMouseDown = { [weak self] event in self?.rightMouseDown(event) }
    }

    private func mouseDown(_ event: NSEvent) {
        mouseDownScreenPoint = event.locationInWindow.screenPoint(window: event.window)
        dragging = false
    }

    private func mouseDragged(_ event: NSEvent) {
        guard let start = mouseDownScreenPoint else { return }
        let point = event.locationInWindow.screenPoint(window: event.window)
        if !dragging, GeometryUtils.distance(start, point) >= threshold {
            dragging = true
            onBeginDrag?()
        }
        if dragging {
            onDrag?(point)
        }
    }

    private func mouseUp(_ event: NSEvent) {
        let point = event.locationInWindow.screenPoint(window: event.window)
        if dragging {
            onEndDrag?(point)
        }
        mouseDownScreenPoint = nil
        dragging = false
    }

    private func rightMouseDown(_ event: NSEvent) {
        onContextMenu?(event)
    }
}

private extension CGPoint {
    func screenPoint(window: NSWindow?) -> CGPoint {
        guard let window else { return self }
        return window.convertPoint(toScreen: self)
    }
}
