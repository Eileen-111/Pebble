import Foundation

enum RuntimeDiagnostics {
    static func record(_ message: @autoclosure () -> String) {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["DOCKCAT_DIAGNOSTICS"] == "1" else { return }
        let line = "\(Date()) \(message())\n"
        let url = URL(fileURLWithPath: "/tmp/dockcat-launch.log")
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        if let data = line.data(using: .utf8) {
            try? handle.write(contentsOf: data)
        }
        #endif
    }
}
