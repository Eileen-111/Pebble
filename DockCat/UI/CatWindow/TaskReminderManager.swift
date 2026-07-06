//
//  TaskReminderManager.swift
//  DockCat
//
//  Created by apricity_peng on 11/5/2026.
//
import AppKit
import SwiftUI

enum TaskStatus: String, Codable {
    case active
    case completed
    case abandoned
    case partial
    case paused
    case interrupted
}
struct TaskRecord: Codable {
    let taskName: String
    let recordedAt: Date
    let status: TaskStatus
    let progress: Double
}
struct TaskItem: Codable {
    
    let id: UUID
    
    var title: String
    
    var createdAt: Date
    
    var estimatedMinutes: Int
    
    var remainingMinutes: Int
    
    var progress: Double
    
    var status: TaskStatus
}
@MainActor
final class TaskReminderManager {
    static let shared = TaskReminderManager()
    private let recordsKey = "task_records"
    
    private var currentTask: TaskItem?
    private var taskTimer: Timer?
    
    private init() {}
    
    private func saveTaskRecord(taskName: String, status: TaskStatus, progress: Double) {
        var records = loadRecords()
        
        records.append(
            TaskRecord(
                taskName: taskName,
                recordedAt: Date(),
                status: status,
                progress: progress
            )
        )
        
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }
        

    func loadRecords() -> [TaskRecord] {
        guard let data = UserDefaults.standard.data(forKey: recordsKey),
              let records = try? JSONDecoder().decode([TaskRecord].self, from: data) else {
            return []
        }
        
        return records
    }
    
    private func startTaskReminder(task: String, minutes: TimeInterval) {
        currentTask = TaskItem(
            id: UUID(),
            title: task,
            createdAt: Date(),
            estimatedMinutes: Int(minutes),
            remainingMinutes: Int(minutes),
            progress: 0,
            status: .active
        )
        taskTimer?.invalidate()
        
        taskTimer = Timer.scheduledTimer(withTimeInterval: minutes * 60, repeats: false) { _ in
            DispatchQueue.main.async {
                self.showTaskCheckDialog()
            }
        }
    }
    
