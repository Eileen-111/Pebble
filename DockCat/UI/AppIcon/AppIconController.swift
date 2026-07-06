import AppKit

@MainActor
final class AppIconController {
    typealias FileIconApplier = (NSImage, String) -> Bool

    private let bundle: Bundle
    private let fileIconApplier: FileIconApplier
    private var iconSource: AppIconSource?

    init(
        bundle: Bundle = .main,
        fileIconApplier: @escaping FileIconApplier = { image, path in
            NSWorkspace.shared.setIcon(image, forFile: path, options: [])
        }
    ) {
        self.bundle = bundle
        self.fileIconApplier = fileIconApplier
    }

    func updateIconSource(_ iconSource: AppIconSource?) {
        self.iconSource = iconSource
    }

    func showSleepIcon() {
        setIcon(url: iconSource?.sleepURL, fallbackName: "icon_sleep")
    }

    func showEmptyIcon() {
        setIcon(url: iconSource?.emptyURL, fallbackName: "icon_empty")
    }

    @discardableResult
    func applyPersistentFileIconIfNeeded() -> Bool {
        guard
            iconSource?.usesCustomIcons == true,
            let sleepURL = iconSource?.sleepURL,
            let image = NSImage(contentsOf: sleepURL)
        else {
            return false
        }

        let didApply = fileIconApplier(image, bundle.bundlePath)
        if !didApply {
            DockCatLog.app.error("Failed to apply persistent custom app icon to \(self.bundle.bundlePath)")
        }
        return didApply
    }

    private func setIcon(url: URL?, fallbackName name: String) {
        if let url, let image = NSImage(contentsOf: url) {
            NSApplication.shared.applicationIconImage = iconSource?.usesCustomIcons == true
                ? image
                : Self.transparentSquareIcon(from: image)
            return
        }

        let candidates = [
            bundle.url(forResource: name, withExtension: "png"),
            bundle.url(forResource: name, withExtension: "png", subdirectory: "AppIcon"),
            bundle.url(forResource: name, withExtension: "png", subdirectory: "Resources/AppIcon")
        ].compactMap { $0 }
        guard let url = candidates.first, let image = NSImage(contentsOf: url) else {
            DockCatLog.app.error("Missing Dock icon image \(name)")
            return
        }
        NSApplication.shared.applicationIconImage = Self.transparentSquareIcon(from: image)
    }

    private static func transparentSquareIcon(from source: NSImage) -> NSImage {
        let side = max(source.size.width, source.size.height)
        guard side > 0 else {
            return source
        }

        let targetSize = NSSize(width: side, height: side)
        let icon = NSImage(size: targetSize)
        icon.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: targetSize).fill()
        let drawRect = NSRect(
            x: (side - source.size.width) / 2,
            y: (side - source.size.height) / 2,
            width: source.size.width,
            height: source.size.height
        )
        source.draw(in: drawRect, from: NSRect(origin: .zero, size: source.size), operation: .sourceOver, fraction: 1)
        icon.unlockFocus()
        return icon
    }
}
