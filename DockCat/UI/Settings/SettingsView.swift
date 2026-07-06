import AppKit
import SwiftUI

struct AssetPackPreviewResult {
    var report: AssetPackValidationReport
    var dialogueImage: NSImage?
}

struct AssetPackComboBox: NSViewRepresentable {
    @Binding var text: String
    var items: [String]

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.usesDataSource = true
        comboBox.completes = true
        comboBox.dataSource = context.coordinator
        comboBox.delegate = context.coordinator
        comboBox.isEditable = true
        comboBox.numberOfVisibleItems = 8
        comboBox.controlSize = .regular
        return comboBox
    }

    func updateNSView(_ comboBox: NSComboBox, context: Context) {
        context.coordinator.parent = self
        comboBox.reloadData()
        if comboBox.stringValue != text {
            comboBox.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSComboBoxDataSource, NSComboBoxDelegate {
        var parent: AssetPackComboBox

        init(parent: AssetPackComboBox) {
            self.parent = parent
        }

        func numberOfItems(in comboBox: NSComboBox) -> Int {
            parent.items.count
        }

        func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
            guard parent.items.indices.contains(index) else { return nil }
            return parent.items[index]
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else { return }
            let selectedIndex = comboBox.indexOfSelectedItem
            if parent.items.indices.contains(selectedIndex) {
                parent.text = parent.items[selectedIndex]
                comboBox.stringValue = parent.items[selectedIndex]
            } else {
                parent.text = comboBox.stringValue
            }
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else { return }
            parent.text = comboBox.stringValue
        }
    }
}

struct SettingsView: View {
    @State private var draft: AppSettings
    @State private var availableAssetPackIDs: [String]
    @State private var displayOptions: [DisplaySelectionOption]
    @State private var previewImage: NSImage?
    @State private var geminiAPIKey: String =
        UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
    private let usageStatistics: UsageStatistics
    private let outingCatalog: OutingCatalog
    private let collectableInventory: CollectableInventory
    private let labelWidth: CGFloat = 112
    private let controlWidth: CGFloat = 196
    private let displayControlWidth: CGFloat = 240
    private let rowSpacing: CGFloat = 6
    private let panelWidth: CGFloat = 420
    private var assetInputWidth: CGFloat { controlWidth }
    private var rowWidth: CGFloat { labelWidth + rowSpacing + controlWidth }
    private let onOpenAssetPacksFolder: () -> Void
    private let onReloadAssetPackIDs: () -> [String]
    private let onLoadAssetPack: (String) -> AssetPackPreviewResult
    var onSave: (AppSettings) -> Void

    init(
        settings: AppSettings,
        usageStatistics: UsageStatistics,
        outingCatalog: OutingCatalog,
        collectableInventory: CollectableInventory,
        dialogueImage: NSImage?,
        availableAssetPackIDs: [String],
        onOpenAssetPacksFolder: @escaping () -> Void,
        onReloadAssetPackIDs: @escaping () -> [String],
        onLoadAssetPack: @escaping (String) -> AssetPackPreviewResult,
        onSave: @escaping (AppSettings) -> Void
    ) {
        _draft = State(initialValue: settings)
        _availableAssetPackIDs = State(initialValue: availableAssetPackIDs)
        _displayOptions = State(initialValue: DockGeometry.currentDisplaySelectionOptions())
        _previewImage = State(initialValue: dialogueImage)
        self.usageStatistics = usageStatistics
        self.outingCatalog = outingCatalog
        self.collectableInventory = collectableInventory
        self.onOpenAssetPacksFolder = onOpenAssetPacksFolder
        self.onReloadAssetPackIDs = onReloadAssetPackIDs
        self.onLoadAssetPack = onLoadAssetPack
        self.onSave = onSave
    }
  
    struct TodayRecordsView: View {
        
        @State private var records: [TaskRecord] = []
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                
                Text("今日记录")
                    .font(.title2)
                    .bold()
                
                Text("今天完成了 \(records.count) 项任务")
                    .font(.headline)
                
                Divider()
                
