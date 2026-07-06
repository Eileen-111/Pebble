import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let store: SettingsStore
    private var settings: AppSettings
    private var usageStatistics: UsageStatistics
    private let outingCatalog: OutingCatalog
    private var collectableInventory: CollectableInventory
    private var dialogueImage: NSImage?
    var onSave: ((AppSettings) -> Void)?
    var assetPackIDsProvider: () -> [String] = { [] }
    var onOpenAssetPacksFolder: () -> Void = {}
    var onLoadAssetPack: (String) -> AssetPackPreviewResult = { id in
        AssetPackPreviewResult(
            report: AssetPackValidationReport(
                requestedID: id,
                pack: nil,
                errorDescription: "资源包加载器尚未准备好。",
                poseStatuses: [],
                walkFrameCount: 0,
                hasValidSleepIcon: false,
                hasValidEmptyIcon: false
            ),
            dialogueImage: nil
        )
    }

    init(
        store: SettingsStore,
        settings: AppSettings,
        usageStatistics: UsageStatistics,
        outingCatalog: OutingCatalog,
        collectableInventory: CollectableInventory,
        dialogueImage: NSImage?
    ) {
        self.store = store
        self.settings = settings
        self.usageStatistics = usageStatistics
        self.outingCatalog = outingCatalog
        self.collectableInventory = collectableInventory
        self.dialogueImage = dialogueImage
        super.init()
    }

    func update(settings: AppSettings) {
        self.settings = settings
    }

    func update(usageStatistics: UsageStatistics) {
        self.usageStatistics = usageStatistics
    }

    func update(collectableInventory: CollectableInventory) {
        self.collectableInventory = collectableInventory
    }

    func update(dialogueImage: NSImage?) {
        self.dialogueImage = dialogueImage
    }

    func show() {
        if let window {
            if let hosting = window.contentViewController as? NSHostingController<SettingsView> {
                hosting.rootView = makeSettingsView()
            }
            centerOnActiveScreen(window)
            bringToFront(window)
            return
        }
        let view = makeSettingsView()
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Pebble 设置"
        window.setContentSize(NSSize(width: 520, height: 580))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        self.window = window
        centerOnActiveScreen(window)
        bringToFront(window)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }

    private func makeSettingsView() -> SettingsView {
        SettingsView(
            settings: settings,
            usageStatistics: usageStatistics,
            outingCatalog: outingCatalog,
            collectableInventory: collectableInventory,
            dialogueImage: dialogueImage,
            availableAssetPackIDs: assetPackIDsProvider(),
            onOpenAssetPacksFolder: onOpenAssetPacksFolder,
            onReloadAssetPackIDs: assetPackIDsProvider,
            onLoadAssetPack: onLoadAssetPack
        ) { [weak self] updated in
            guard let self else { return }
            self.settings = updated
            self.store.save(updated)
            self.onSave?(updated)
            self.window?.close()
        }
    }

    private func bringToFront(_ window: NSWindow) {
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func centerOnActiveScreen(_ window: NSWindow) {
        guard let screen = DockGeometry.currentActivityScreen(activityDisplayID: settings.activityDisplayID) ?? window.screen else {
            window.center()
            return
        }
        let visibleFrame = screen.visibleFrame
        let windowSize = window.frame.size
        window.setFrameOrigin(NSPoint(
            x: visibleFrame.midX - windowSize.width / 2,
            y: visibleFrame.midY - windowSize.height / 2
        ))
    }
}
