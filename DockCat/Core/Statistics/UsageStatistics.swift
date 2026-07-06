import Foundation

struct UsageStatistics: Codable, Equatable {
    var totalLitScreenUsageSeconds: TimeInterval
    var completedWaterReminderCount: Int
    var completedMovementReminderCount: Int
    var outingEventCount: Int
    var outingCollectableCount: Int

    enum CodingKeys: String, CodingKey {
        case totalLitScreenUsageSeconds
        case completedWaterReminderCount
        case completedMovementReminderCount
        case outingEventCount
        case outingCollectableCount
    }

    enum LegacyCodingKeys: String, CodingKey {
        case completedStandReminderCount
    }

    static let defaults = UsageStatistics(
        totalLitScreenUsageSeconds: 0,
        completedWaterReminderCount: 0,
        completedMovementReminderCount: 0,
        outingEventCount: 0,
        outingCollectableCount: 0
    )

    var litScreenUsageHoursText: String {
        String(format: "%.1f", max(0, totalLitScreenUsageSeconds) / 3600)
    }

    init(
        totalLitScreenUsageSeconds: TimeInterval,
        completedWaterReminderCount: Int,
        completedMovementReminderCount: Int,
        outingEventCount: Int = 0,
        outingCollectableCount: Int = 0
    ) {
        self.totalLitScreenUsageSeconds = totalLitScreenUsageSeconds
        self.completedWaterReminderCount = completedWaterReminderCount
        self.completedMovementReminderCount = completedMovementReminderCount
        self.outingEventCount = outingEventCount
        self.outingCollectableCount = outingCollectableCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
        let defaults = UsageStatistics.defaults
        totalLitScreenUsageSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .totalLitScreenUsageSeconds) ?? defaults.totalLitScreenUsageSeconds
        completedWaterReminderCount = try container.decodeIfPresent(Int.self, forKey: .completedWaterReminderCount) ?? defaults.completedWaterReminderCount
        completedMovementReminderCount = try container.decodeIfPresent(Int.self, forKey: .completedMovementReminderCount)
            ?? legacyContainer.decodeIfPresent(Int.self, forKey: .completedStandReminderCount)
            ?? defaults.completedMovementReminderCount
        outingEventCount = try container.decodeIfPresent(Int.self, forKey: .outingEventCount) ?? defaults.outingEventCount
        outingCollectableCount = try container.decodeIfPresent(Int.self, forKey: .outingCollectableCount) ?? defaults.outingCollectableCount
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalLitScreenUsageSeconds, forKey: .totalLitScreenUsageSeconds)
        try container.encode(completedWaterReminderCount, forKey: .completedWaterReminderCount)
        try container.encode(completedMovementReminderCount, forKey: .completedMovementReminderCount)
        try container.encode(outingEventCount, forKey: .outingEventCount)
        try container.encode(outingCollectableCount, forKey: .outingCollectableCount)
    }

    mutating func recordCompletedReminder(_ type: ReminderType) {
        switch type {
        case .water:
            completedWaterReminderCount += 1
        case .movement:
            completedMovementReminderCount += 1
        }
    }

    mutating func recordOutingEvent() {
        outingEventCount += 1
    }

    mutating func recordOutingCollectable() {
        outingCollectableCount += 1
    }
}