                if records.isEmpty {
                    
                    Spacer()
                    
                    Text("今天还没有完成任务")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                } else {
                    
                    List(records, id: \.recordedAt) { record in
                        
                        HStack {
                            
                            Text(formatTime(record.recordedAt))
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)
                            
                            Text("\(record.taskName) · \(record.status.rawValue) · \(Int(record.progress * 100))%")
                        }
                    }
                }
            }
            .padding()
            .onAppear {
                loadTodayRecords()
            }
        }
        
        private func loadTodayRecords() {
            records = TaskReminderManager.shared.loadRecords().filter {
                Calendar.current.isDateInToday($0.recordedAt)
            }
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                petTab
                    .tabItem { Text("猫咪设置") }

                parametersTab
                    .tabItem { Text("参数设置") }

                collectablesTab
                    .tabItem { Text("收藏品箱") }

                TodayRecordsView()
                    .tabItem { Text("今日记录") }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)

            Divider()

            HStack {
                Spacer()
                Button("保存") {
                    onSave(normalized(draft))
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
        .frame(width: 520, height: 580)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var petTab: some View {
        VStack(spacing: 10) {
            petImage
                .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    compactTextField("猫咪名字", text: $draft.catName)
                    compactTextField("对你的称呼", text: $draft.userSalutation)
                    assetPackRow
                    assetPackActionsRow
                    compactStepper("缩放", value: scaleBinding, range: 1...100, step: 1, suffix: "%")
                    compactStepper("起始出现位置", value: startPositionBinding, range: 0...100, step: 1, suffix: "%")
                }
                .frame(width: rowWidth, alignment: .leading)
                Spacer()
            }
        }
        .padding(.top, 0)
        .padding(.horizontal, 36)
    }

    @ViewBuilder
    private var petImage: some View {
        if let previewImage {
            Image(nsImage: previewImage)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .separatorColor).opacity(0.25))
                .frame(width: 120, height: 120)
        }
    }

    private var assetPackRow: some View {
        HStack(spacing: rowSpacing) {
            Text("资源包 ID")
                .frame(width: labelWidth, alignment: .trailing)
            AssetPackComboBox(text: $draft.selectedAssetPackID, items: availableAssetPackIDs)
                .frame(width: assetInputWidth, height: 22)
        }
        .frame(width: rowWidth, alignment: .leading)
    }

    private var assetPackActionsRow: some View {
        HStack(spacing: rowSpacing) {
            Spacer()
                .frame(width: labelWidth)
            HStack(spacing: rowSpacing) {
                Button("打开资源包位置") {
                    onOpenAssetPacksFolder()
                    availableAssetPackIDs = onReloadAssetPackIDs()
                }
                Spacer(minLength: 0)
                Button("加载所选") {
                    loadSelectedAssetPack()
                }
            }
            .frame(width: controlWidth, alignment: .leading)
        }
        .frame(width: rowWidth, alignment: .leading)
    }

    private var parametersTab: some View {
        VStack(alignment: .center, spacing: 14) {
            settingsPanel(
                title: {
                    HStack(spacing: 12) {
                        sectionTitle("提醒设置")
                        Toggle("", isOn: $draft.remindersEnabled)
                            .toggleStyle(.checkbox)
                            .labelsHidden()
                        Text("开启提醒模式")
                            .font(.system(size: 14))
                        Spacer()
                    }
                },
                content: {
                    compactStepper("喝水提醒", value: minutesBinding(\.waterReminderInterval), range: 1...240, step: 5, suffix: "分钟")
                    compactStepper("久坐提醒", value: minutesBinding(\.movementReminderInterval), range: 5...360, step: 5, suffix: "分钟")
                    compactStepper("默认出门时长", value: minutesBinding(\.defaultOutingDuration), range: 5...480, step: 5, suffix: "分钟")
                }
            )

            settingsPanel(
                title: {
                    sectionTitle("状态参数")
                },
                content: {
                    rangeRow("休息时长", minimum: minutesBinding(\.restDurationMinimum), maximum: minutesBinding(\.restDurationMaximum), range: 1...480)
                    rangeRow("散步时长", minimum: minutesBinding(\.walkDurationMinimum), maximum: minutesBinding(\.walkDurationMaximum), range: 1...480)
                    compactStepper("散步基础速度", value: speedBinding, range: 8...240, step: 4, suffix: "px/s")
                }
            )
            settingsPanel(
                title: {
                    sectionTitle("AI 启动助手")
                },
                content: {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("请输入 Gemini API Key", text: $geminiAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
            
                        Button("从剪贴板粘贴") {
                            if let copiedText = NSPasteboard.general.string(forType: .string) {
                                geminiAPIKey = copiedText.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        }

                        HStack {
                            Button("保存并测试") {
                                UserDefaults.standard.set(geminiAPIKey, forKey: "gemini_api_key")

                                Task {
                                    let result = await AIStartHelper.shared.generateMicroTask(from: "写周报")

                                    let alert = NSAlert()
                                    alert.messageText = "Gemini 已连接"
                                    alert.informativeText = """
                                    测试成功。
                                   """
                               alert.addButton(withTitle: "好")
                               alert.runModal()

                                }
                            }
                        }

                        Text("API Key 仅保存在本机，用于“帮我拆成第一步”。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            )
            settingsPanel(
                title: {
                    sectionTitle("多显示器设置")
                },
                content: {
                    displaySelectionRow
                }
            )

            Spacer()
        }
        .padding(.top, 12)
        .padding(.horizontal, 14)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
    }

    private func settingsPanel<Title: View, Content: View>(
        @ViewBuilder title: () -> Title,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            title()
                .frame(width: panelWidth, alignment: .leading)
            GroupBox {
                VStack(alignment: .center, spacing: 10) {
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 6)
            } label: {
                EmptyView()
            }
            .frame(width: panelWidth)
        }
        .frame(width: panelWidth, alignment: .leading)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.4"
    }

    private var projectURL: URL {
        URL(string: "https://github.com/Eileen-111/Pebble")!
    }

    private var collectablesTab: some View {
        VStack(alignment: .center, spacing: 14) {
            GroupBox {
                VStack(alignment: .center, spacing: 8) {
                    Text("Pebble 已陪伴你 \(usageStatistics.litScreenUsageHoursText) 小时")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: labelWidth + controlWidth, alignment: .center)
                    Text("已完成喝水提醒 \(usageStatistics.completedWaterReminderCount) 次、走动提醒 \(usageStatistics.completedMovementReminderCount) 次")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: labelWidth + controlWidth, alignment: .center)
                    Text("\(draft.catName) 出门遇到事件 \(usageStatistics.outingEventCount) 次、带回礼物 \(usageStatistics.outingCollectableCount) 次")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: labelWidth + controlWidth, alignment: .center)
                }
                .frame(width: labelWidth + controlWidth, alignment: .center)
                .padding(.vertical, 6)
            } label: {
                sectionTitle("数据统计")
            }
            .frame(width: panelWidth, alignment: .center)

            if acquiredCollectables.isEmpty {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
                    .frame(width: 360, height: 150)
                    .overlay {
                        Text("还没有收藏品")
                            .foregroundStyle(.secondary)
                    }
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(92), spacing: 12), count: 4), spacing: 12) {
                        ForEach(acquiredCollectables) { item in
                            collectableCell(item)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(height: 260)
            }

            Spacer()
        }
        .padding(.top, 12)
        .padding(.horizontal, 14)
    }

    private var displaySelectionRow: some View {
        HStack(spacing: rowSpacing) {
            Text("猫咪出现在")
                .frame(width: labelWidth, alignment: .trailing)
            Picker("", selection: $draft.activityDisplayID) {
                ForEach(displayOptions) { option in
                    Text(option.title)
                        .tag(option.displayID)
                }
            }
            .labelsHidden()
            .frame(width: displayControlWidth, alignment: .leading)
        }
        .frame(width: labelWidth + rowSpacing + displayControlWidth, alignment: .center)
    }

    private var acquiredCollectables: [CollectableDisplayItem] {
        let collectablesByID = Dictionary(uniqueKeysWithValues: outingCatalog.collectables.map { ($0.id, $0) })
        return collectableInventory.acquiredEntries.compactMap { entry in
            guard let collectable = collectablesByID[entry.collectableID] else { return nil }
            return CollectableDisplayItem(
                collectable: collectable,
                imageURL: outingCatalog.imageURL(for: collectable),
                count: entry.count,
                isNew: collectableInventory.recentNewCollectableID == collectable.id
            )
        }
        .sorted {
            if $0.collectable.rarity == $1.collectable.rarity {
                return $0.collectable.chineseName < $1.collectable.chineseName
            }
            return $0.collectable.rarity > $1.collectable.rarity
        }
    }

    private func collectableCell(_ item: CollectableDisplayItem) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
                    }
                collectableImage(url: item.imageURL)
                    .frame(width: 72, height: 72, alignment: .center)
                if item.isNew {
                    VStack {
                        HStack {
                            Spacer()
                            Text("New")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(4)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 88, height: 78)

            Text(item.collectable.chineseName)
                .font(.system(size: 12))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 88)
            Text(String(repeating: "★", count: item.collectable.rarity))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 88)
        }
        .frame(width: 92, height: 122)
    }

    @ViewBuilder
    private func collectableImage(url: URL) -> some View {
        if let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .separatorColor).opacity(0.25))
        }
    }

    private func compactTextField(_ title: String, text: Binding<String>) -> some View {
        HStack(spacing: rowSpacing) {
            Text(title)
                .frame(width: labelWidth, alignment: .trailing)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .frame(width: controlWidth)
        }
        .frame(width: rowWidth, alignment: .leading)
    }

    private func loadSelectedAssetPack() {
        availableAssetPackIDs = onReloadAssetPackIDs()
        let result = onLoadAssetPack(draft.selectedAssetPackID)
        if result.report.isLoadable {
            draft.selectedAssetPackID = result.report.requestedID
            previewImage = result.dialogueImage
        }
        showAssetPackValidationAlert(result.report)
    }

    private func showAssetPackValidationAlert(_ report: AssetPackValidationReport) {
        let alert = NSAlert()
        alert.alertStyle = report.isLoadable ? .informational : .warning
        alert.messageText = report.isLoadable ? "加载校验结果" : "资源包加载失败"
        alert.informativeText = assetPackValidationText(report)
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    private func assetPackValidationText(_ report: AssetPackValidationReport) -> String {
        guard let pack = report.pack else {
            return "资源包 ID：\(report.requestedID)\n\(report.errorDescription ?? "未知错误。")"
        }

        var lines = [
            "资源包 ID：\(pack.id)",
            "猫咪名字：\(pack.manifest.name)",
            "作者：\(pack.manifest.author)",
            ""
        ]

        for status in report.poseStatuses {
            if status.isAvailable {
                lines.append("\(status.title)：\(status.count) 张可用")
            } else {
                lines.append("\(status.title)：缺失，将使用默认小猫")
            }
        }

        if report.walkFrameCount > 0 {
            lines.append("散步动画：\(report.walkFrameCount) 帧可用，\(formatFPS(pack.manifest.animations.walk.fps)) fps")
        } else {
            lines.append("散步动画：缺失，将使用默认小猫")
        }

        let iconsAvailable = report.hasValidSleepIcon && report.hasValidEmptyIcon
        lines.append("App 图标：\(iconsAvailable ? "自定义图标可用" : "缺失，将使用默认小猫")")
        return lines.joined(separator: "\n")
    }

    private func formatFPS(_ fps: Double) -> String {
        fps.rounded() == fps ? String(Int(fps)) : String(format: "%.1f", fps)
    }

    private func compactStepper(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        suffix: String
    ) -> some View {
        HStack(spacing: rowSpacing) {
            Text(title)
                .frame(width: labelWidth, alignment: .trailing)
            HStack(spacing: 6) {
                Text("\(Int(value.wrappedValue))")
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 48, alignment: .trailing)
                Stepper("", value: value, in: range, step: step)
                    .labelsHidden()
                    .frame(width: 22)
                Text(suffix)
                    .frame(width: controlWidth - 82, alignment: .leading)
            }
            .frame(width: controlWidth, alignment: .leading)
        }
        .frame(width: rowWidth, alignment: .leading)
    }

    private func rangeRow(
        _ title: String,
        minimum: Binding<Double>,
        maximum: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        HStack(spacing: rowSpacing) {
            Text(title)
                .frame(width: labelWidth, alignment: .trailing)
            HStack(spacing: 4) {
                numericStepper(value: minimum, range: range, step: 1)
                Text("–")
                numericStepper(value: maximum, range: range, step: 1)
                Text("分钟")
            }
            .frame(width: controlWidth, alignment: .leading)
        }
        .frame(width: rowWidth, alignment: .leading)
    }

    private func numericStepper(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        HStack(spacing: 3) {
            Text("\(Int(value.wrappedValue))")
                .font(.system(.body, design: .monospaced))
                .frame(width: 28, alignment: .trailing)
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
                .frame(width: 22)
        }
        .frame(width: 54, alignment: .leading)
    }

    private var speedBinding: Binding<Double> {
        Binding(
            get: { draft.walkBaseSpeed },
            set: { draft.walkBaseSpeed = max(1, $0) }
        )
    }

    private var scaleBinding: Binding<Double> {
        Binding(
            get: { draft.catScalePercent },
            set: { draft.catScalePercent = max(1, min(100, $0)) }
        )
    }

    private var startPositionBinding: Binding<Double> {
        Binding(
            get: { draft.startPositionPercent },
            set: { draft.startPositionPercent = max(0, min(100, $0)) }
        )
    }

    private func minutesBinding(_ keyPath: WritableKeyPath<AppSettings, TimeInterval>) -> Binding<Double> {
        Binding(
            get: { draft[keyPath: keyPath] / 60 },
            set: { draft[keyPath: keyPath] = $0 * 60 }
        )
    }

    private func normalized(_ settings: AppSettings) -> AppSettings {
        var normalized = settings
        if normalized.restDurationMinimum > normalized.restDurationMaximum {
            let minimum = normalized.restDurationMaximum
            normalized.restDurationMaximum = normalized.restDurationMinimum
            normalized.restDurationMinimum = minimum
        }
        if normalized.walkDurationMinimum > normalized.walkDurationMaximum {
            let minimum = normalized.walkDurationMaximum
            normalized.walkDurationMaximum = normalized.walkDurationMinimum
            normalized.walkDurationMinimum = minimum
        }
        normalized.walkBaseSpeed = max(1, normalized.walkBaseSpeed)
        normalized.catScalePercent = max(1, min(100, normalized.catScalePercent))
        normalized.startPositionPercent = max(0, min(100, normalized.startPositionPercent))
        return normalized
    }
}

private struct CollectableDisplayItem: Identifiable {
    var collectable: OutingCollectable
    var imageURL: URL
    var count: Int
    var isNew: Bool

    var id: String {
        collectable.id
    }
}
