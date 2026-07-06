import AppKit

@MainActor
final class DockMenuController: NSObject {
    var stateProvider: (() -> CatState)?
    var statusProvider: (() -> CatStatusSnapshot?)?
    var settingsProvider: (() -> AppSettings)?
    var onPet: (() -> Void)?
    var onOuting: (() -> Void)?
    var onRecall: (() -> Void)?
    var onSettings: (() -> Void)?
    var onSleep: (() -> Void)?

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let state = stateProvider?()
        if let snapshot = statusProvider?() {
            menu.addItem(CatStatusMenuPresenter.statusItem(snapshot: snapshot))
            menu.addItem(NSMenuItem.separator())
        }
        if case .outing(.away) = state {
            let settings = settingsProvider?() ?? .defaults
            menu.addItem(item("召回\(settings.catName)", #selector(recall)))
        } else {
            menu.addItem(item("摸摸 (改变姿势)", #selector(pet)))
            menu.addItem(item("出门玩吧 (专注模式)", #selector(outing)))
        }
        menu.addItem(item("任务管理", #selector(taskManager)))
        menu.addItem(item("设置", #selector(settings)))
        menu.addItem(item("去睡觉吧 (退出应用)", #selector(sleep)))
        return menu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func pet() {
        onPet?()
    }

    @objc private func outing() {
        onOuting?()
    }

    @objc private func recall() {
        onRecall?()
    }

    @objc private func settings() {
        onSettings?()
    }

    @objc private func sleep() {
        onSleep?()
    }
    @objc private func taskManager() {
        Task {
            await MainActor.run {
                TaskReminderManager.shared.showTaskManagerWindow()
            }
        }
    }
}
