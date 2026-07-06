import AppKit

struct SpriteAnimation {
    var frames: [NSImage]
    var fps: Double
    var loops: Bool

    var frameDuration: TimeInterval {
        guard fps > 0 else { return 1.0 / 6.0 }
        return 1.0 / fps
    }
}

