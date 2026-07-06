import AppKit

final class CatView: NSView {
    var image: NSImage? {
        didSet { needsDisplay = true }
    }
 
    var isMirrored = false {
        didSet { needsDisplay = true }
    }

    var onMouseDown: ((NSEvent) -> Void)?
    var onMouseDragged: ((NSEvent) -> Void)?
    var onMouseUp: ((NSEvent) -> Void)?
    var onRightMouseDown: ((NSEvent) -> Void)?

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()
        guard let image else { return }

        let target = bottomAlignedAspectFitRect(imageSize: image.size, in: bounds)
        if isMirrored {
            NSGraphicsContext.saveGraphicsState()
            let transform = NSAffineTransform()
            transform.translateX(by: bounds.maxX, yBy: 0)
            transform.scaleX(by: -1, yBy: 1)
            transform.concat()
            image.draw(in: target)
            NSGraphicsContext.restoreGraphicsState()
        } else {
            image.draw(in: target)
        }
    }

    private func bottomAlignedAspectFitRect(imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, bounds.width > 0, bounds.height > 0 else {
            return bounds
        }
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    override func mouseDown(with event: NSEvent) {
        onMouseDown?(event)
        
        if event.clickCount == 2 {
            print("Double clicked!")
            
            TaskReminderManager.shared.showTaskManagerWindow()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        onMouseDragged?(event)
    }

    override func mouseUp(with event: NSEvent) {
        onMouseUp?(event)
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightMouseDown?(event)
    }
}
