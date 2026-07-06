import Foundation

final class ReminderScheduler {
    private(set) var settings: AppSettings
    private let now: () -> Date
    private(set) var pendingReminder: ReminderType?
    private var nextWaterDue: Date?
    private var nextMovementDue: Date?

    init(settings: AppSettings, now: @escaping () -> Date = Date.init) {
        self.settings = settings
        self.now = now
        if settings.remindersEnabled {
            resetTimers(from: now())
        }
    }

    func updateSettings(_ settings: AppSettings) {
        let previousSettings = self.settings
        let wasEnabled = self.settings.remindersEnabled
        self.settings = settings
        if !settings.remindersEnabled {
            clear()
        } else if !wasEnabled {
            resetTimers(from: now())
        } else {
            let current = now()
            if previousSettings.waterReminderInterval != settings.waterReminderInterval {
                nextWaterDue = current.addingTimeInterval(settings.waterReminderInterval)
            }
            if previousSettings.movementReminderInterval != settings.movementReminderInterval {
                nextMovementDue = current.addingTimeInterval(settings.movementReminderInterval)
            }
        }
    }

    func dueReminder(whenCatInLongDurationState isLongDuration: Bool) -> ReminderType? {
        guard settings.remindersEnabled else { return nil }
        if let pendingReminder {
            return isLongDuration ? pendingReminder : nil
        }

        let current = now()
        let waterDue = nextWaterDue.map { $0 <= current } ?? false
        let movementDue = nextMovementDue.map { $0 <= current } ?? false

        let due: ReminderType?
        if movementDue {
            due = .movement
        } else if waterDue {
            due = .water
        } else {
            due = nil
        }

        guard let due else { return nil }
        if isLongDuration {
            pendingReminder = due
            return due
        }
        pendingReminder = due
        return nil
    }

    func complete(_ type: ReminderType) {
        pendingReminder = nil
        let current = now()
        switch type {
        case .water:
            nextWaterDue = current.addingTimeInterval(settings.waterReminderInterval)
        case .movement:
            nextMovementDue = current.addingTimeInterval(settings.movementReminderInterval)
            nextWaterDue = current.addingTimeInterval(settings.waterReminderInterval)
        }
    }

    func snooze(_ type: ReminderType, interval: TimeInterval = 5 * 60) {
        pendingReminder = nil
        let due = now().addingTimeInterval(interval)
        switch type {
        case .water:
            nextWaterDue = due
        case .movement:
            nextMovementDue = due
            if nextWaterDue.map({ $0 <= due }) ?? false {
                nextWaterDue = due
            }
        }
    }

    func clear() {
        pendingReminder = nil
        nextWaterDue = nil
        nextMovementDue = nil
    }

    private func resetTimers(from date: Date) {
        pendingReminder = nil
        nextWaterDue = date.addingTimeInterval(settings.waterReminderInterval)
        nextMovementDue = date.addingTimeInterval(settings.movementReminderInterval)
    }
}
