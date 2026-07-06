import AppKit

@MainActor
final class CatMenuController {
    var onPet: (() -> Void)?
    var onOuting: (() -> Void)?
    var onSettings: (() -> Void)?
    var onSleep: (() -> Void)?

    func show(snapshot: CatStatusSnapshot, at event: NSEvent, in view: NSView) {
        let menu = NSMenu()
        menu.addItem(CatStatusMenuPresenter.statusItem(snapshot: snapshot))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "摸摸 (改变姿势)", action: #selector(pet), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "出门玩吧 (专注模式)", action: #selector(outing), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "任务管理", action: #selector(taskManager), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "设置", action: #selector(settings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "去睡觉吧 (退出应用)", action: #selector(sleep), keyEquivalent: "q"))
        for item in menu.items {
            item.target = self
        }
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }

    @objc private func pet() {
        onPet?()
    }

    @objc private func outing() {
        onOuting?()
    }

    @objc private func settings() {
        onSettings?()
    }

    @objc private func sleep() {
        onSleep?()
    }
    @objc func taskManager() {
        Task {
            await MainActor.run {
                TaskReminderManager.shared.showTaskManagerWindow()
            }
        }
    }
}
