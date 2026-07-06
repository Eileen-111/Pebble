import Foundation

enum OutingWakeResolution: Equatable {
    case noActiveOuting
    case reschedule(remaining: TimeInterval, plannedDuration: TimeInterval)
    case returnNow(plannedDuration: TimeInterval)
}

struct OutingWakeResolver {
    func resolution(
        endDate: Date?,
        plannedDuration: TimeInterval?,
        defaultDuration: TimeInterval,
        now: Date = Date()
    ) -> OutingWakeResolution {
        guard let endDate else {
            return .noActiveOuting
        }

        let resolvedDuration = plannedDuration ?? defaultDuration
        let remaining = endDate.timeIntervalSince(now)
        if remaining > 0 {
            return .reschedule(remaining: remaining, plannedDuration: resolvedDuration)
        }
        return .returnNow(plannedDuration: resolvedDuration)
    }
}
