import AppKit
import Foundation

struct AppIconSource: Equatable {
    var sleepURL: URL
    var emptyURL: URL
    var usesCustomIcons: Bool
}

final class AppIconStore {
    typealias BundledIconSourceProvider = () -> AppIconSource?

    private let fileManager: FileManager
    private let applicationSupportURL: URL
    private let bundledIconSourceProvider: BundledIconSourceProvider

    init(
        fileManager: FileManager = .default,
        bundle: Bundle = .main,
        applicationSupportURL: URL? = nil,
        bundledIconSourceProvider: BundledIconSourceProvider? = nil
    ) {
        self.fileManager = fileManager
        self.applicationSupportURL = applicationSupportURL
            ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        self.bundledIconSourceProvider = bundledIconSourceProvider ?? {
            Self.bundledIconSource(bundle: bundle)
        }
    }

    var cachedIconDirectoryURL: URL {
        applicationSupportURL
            .appendingPathComponent("DockCat", isDirectory: true)
            .appendingPathComponent("AppIcon", isDirectory: true)
    }

    func prepareActiveIconSource(selectedPack: CatAssetPack) -> AppIconSource? {
        if let cachedCustomSource = cacheCustomIcons(from: selectedPack) {
            return cachedCustomSource
        }
        if let cachedSource = cachedIconSource() {
            return cachedSource
        }
        return bundledIconSourceProvider()
    }

    func cachedIconSource() -> AppIconSource? {
        let source = AppIconSource(
            sleepURL: cachedIconDirectoryURL.appendingPathComponent("icon_sleep.png"),
            emptyURL: cachedIconDirectoryURL.appendingPathComponent("icon_empty.png"),
            usesCustomIcons: true
        )
        guard isLoadableImage(at: source.sleepURL), isLoadableImage(at: source.emptyURL) else {
            return nil
        }
        return source
    }

    private func cacheCustomIcons(from pack: CatAssetPack) -> AppIconSource? {
        guard
            let sleepURL = pack.sleepIconURL,
            let emptyURL = pack.emptyIconURL,
            isLoadableImage(at: sleepURL),
            isLoadableImage(at: emptyURL)
        else {
            return nil
        }

        let cachedSleepURL = cachedIconDirectoryURL.appendingPathComponent("icon_sleep.png")
        let cachedEmptyURL = cachedIconDirectoryURL.appendingPathComponent("icon_empty.png")

        do {
            try fileManager.createDirectory(at: cachedIconDirectoryURL, withIntermediateDirectories: true)
            try copyReplacingItem(at: sleepURL, to: cachedSleepURL)
            try copyReplacingItem(at: emptyURL, to: cachedEmptyURL)
        } catch {
            DockCatLog.app.error("Failed to cache custom app icons: \(error.localizedDescription)")
            return nil
        }

        return cachedIconSource()
    }

    private func copyReplacingItem(at sourceURL: URL, to destinationURL: URL) throws {
        if sourceURL.standardizedFileURL == destinationURL.standardizedFileURL {
            return
        }
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }

    private func isLoadableImage(at url: URL) -> Bool {
        NSImage(contentsOf: url) != nil
    }

    private static func bundledIconSource(bundle: Bundle) -> AppIconSource? {
        guard
            let sleepURL = bundledIconURL(named: "icon_sleep", bundle: bundle),
            let emptyURL = bundledIconURL(named: "icon_empty", bundle: bundle)
        else {
            return nil
        }
        return AppIconSource(sleepURL: sleepURL, emptyURL: emptyURL, usesCustomIcons: false)
    }

    private static func bundledIconURL(named name: String, bundle: Bundle) -> URL? {
        [
            bundle.url(forResource: name, withExtension: "png"),
            bundle.url(forResource: name, withExtension: "png", subdirectory: "AppIcon"),
            bundle.url(forResource: name, withExtension: "png", subdirectory: "Resources/AppIcon")
        ].compactMap { $0 }.first
    }
}
