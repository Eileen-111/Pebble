import Foundation

final class SpriteAnimator {
    private var timer: Timer?
    private var frameIndex = 0

    func start(animation: SpriteAnimation, onFrame: @escaping (Int) -> Void, onFinish: (() -> Void)? = nil) {
        stop()
        frameIndex = 0
        guard !animation.frames.isEmpty else { return }
        onFrame(0)
        timer = Timer.scheduledTimer(withTimeInterval: animation.frameDuration, repeats: true) { [weak self] timer in
            guard let self else { return }
            frameIndex += 1
            if frameIndex >= animation.frames.count {
                if animation.loops {
                    frameIndex = 0
                } else {
                    timer.invalidate()
                    onFinish?()
                    return
                }
            }
            onFrame(frameIndex)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        frameIndex = 0
    }
}

