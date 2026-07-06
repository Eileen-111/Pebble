import Foundation

struct UserDataBackupSnapshot: Codable, Equatable {
    var schemaVersion: Int
    var generatedAt: Date
    var appVersion: String
    var bundleIdentifier: String
    var settings: UserDataBackupSettings
    var usageStatistics: UsageStatistics
    var collectableInventory: UserDataBackupCollectableInventory

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case generatedAt
        case appVersion
        case bundleIdentifier
        case settings
        case usageStatistics
        case collectableInventory
    }
}

struct UserDataBackupSettings: Codable, Equatable {
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

    init(settings: AppSettings) {
        catName = settings.catName
        catIdentifier = settings.catIdentifier
        userSalutation = settings.userSalutation
        selectedAssetPackID = settings.selectedAssetPackID
        remindersEnabled = settings.remindersEnabled
        waterReminderInterval = settings.waterReminderInterval
        movementReminderInterval = settings.movementReminderInterval
        defaultOutingDuration = settings.defaultOutingDuration
        restDurationMinimum = settings.restDurationMinimum
        restDurationMaximum = settings.restDurationMaximum
        walkDurationMinimum = settings.walkDurationMinimum
        walkDurationMaximum = settings.walkDurationMaximum
        walkBaseSpeed = settings.walkBaseSpeed
        catScalePercent = settings.catScalePercent
        startPositionPercent = settings.startPositionPercent
        activityDisplayID = settings.activityDisplayID
    }
}

struct UserDataBackupCollectableInventory: Codable, Equatable {
    var entries: [String: UserDataBackupCollectableInventoryEntry]
    var recentNewCollectableID: String?

    init(inventory: CollectableInventory) {
        entries = inventory.entries.mapValues { entry in
            UserDataBackupCollectableInventoryEntry(entry: entry)
        }
        recentNewCollectableID = inventory.recentNewCollectableID
    }
}

struct UserDataBackupCollectableInventoryEntry: Codable, Equatable {
    var collectableID: String
    var lastAcquiredAt: Date

    init(entry: CollectableInventoryEntry) {
        collectableID = entry.collectableID
        lastAcquiredAt = entry.lastAcquiredAt
    }
}

final class UserDataBackupStore {
    private let fileManager: FileManager
    private let applicationSupportURL: URL
    private let appVersionProvider: () -> String
    private let bundleIdentifierProvider: () -> String
    private let now: () -> Date

    init(
        fileManager: FileManager = .default,
        applicationSupportURL: URL? = nil,
        bundle: Bundle = .main,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.applicationSupportURL = applicationSupportURL
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        appVersionProvider = {
            bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        }
        bundleIdentifierProvider = {
            bundle.bundleIdentifier ?? "com.tianmaizhang.DockCat"
        }
        self.now = now
    }

    var backupDirectoryURL: URL {
        applicationSupportURL
            .appendingPathComponent("DockCat", isDirectory: true)
            .appendingPathComponent("DataBackup", isDirectory: true)
    }

    var backupFileURL: URL {
        backupDirectoryURL.appendingPathComponent("user-data-backup.json")
    }

    func save(
        settings: AppSettings,
        usageStatistics: UsageStatistics,
        collectableInventory: CollectableInventory
    ) {
        let snapshot = UserDataBackupSnapshot(
            schemaVersion: 1,
            generatedAt: now(),
            appVersion: appVersionProvider(),
            bundleIdentifier: bundleIdentifierProvider(),
            settings: UserDataBackupSettings(settings: settings),
            usageStatistics: usageStatistics,
            collectableInventory: UserDataBackupCollectableInventory(inventory: collectableInventory)
        )

        do {
            try fileManager.createDirectory(at: backupDirectoryURL, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted]
            let data = try encoder.encode(snapshot)
            try data.write(to: backupFileURL, options: .atomic)
        } catch {
            DockCatLog.app.error("Failed to write user data backup: \(error.localizedDescription)")
        }
    }
}
