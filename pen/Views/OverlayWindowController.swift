//
//  OverlayWindowController.swift
//  pen
//

import AppKit
import SwiftUI

// Custom window that can become key window to receive keyboard events
class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
class OverlayWindowController {
    private var overlayWindows: [KeyableWindow] = []
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        setupWindows()
    }

    private func setupWindows() {
        // Create an overlay window for each screen
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen)
            overlayWindows.append(window)
        }

        // Listen for screen configuration changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.rebuildWindows()
            }
        }
    }

    private func createOverlayWindow(for screen: NSScreen) -> KeyableWindow {
        let window = KeyableWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = false
        window.acceptsMouseMovedEvents = true

        // Get the screen's display ID with robust fallback
        let screenID: UInt32
        if let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 {
            screenID = displayID
            print("📺 Screen setup: origin=\(screen.frame.origin), displayID=\(displayID)")
        } else {
            // Fallback: use screen index based on frame position
            let fallbackID = UInt32(abs(Int(screen.frame.origin.x)) % 10000 + abs(Int(screen.frame.origin.y)) % 10000)
            screenID = fallbackID
            print("⚠️ Screen ID fallback: origin=\(screen.frame.origin), fallbackID=\(fallbackID)")
        }

        let canvasView = CanvasView(appState: appState, screenID: screenID)
        window.contentView = NSHostingView(rootView: canvasView)

        return window
    }

    private func rebuildWindows() {
        let wasVisible = overlayWindows.first?.isVisible ?? false

        // Close existing windows
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()

        // Recreate for all current screens
        setupWindows()

        // Restore visibility state
        if wasVisible {
            showOverlays()
        }
    }

    func showOverlays() {
        for (index, screen) in NSScreen.screens.enumerated() {
            if index < overlayWindows.count {
                let window = overlayWindows[index]
                window.setFrame(screen.frame, display: true)
                window.orderFrontRegardless()
            }
        }

        // Make the first window key to receive keyboard events
        if let firstWindow = overlayWindows.first {
            firstWindow.makeKeyAndOrderFront(nil)
        }

        // Activate the app to receive keyboard events
        NSApp.activate(ignoringOtherApps: true)

        // Hide the dock icon when annotating
        NSApp.setActivationPolicy(.accessory)

        print("📺 Overlay windows shown, app activated for keyboard events")
    }

    func hideOverlays() {
        for window in overlayWindows {
            window.orderOut(nil)
        }

        // Show dock icon when not annotating
        NSApp.setActivationPolicy(.regular)
    }

    func refreshOverlays() {
        for window in overlayWindows {
            window.contentView?.needsDisplay = true
        }
    }
}
