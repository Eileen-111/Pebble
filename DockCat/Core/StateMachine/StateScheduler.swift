import Foundation

final class StateScheduler {
    private var timer: Timer?

    func schedule(after interval: TimeInterval, action: @escaping () -> Void) {
        cancel()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            action()
        }
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}

