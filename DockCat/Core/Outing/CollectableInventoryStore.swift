import Foundation

final class CollectableInventoryStore {
    private let defaults: UserDefaults
    private let key = "DockCat.CollectableInventory.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> CollectableInventory {
        guard let data = defaults.data(forKey: key) else {
            return .empty
        }
        do {
            return try JSONDecoder().decode(CollectableInventory.self, from: data)
        } catch {
            DockCatLog.app.error("Failed to decode collectable inventory: \(error.localizedDescription)")
            return .empty
        }
    }

    func save(_ inventory: CollectableInventory) {
        do {
            let data = try JSONEncoder().encode(inventory)
            defaults.set(data, forKey: key)
        } catch {
            DockCatLog.app.error("Failed to encode collectable inventory: \(error.localizedDescription)")
        }
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}
