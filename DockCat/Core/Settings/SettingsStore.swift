import Foundation

final class SettingsStore {
    private let defaults: UserDefaults
    private let key = "DockCat.AppSettings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: key) else {
            return .defaults
        }
        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            DockCatLog.app.error("Failed to decode settings: \(error.localizedDescription)")
            return .defaults
        }
    }

    func save(_ settings: AppSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: key)
        } catch {
            DockCatLog.app.error("Failed to encode settings: \(error.localizedDescription)")
        }
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}

