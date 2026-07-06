import Foundation

struct ReminderQueue {
    private(set) var item: ReminderType?

    mutating func enqueue(_ type: ReminderType) {
        item = type == .movement ? .movement : (item ?? type)
    }

    mutating func clear() {
        item = nil
    }
}
