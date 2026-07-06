import Foundation

struct CollectableInventoryEntry: Codable, Equatable {
    var collectableID: String
    var count: Int
    var firstAcquiredAt: Date
    var lastAcquiredAt: Date
}

struct CollectableInventory: Codable, Equatable {
    var entries: [String: CollectableInventoryEntry]
    var recentNewCollectableID: String?

    static let empty = CollectableInventory(entries: [:], recentNewCollectableID: nil)

    var acquiredEntries: [CollectableInventoryEntry] {
        entries.values.sorted {
            if $0.lastAcquiredAt == $1.lastAcquiredAt {
                return $0.collectableID < $1.collectableID
            }
            return $0.lastAcquiredAt > $1.lastAcquiredAt
        }
    }

    mutating func recordCollectable(_ collectableID: String, at date: Date = Date()) -> Bool {
        if var entry = entries[collectableID] {
            entry.count += 1
            entry.lastAcquiredAt = date
            entries[collectableID] = entry
            recentNewCollectableID = nil
            return false
        }

        entries[collectableID] = CollectableInventoryEntry(
            collectableID: collectableID,
            count: 1,
            firstAcquiredAt: date,
            lastAcquiredAt: date
        )
        recentNewCollectableID = collectableID
        return true
    }

    mutating func clearRecentNewMarker() {
        recentNewCollectableID = nil
    }
}
