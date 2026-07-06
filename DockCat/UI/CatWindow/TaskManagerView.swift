//
//  TaskManagerView.swift
//  DockCat
//
//  Created by apricity_peng on 14/5/2026.
//
import SwiftUI

struct TaskManagerView: View {
    @State private var taskName: String = ""
    @State private var estimatedMinutes: String = "60"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("任务管理")
                .font(.title2)
                .bold()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 14) {

                Text("开始新任务")
                    .font(.headline)

                TextField("你现在想推进什么？", text: $taskName)

                TextField("预计需要多少分钟？", text: $estimatedMinutes)

                VStack(alignment: .leading, spacing: 8) {

                    Text("🐱 不知道怎么开始？")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("帮我拆成第一步") {
                        print("AI BUTTON CLICKED")
                        
                        Task {
                            let suggestion = await AIStartHelper.shared.generateMicroTask(from: taskName)
                            
                            let alert = NSAlert()
                            alert.messageText = "先从这一步开始"
                            alert.informativeText = """
                            \(suggestion.microTask)

                            \(suggestion.encouragement)
                            """
                            
                            alert.addButton(withTitle: "用这个开始")
                            alert.addButton(withTitle: "取消")
                            
                            let response = alert.runModal()
                            
                            if response == .alertFirstButtonReturn {
                                taskName = suggestion.microTask
                                estimatedMinutes = "\(suggestion.minutes)"
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                Button(
                    TaskReminderManager.shared.hasCurrentTask()
                    ? "切换到这个任务"
                    : "开始任务"
                ) {

                    let minutes = Int(estimatedMinutes) ?? 60

                    if TaskReminderManager.shared.hasCurrentTask() {

                        TaskReminderManager.shared.switchTaskFromManager(
                            newTask: taskName,
                            minutes: minutes
                        )

                    } else {

                        TaskReminderManager.shared.startTaskFromManager(
                            task: taskName,
                            minutes: minutes
                        )
                    }

                    taskName = ""
                    estimatedMinutes = "60"
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("当前任务")
                    .font(.headline)
                
                Text(TaskReminderManager.shared.currentTaskTitleForDisplay())
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("提前完成") {
                        TaskReminderManager.shared.completeCurrentTaskFromManager()
                    }
                    
                   
                }
                
                HStack {
                    
                    Button("放弃任务") {
                        TaskReminderManager.shared.abandonCurrentTask()
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                
                Text("今日记录")
                    .font(.headline)
                
                let records = TaskReminderManager.shared.loadRecords().filter {
                    Calendar.current.isDateInToday($0.recordedAt)
                }
                
                if records.isEmpty {
                    
                    Text("今天还没有完成任务")
                        .foregroundColor(.secondary)
                    
                } else {
                    
                    ForEach(records, id: \.recordedAt) { record in
                        
                        HStack {
                            
                            Text(formatTime(record.recordedAt))
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)
                            
                            Text("\(record.taskName) · \(statusText(record.status, progress: record.progress))")
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 420, height: 520)
    }
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func statusText(_ status: TaskStatus, progress: Double) -> String {
        switch status {
        case .completed:
            return "已完成"
        case .abandoned:
            return "已放弃"
        case .partial:
            return "完成 \(Int(progress * 100))%"
        case .paused:
            return "已暂停"
        case .active:
            return "进行中"
        case .interrupted:
            return "已中断"
        }
    }
    
}
