import AppKit

let application = NSApplication.shared
let delegate = DockCatApplication()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
