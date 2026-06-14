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
    private var launchedFullscreen = false
    private var fullscreenPresentationWorkItem: DispatchWorkItem?

    /// Application startup hook.
    ///
    /// - Parameter notification: Launch notification from AppKit.
    func applicationDidFinishLaunching(_ notification: Notification) {
        createMainMenu()

        let screens = NSScreen.screens
        let wantsFullscreen = CommandLine.arguments.contains("--fullscreen")
        launchedFullscreen = wantsFullscreen
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
        self.window = window
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        installInputExitMonitor()

        guard wantsFullscreen else {
            print("[ScreenSaver] launching debug titled window")
            return
        }

        print("[ScreenSaver] entering native fullscreen")
        if let mainScreen = NSScreen.main {
            print("[ScreenSaver] main screen frame: \(mainScreen.frame)")
        }
        shouldExitOnInput = true
        presentFullscreenWindow(window)
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
        shouldExitOnInput = false
        fullscreenPresentationWorkItem?.cancel()

        if let optionsWindow, optionsWindow.isVisible {
            optionsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = OptionsViewController()
        _ = controller.view
        let preferredSize = controller.preferredContentSize
        let contentSize = NSSize(
            width: max(preferredSize.width, 500),
            height: max(preferredSize.height, 360)
        )
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
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
            if launchedFullscreen {
                restoreInputExitAfterOptionsClose()
            }
        }
    }

    /// Installs a local event monitor that exits fullscreen mode on input.
    ///
    /// While the options window is visible, input is allowed through without terminating.
    private func installInputExitMonitor() {
        guard inputMonitor == nil else { return }
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

            if self.isFullscreenOptionsShortcut(event) {
                self.openOptionsWindow(nil)
                return nil
            }

            if let optionsWindow = self.optionsWindow, optionsWindow.isVisible {
                // Allow full interaction with Options without terminating fullscreen mode.
                return event
            }

            if event.type == .keyDown {
                switch event.keyCode {
                case 53:
                    guard self.shouldExitOnInput else { return event }
                    print("[ScreenSaver] escape pressed; exiting")
                    Task { @MainActor in
                        NSApp.terminate(nil)
                    }
                    return nil
                default:
                    guard self.shouldExitOnInput else { return event }
                    print("[ScreenSaver] key input detected (\(event.keyCode)); exiting")
                    Task { @MainActor in
                        NSApp.terminate(nil)
                    }
                    return nil
                }
            }

            guard self.shouldExitOnInput else {
                return event
            }
            print("[ScreenSaver] input detected (\(event.type.rawValue)); exiting")
            Task { @MainActor in
                NSApp.terminate(nil)
            }
            return nil
        }
    }

    /// Returns `true` when the event is the `Cmd+,` shortcut for Options.
    private func isFullscreenOptionsShortcut(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown else { return false }
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command) else { return false }
        return event.charactersIgnoringModifiers == ","
    }

    /// Brings the fullscreen host window on-screen and activates the app.
    /// A short deferred pass is used because launch-time focus/fullscreen
    /// transitions are flaky if we only do them once inside
    /// `applicationDidFinishLaunching`.
    private func presentFullscreenWindow(_ window: NSWindow) {
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.acceptsMouseMovedEvents = true

        fullscreenPresentationWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak window] in
            guard let window else { return }
            NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
        fullscreenPresentationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    /// Re-enables screensaver-style exit after the close gesture on Options has
    /// fully finished, so the close click itself does not terminate the app.
    private func restoreInputExitAfterOptionsClose() {
        shouldExitOnInput = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self else { return }
            guard self.optionsWindow == nil else { return }
            self.shouldExitOnInput = true
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
