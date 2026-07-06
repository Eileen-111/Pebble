import AppKit
import Foundation

final class OutingCatalogLoader {
    private let bundle: Bundle
    private let fileManager: FileManager
    private let explicitRootURL: URL?

    init(bundle: Bundle = .main, fileManager: FileManager = .default, rootURL: URL? = nil) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.explicitRootURL = rootURL
    }

    func loadCatalog() -> OutingCatalog {
        guard let rootURL = outingRootURL() else {
            DockCatLog.app.error("Missing Outing resource root")
            return .empty
        }

        let collectables = loadCollectables(rootURL: rootURL)
        let events = loadEvents(rootURL: rootURL)
        return OutingCatalog(collectables: collectables, events: events, resourceRootURL: rootURL)
    }

    private func loadCollectables(rootURL: URL) -> [OutingCollectable] {
        let url = rootURL.appendingPathComponent("collectables.json")
        guard let items = decode([OutingCollectable].self, from: url) else { return [] }
        return items.filter { item in
            guard !item.id.isEmpty,
                  !item.chineseName.isEmpty,
                  !item.englishName.isEmpty,
                  !item.author.isEmpty,
                  (1 ... 5).contains(item.rarity)
            else {
                return false
            }
            let imageURL = rootURL.appendingPathComponent(item.imagePath)
            return fileManager.fileExists(atPath: imageURL.path) && NSImage(contentsOf: imageURL) != nil
        }
    }

    private func loadEvents(rootURL: URL) -> [OutingEvent] {
        let url = rootURL.appendingPathComponent("events.json")
        guard let events = decode([OutingEvent].self, from: url) else { return [] }
        return events.filter { event in
            !event.id.isEmpty
                && !event.eventType.isEmpty
                && !event.chineseDescription.isEmpty
                && !event.englishDescription.isEmpty
                && !event.author.isEmpty
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            DockCatLog.app.error("Failed to load outing catalog \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    private func outingRootURL() -> URL? {
        if let explicitRootURL {
            return explicitRootURL
        }

        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/Outing", isDirectory: true)

        return [
            bundle.resourceURL?.appendingPathComponent("Outing", isDirectory: true),
            bundle.resourceURL?.appendingPathComponent("Resources/Outing", isDirectory: true),
            sourceRoot
        ]
        .compactMap { $0 }
        .first { fileManager.fileExists(atPath: $0.path) }
    }
}