    private func showTaskCheckDialog() {
        guard let task = currentTask else { return }
        
        let alert = NSAlert()
        alert.messageText = "任务进行得怎么样？"
        alert.informativeText = "你刚刚在做「\(task.title)」，现在状态如何？"
        
        alert.addButton(withTitle: "已完成")
        alert.addButton(withTitle: "还需要点时间")
        alert.addButton(withTitle: "完成了一部分")
        alert.addButton(withTitle: "放弃")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            completeTask()
            
        case .alertSecondButtonReturn:
            showExtendTimeDialog()
            
        case .alertThirdButtonReturn:
            showPartialProgressDialog()
            
        default:
            abandonCurrentTask()
        }
    }
    
    private func showExtendTimeDialog() {
        guard let task = currentTask else { return }
        
        let alert = NSAlert()
        alert.messageText = "还需要多久？"
        alert.informativeText = "你可以输入还需要的分钟数，默认 15 分钟。"
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.stringValue = "15"
        input.placeholderString = "15"
        
        alert.accessoryView = input
        
        alert.addButton(withTitle: "继续")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let minutes = Int(input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 15
            
            extendCurrentTask(minutes: minutes)
            showMessage("好，我 \(minutes) 分钟后再来看看「\(task.title)」～")
        }
    }
    
    
    private func showPartialProgressDialog() {
        let alert = NSAlert()
        alert.messageText = "完成了多少？"
        alert.informativeText = "不用必须做完，推进了一部分也值得记录。"
        
        alert.addButton(withTitle: "25%")
        alert.addButton(withTitle: "50%")
        alert.addButton(withTitle: "75%")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            markCurrentTaskPartial(progress: 0.25)
        case .alertSecondButtonReturn:
            markCurrentTaskPartial(progress: 0.5)
        default:
            markCurrentTaskPartial(progress: 0.75)
        }
    }
    
    private func completeTask() {
        guard var task = currentTask else { return }
        
        task.status = .completed
        task.progress = 1.0
        
        saveTaskRecord(
            taskName: task.title,
            status: .completed,
            progress: 1.0
        )
        
        showMessage("太棒了！你完成了「\(task.title)」🎉")
        
        taskTimer?.invalidate()
        taskTimer = nil
        currentTask = nil
    }
    
    func markCurrentTaskPartial(progress: Double) {
        guard var task = currentTask else { return }
        
        task.status = .partial
        task.progress = progress
        currentTask = task
        
        saveTaskRecord(
            taskName: task.title,
            status: .partial,
            progress: progress
        )
        
        taskTimer?.invalidate()
        taskTimer = nil
        
        showMessage("已记录「\(task.title)」完成了 \(Int(progress * 100))%，之后可以继续～")
    }
    

    private func showMessage(_ text: String) {
        let alert = NSAlert()
        alert.messageText = text
        alert.addButton(withTitle: "好")
        alert.runModal()
    }
    func showTodayRecordsDialog() {
        let todayRecords = loadRecords().filter {
            Calendar.current.isDateInToday($0.recordedAt)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let content: String
        
        if todayRecords.isEmpty {
            content = "今天还没有完成任务。"
        } else {
            content = todayRecords.enumerated().map { index, record in
                "\(index + 1). \(formatter.string(from: record.recordedAt)) 完成了「\(record.taskName)」"
            }.joined(separator: "\n")
        }
        
        let alert = NSAlert()
        alert.messageText = "今天完成了 \(todayRecords.count) 项任务"
        alert.informativeText = content
        alert.addButton(withTitle: "好")
        alert.runModal()
    }
    private var taskManagerWindow: NSWindow?

    func showTaskManagerWindow() {
        if let window = taskManagerWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "任务管理"
        window.center()
        window.contentView = NSHostingView(rootView: TaskManagerView())
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)

        taskManagerWindow = window
    }
    
    func currentTaskTitleForDisplay() -> String {
        return currentTask?.title ?? "当前没有任务"
    }

    func startTaskFromManager(task: String, minutes: Int) {
        
        currentTask = TaskItem(
            id: UUID(),
            title: task,
            createdAt: Date(),
            estimatedMinutes: minutes,
            remainingMinutes: minutes,
            progress: 0,
            status: .active
        )
        
        taskTimer?.invalidate()
        
        taskTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(minutes * 60),
            repeats: false
        ) { _ in
            
            Task { @MainActor in
                self.showTaskCheckDialog()
            }
        }
        
        showMessage("开始任务「\(task)」预计 \(minutes) 分钟")
    }

    func completeCurrentTaskFromManager() {
        completeTask()
    }

    func extendCurrentTask(minutes: Int) {
        
        guard let task = currentTask else { return }
        
        taskTimer?.invalidate()
        
        taskTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(minutes * 60),
            repeats: false
        ) { _ in
            
            Task { @MainActor in
                self.showTaskCheckDialog()
            }
        }
        
        showMessage("「\(task.title)」延长了 \(minutes) 分钟")
    }

    func switchTaskFromManager(newTask: String, minutes: Int) {
        
        if let oldTask = currentTask {
            saveTaskRecord(
                taskName: oldTask.title,
                status: .interrupted,
                progress: oldTask.progress
            )
        }
        
        currentTask = TaskItem(
            id: UUID(),
            title: newTask,
            createdAt: Date(),
            estimatedMinutes: minutes,
            remainingMinutes: minutes,
            progress: 0,
            status: .active
        )
        
        taskTimer?.invalidate()
        
        taskTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(minutes * 60),
            repeats: false
        ) { _ in
            
            Task { @MainActor in
                self.showTaskCheckDialog()
            }
        }
        
        showMessage("切换到新任务「\(newTask)」")
    }

    func abandonCurrentTask() {
        guard let task = currentTask else { return }
        
        saveTaskRecord(
            taskName: task.title,
            status: .abandoned,
            progress: task.progress
        )
        
        taskTimer?.invalidate()
        taskTimer = nil
        currentTask = nil
        
        showMessage("已放弃任务「\(task.title)」。没关系，先照顾好自己。")
    }
    
    func hasCurrentTask() -> Bool {
        return currentTask != nil
    }
    
}
