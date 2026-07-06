import Foundation

final class UsageSessionTracker {
    private var statistics: UsageStatistics
    private let now: () -> Date
    private let onChange: (UsageStatistics) -> Void
    private var activeStartDate: Date?

    init(
        statistics: UsageStatistics,
        now: @escaping () -> Date = Date.init,
        onChange: @escaping (UsageStatistics) -> Void
    ) {
        self.statistics = statistics
        self.now = now
        self.onChange = onChange
    }

    var snapshot: UsageStatistics {
        var current = statistics
        guard let activeStartDate else { return current }
        current.totalLitScreenUsageSeconds += max(0, now().timeIntervalSince(activeStartDate))
        return current
    }

    func start() {
        resume()
    }

    func screenDidSleep() {
        pause()
    }

    func screenDidWake() {
        resume()
    }

    func stop() {
        pause()
    }

    func recordCompletedReminder(_ type: ReminderType) {
        settleActiveInterval()
        statistics.recordCompletedReminder(type)
        onChange(statistics)
    }

    func recordOutingEvent() {
        settleActiveInterval()
        statistics.recordOutingEvent()
        onChange(statistics)
    }

    func recordOutingCollectable() {
        settleActiveInterval()
        statistics.recordOutingCollectable()
        onChange(statistics)
    }

    private func resume() {
        guard activeStartDate == nil else { return }
        activeStartDate = now()
    }

    private func pause() {
        guard activeStartDate != nil else { return }
        settleActiveInterval()
        activeStartDate = nil
        onChange(statistics)
    }

    private func settleActiveInterval() {
        guard let activeStartDate else { return }
        let current = now()
        statistics.totalLitScreenUsageSeconds += max(0, current.timeIntervalSince(activeStartDate))
        self.activeStartDate = current
    }
}
