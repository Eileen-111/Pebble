import Foundation
import os

enum DockCatLog {
    static let app = Logger(subsystem: "com.tianmaizhang.DockCat", category: "App")
    static let assets = Logger(subsystem: "com.tianmaizhang.DockCat", category: "Assets")
    static let state = Logger(subsystem: "com.tianmaizhang.DockCat", category: "State")
}

