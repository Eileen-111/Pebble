import Foundation

final class UsageStatisticsStore {
    private let defaults: UserDefaults
    private let key = "DockCat.UsageStatistics.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> UsageStatistics {
        guard let data = defaults.data(forKey: key) else {
            return .defaults
        }
        do {
            return try JSONDecoder().decode(UsageStatistics.self, from: data)
        } catch {
            DockCatLog.app.error("Failed to decode usage statistics: \(error.localizedDescription)")
            return .defaults
        }
    }

    func save(_ statistics: UsageStatistics) {
        do {
            let data = try JSONEncoder().encode(statistics)
            defaults.set(data, forKey: key)
        } catch {
            DockCatLog.app.error("Failed to encode usage statistics: \(error.localizedDescription)")
        }
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}
