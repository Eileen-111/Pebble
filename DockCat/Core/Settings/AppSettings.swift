import Foundation

struct AppSettings: Codable, Equatable {
    var catName: String
    var catIdentifier: String
    var userSalutation: String
    var selectedAssetPackID: String
    var remindersEnabled: Bool
    var waterReminderInterval: TimeInterval
    var movementReminderInterval: TimeInterval
    var defaultOutingDuration: TimeInterval
    var restDurationMinimum: TimeInterval
    var restDurationMaximum: TimeInterval
    var walkDurationMinimum: TimeInterval
    var walkDurationMaximum: TimeInterval
    var walkBaseSpeed: Double
    var catScalePercent: Double
    var startPositionPercent: Double
    var activityDisplayID: UInt32?
    var activeOutingEndDate: Date?
    var activeOutingDuration: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case catName
        case catIdentifier
        case userSalutation
        case selectedAssetPackID
        case remindersEnabled
        case waterReminderInterval
        case movementReminderInterval
        case defaultOutingDuration
        case restDurationMinimum
        case restDurationMaximum
        case walkDurationMinimum
        case walkDurationMaximum
        case walkBaseSpeed
        case catScalePercent
        case startPositionPercent
        case activityDisplayID
        case activeOutingEndDate
        case activeOutingDuration
    }

    enum LegacyCodingKeys: String, CodingKey {
        case standReminderInterval
    }

    static let defaults = AppSettings(
        catName: "小E",
        catIdentifier: "E",
        userSalutation: "妈妈",
        selectedAssetPackID: "default-pet",
        remindersEnabled: true,
        waterReminderInterval: 30 * 60,
        movementReminderInterval: 60 * 60,
        defaultOutingDuration: 25 * 60,
        restDurationMinimum: 2 * 60,
        restDurationMaximum: 5 * 60,
        walkDurationMinimum: 2 * 60,
        walkDurationMaximum: 5 * 60,
        walkBaseSpeed: 36,
        catScalePercent: 10,
        startPositionPercent: 75,
        activityDisplayID: nil,
        activeOutingEndDate: nil,
        activeOutingDuration: nil
    )

    init(
        catName: String,
        catIdentifier: String,
        userSalutation: String,
        selectedAssetPackID: String,
        remindersEnabled: Bool,
        waterReminderInterval: TimeInterval,
        movementReminderInterval: TimeInterval,
        defaultOutingDuration: TimeInterval,
        restDurationMinimum: TimeInterval,
        restDurationMaximum: TimeInterval,
        walkDurationMinimum: TimeInterval,
        walkDurationMaximum: TimeInterval,
        walkBaseSpeed: Double,
        catScalePercent: Double,
        startPositionPercent: Double,
        activityDisplayID: UInt32?,
        activeOutingEndDate: Date?,
        activeOutingDuration: TimeInterval?
    ) {
        self.catName = catName
        self.catIdentifier = catIdentifier
        self.userSalutation = userSalutation
        self.selectedAssetPackID = selectedAssetPackID
        self.remindersEnabled = remindersEnabled
        self.waterReminderInterval = waterReminderInterval
        self.movementReminderInterval = movementReminderInterval
        self.defaultOutingDuration = defaultOutingDuration
        self.restDurationMinimum = restDurationMinimum
        self.restDurationMaximum = restDurationMaximum
        self.walkDurationMinimum = walkDurationMinimum
        self.walkDurationMaximum = walkDurationMaximum
        self.walkBaseSpeed = walkBaseSpeed
        self.catScalePercent = catScalePercent
        self.startPositionPercent = startPositionPercent
        self.activityDisplayID = activityDisplayID
        self.activeOutingEndDate = activeOutingEndDate
        self.activeOutingDuration = activeOutingDuration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings.defaults
        catName = try container.decodeIfPresent(String.self, forKey: .catName) ?? defaults.catName
        catIdentifier = try container.decodeIfPresent(String.self, forKey: .catIdentifier) ?? defaults.catIdentifier
        userSalutation = try container.decodeIfPresent(String.self, forKey: .userSalutation) ?? defaults.userSalutation
        selectedAssetPackID = try container.decodeIfPresent(String.self, forKey: .selectedAssetPackID) ?? defaults.selectedAssetPackID
        remindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? defaults.remindersEnabled
        waterReminderInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .waterReminderInterval) ?? defaults.waterReminderInterval
        let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
        movementReminderInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .movementReminderInterval)
            ?? legacyContainer.decodeIfPresent(TimeInterval.self, forKey: .standReminderInterval)
            ?? defaults.movementReminderInterval
        defaultOutingDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .defaultOutingDuration) ?? defaults.defaultOutingDuration
        restDurationMinimum = try container.decodeIfPresent(TimeInterval.self, forKey: .restDurationMinimum) ?? defaults.restDurationMinimum
        restDurationMaximum = try container.decodeIfPresent(TimeInterval.self, forKey: .restDurationMaximum) ?? defaults.restDurationMaximum
        walkDurationMinimum = try container.decodeIfPresent(TimeInterval.self, forKey: .walkDurationMinimum) ?? defaults.walkDurationMinimum
        walkDurationMaximum = try container.decodeIfPresent(TimeInterval.self, forKey: .walkDurationMaximum) ?? defaults.walkDurationMaximum
        walkBaseSpeed = try container.decodeIfPresent(Double.self, forKey: .walkBaseSpeed) ?? defaults.walkBaseSpeed
        catScalePercent = try container.decodeIfPresent(Double.self, forKey: .catScalePercent) ?? defaults.catScalePercent
        startPositionPercent = try container.decodeIfPresent(Double.self, forKey: .startPositionPercent) ?? defaults.startPositionPercent
        activityDisplayID = try container.decodeIfPresent(UInt32.self, forKey: .activityDisplayID)
        activeOutingEndDate = try container.decodeIfPresent(Date.self, forKey: .activeOutingEndDate)
        activeOutingDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .activeOutingDuration)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(catName, forKey: .catName)
        try container.encode(catIdentifier, forKey: .catIdentifier)
        try container.encode(userSalutation, forKey: .userSalutation)
        try container.encode(selectedAssetPackID, forKey: .selectedAssetPackID)
        try container.encode(remindersEnabled, forKey: .remindersEnabled)
        try container.encode(waterReminderInterval, forKey: .waterReminderInterval)
        try container.encode(movementReminderInterval, forKey: .movementReminderInterval)
        try container.encode(defaultOutingDuration, forKey: .defaultOutingDuration)
        try container.encode(restDurationMinimum, forKey: .restDurationMinimum)
        try container.encode(restDurationMaximum, forKey: .restDurationMaximum)
        try container.encode(walkDurationMinimum, forKey: .walkDurationMinimum)
        try container.encode(walkDurationMaximum, forKey: .walkDurationMaximum)
        try container.encode(walkBaseSpeed, forKey: .walkBaseSpeed)
        try container.encode(catScalePercent, forKey: .catScalePercent)
        try container.encode(startPositionPercent, forKey: .startPositionPercent)
        try container.encodeIfPresent(activityDisplayID, forKey: .activityDisplayID)
        try container.encodeIfPresent(activeOutingEndDate, forKey: .activeOutingEndDate)
        try container.encodeIfPresent(activeOutingDuration, forKey: .activeOutingDuration)
    }
}
