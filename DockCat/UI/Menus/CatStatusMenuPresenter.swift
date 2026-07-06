import AppKit
import Foundation

struct CatStatusSnapshot {
    var state: CatState
    var stateEndDate: Date?
    var outingEndDate: Date?
}

enum CatStatusMenuPresenter {
    static func statusItem(snapshot: CatStatusSnapshot, now: Date = Date()) -> NSMenuItem {
        let title = "\(stateTitle(snapshot.state))：剩余\(remainingText(snapshot: snapshot, now: now))"
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private static func remainingText(snapshot: CatStatusSnapshot, now: Date) -> String {
        if case .transitioning = snapshot.state {
            return "--"
        }
        let endDate: Date?
        if case .outing = snapshot.state {
            endDate = snapshot.outingEndDate
        } else {
            endDate = snapshot.stateEndDate
        }
        guard let endDate else { return "--" }
        return TimeFormatter.menuRemaining(endDate.timeIntervalSince(now))
    }

    private static func stateTitle(_ state: CatState) -> String {
        switch state {
        case .transitioning:
            return "过渡"
        case .walking:
            return "散步"
        case .resting:
            return "休息"
        case .dragged:
            return "被抱起"
        case .dialogue:
            return "对话"
        case .outing:
            return "出门"
        }
    }
}
