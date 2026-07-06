import AppKit

struct DisplayDescriptor: Equatable {
    var displayID: UInt32
    var name: String
    var frame: CGRect
    var visibleFrame: CGRect
}

struct DisplaySelectionOption: Identifiable, Equatable {
    var displayID: UInt32?
    var title: String

    var id: String {
        displayID.map { "display-\($0)" } ?? "primary"
    }
}

enum DockGeometry {
    static func currentActivitySpace(activityDisplayID: UInt32?, startPositionPercent: Double) -> ActivitySpace {
        makeActivitySpace(
            activityDisplayID: activityDisplayID,
            startPositionPercent: startPositionPercent,
            displays: currentDisplayDescriptors()
        )
    }

    static func currentDisplaySelectionOptions() -> [DisplaySelectionOption] {
        displaySelectionOptions(displays: currentDisplayDescriptors())
    }

    static func currentActivityScreen(activityDisplayID: UInt32?) -> NSScreen? {
        selectedScreen(activityDisplayID: activityDisplayID, screens: NSScreen.screens)
    }

    static func makeActivitySpace(
        activityDisplayID: UInt32?,
        startPositionPercent: Double,
        displays: [DisplayDescriptor]
    ) -> ActivitySpace {
        let descriptor = selectedDisplay(activityDisplayID: activityDisplayID, displays: displays)
        let frame = descriptor?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visibleFrame = descriptor?.visibleFrame ?? frame
        return ActivitySpace.make(
            screenFrame: frame,
            visibleFrame: visibleFrame,
            startPositionPercent: CGFloat(startPositionPercent)
        )
    }

    static func displaySelectionOptions(displays: [DisplayDescriptor]) -> [DisplaySelectionOption] {
        let displayOptions = displays.map { display in
            DisplaySelectionOption(
                displayID: display.displayID,
                title: displayTitle(for: display)
            )
        }
        return [DisplaySelectionOption(displayID: nil, title: "主显示器")] + displayOptions
    }

    static func selectedDisplay(activityDisplayID: UInt32?, displays: [DisplayDescriptor]) -> DisplayDescriptor? {
        if let activityDisplayID,
           let selected = displays.first(where: { $0.displayID == activityDisplayID }) {
            return selected
        }
        return primaryDisplay(displays: displays)
    }

    static func primaryDisplay(displays: [DisplayDescriptor]) -> DisplayDescriptor? {
        displays.first { $0.frame.origin == .zero } ?? displays.first
    }

    static func selectedScreen(activityDisplayID: UInt32?, screens: [NSScreen]) -> NSScreen? {
        if let activityDisplayID,
           let selected = screens.first(where: { $0.displayID == activityDisplayID }) {
            return selected
        }
        return screens.first { $0.frame.origin == .zero } ?? NSScreen.main ?? screens.first
    }

    private static func currentDisplayDescriptors() -> [DisplayDescriptor] {
        NSScreen.screens.compactMap { screen in
            guard let displayID = screen.displayID else { return nil }
            return DisplayDescriptor(
                displayID: displayID,
                name: screen.localizedName,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame
            )
        }
    }

    private static func displayTitle(for display: DisplayDescriptor) -> String {
        let width = Int(display.frame.width.rounded())
        let height = Int(display.frame.height.rounded())
        return "\(display.name) \(width)x\(height)"
    }
}

private extension NSScreen {
    var displayID: UInt32? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value
    }
}
