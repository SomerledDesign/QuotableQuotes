import AppKit

/// Entry point for the standalone ScreenSaver executable.
///
/// Configures `NSApplication`, installs the app delegate, and starts the main run loop.
let app = NSApplication.shared
let delegate = AppDelegate()

print("[ScreenSaver] process started")
app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()
