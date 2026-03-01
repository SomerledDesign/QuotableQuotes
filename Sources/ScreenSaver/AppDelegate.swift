import AppKit

/// Main application delegate for the standalone runtime.
///
/// Responsibilities:
/// - create the main menu and options window
/// - launch in windowed or fullscreen mode
/// - enforce screensaver-style exit behavior while fullscreen
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow?
    private var optionsWindow: NSWindow?
    private var inputMonitor: Any?
    private var shouldExitOnInput = false

    /// Application startup hook.
    ///
    /// - Parameter notification: Launch notification from AppKit.
    func applicationDidFinishLaunching(_ notification: Notification) {
        createMainMenu()

        let screens = NSScreen.screens
        let wantsFullscreen = CommandLine.arguments.contains("--fullscreen")
        print("[ScreenSaver] didFinishLaunching")
        print("[ScreenSaver] detected screens: \(screens.count)")
        print("[ScreenSaver] fullscreen mode: \(wantsFullscreen)")

        let contentViewController = QuoteViewController()

        let window = NSWindow(
            contentRect: NSRect(x: 120, y: 120, width: 1280, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ScreenSaver"
        window.backgroundColor = .black
        window.isOpaque = true
        window.contentViewController = contentViewController
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)

        guard wantsFullscreen else {
            print("[ScreenSaver] launching debug titled window")
            return
        }

        guard let mainScreen = NSScreen.main else {
            print("[ScreenSaver] fullscreen requested but NSScreen.main unavailable; staying windowed")
            return
        }

        print("[ScreenSaver] entering native fullscreen")
        print("[ScreenSaver] main screen frame: \(mainScreen.frame)")
        shouldExitOnInput = true
        installInputExitMonitor()
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.window else { return }
            window.collectionBehavior.insert(.fullScreenPrimary)
            window.acceptsMouseMovedEvents = true
            window.toggleFullScreen(nil)
        }
    }

    /// Indicates that the app should terminate after closing the last window.
    ///
    /// - Parameter sender: The shared `NSApplication` instance.
    /// - Returns: `true` to terminate automatically.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    /// Application termination hook.
    ///
    /// Removes any local event monitor created for fullscreen input-exit handling.
    /// - Parameter notification: Termination notification from AppKit.
    func applicationWillTerminate(_ notification: Notification) {
        if let inputMonitor {
            NSEvent.removeMonitor(inputMonitor)
        }
    }

    /// Opens the options window or brings the existing one to front.
    ///
    /// - Parameter _: Sender from menu action.
    @objc private func openOptionsWindow(_: Any?) {
        if let optionsWindow, optionsWindow.isVisible {
            optionsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = OptionsViewController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Options"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentViewController = controller
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.optionsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Tracks closure of the options window and clears retained reference.
    ///
    /// - Parameter notification: Window-close notification.
    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }
        if closingWindow === optionsWindow {
            optionsWindow = nil
        }
    }

    /// Installs a local event monitor that exits fullscreen mode on input.
    ///
    /// While the options window is visible, input is allowed through without terminating.
    private func installInputExitMonitor() {
        let mask: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .scrollWheel,
            .keyDown
        ]
        inputMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            guard let self, self.shouldExitOnInput else {
                return event
            }
            if let optionsWindow = self.optionsWindow, optionsWindow.isVisible {
                // Allow full interaction with Options without terminating fullscreen mode.
                return event
            }

            if event.type == .keyDown {
                switch event.keyCode {
                case 53:
                    print("[ScreenSaver] escape pressed; exiting")
                    Task { @MainActor in
                        NSApp.terminate(nil)
                    }
                    return nil
                default:
                    print("[ScreenSaver] key input detected (\(event.keyCode)); exiting")
                    Task { @MainActor in
                        NSApp.terminate(nil)
                    }
                    return nil
                }
            }

            print("[ScreenSaver] input detected (\(event.type.rawValue)); exiting")
            Task { @MainActor in
                NSApp.terminate(nil)
            }
            return nil
        }
    }

    /// Builds and installs the app main menu (`Options...`, `Quit`).
    private func createMainMenu() {
        let menu = NSMenu()

        let appMenuItem = NSMenuItem()
        menu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "Options...",
            action: #selector(openOptionsWindow(_:)),
            keyEquivalent: ","
        ).target = self
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Quit ScreenSaver",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu

        NSApp.mainMenu = menu
    }
}
