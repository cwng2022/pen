//
//  HotkeyManager.swift
//  pen
//
//  Rewritten to use Carbon HotKey API (no permissions required)
//

import AppKit
import Carbon.HIToolbox

// Helper class to hold the callback reference
private class HotkeyCallback {
    let action: () -> Void
    init(action: @escaping () -> Void) {
        self.action = action
    }
}

@MainActor
final class HotkeyManager {
    // Carbon hotkey for Cmd+2 (no permission needed)
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callbackRef: HotkeyCallback?

    // Local event monitor for annotation mode keys (no permission needed)
    private var localMonitor: Any?

    private weak var appState: AppState?
    private let onToggle: () -> Void
    private let onScreenshot: (() -> Void)?

    init(appState: AppState, onToggle: @escaping () -> Void, onScreenshot: (() -> Void)? = nil) {
        self.appState = appState
        self.onToggle = onToggle
        self.onScreenshot = onScreenshot
    }

    func start() {
        registerCarbonHotkey()
        setupLocalMonitor()
        print("✅ HotkeyManager: Started with Carbon HotKey + Local Monitor (no permissions required)")
    }

    private func registerCarbonHotkey() {
        // Create callback holder
        callbackRef = HotkeyCallback { [weak self] in
            self?.onToggle()
        }

        // Set up event handler for hotkey events
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Install event handler
        let handlerCallback: EventHandlerUPP = { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }

            // Get the hotkey ID from the event
            var hotKeyID = EventHotKeyID()
            let err = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard err == noErr else { return err }

            // Check if it's our hotkey (signature "PEN!", id 1)
            if hotKeyID.signature == OSType(0x50454E21) && hotKeyID.id == 1 {
                let callback = Unmanaged<HotkeyCallback>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    callback.action()
                }
            }

            return noErr
        }

        guard let callback = callbackRef else { return }

        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            handlerCallback,
            1,
            &eventType,
            Unmanaged.passUnretained(callback).toOpaque(),
            &eventHandler
        )

        guard status == noErr else {
            print("❌ HotkeyManager: Failed to install event handler: \(status)")
            return
        }

        // Register Cmd+2 hotkey
        // "PEN!" as signature (0x50454E21)
        var hotKeyID = EventHotKeyID(signature: OSType(0x50454E21), id: UInt32(1))

        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_2),
            UInt32(cmdKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus == noErr {
            print("✅ HotkeyManager: Registered Cmd+2 global hotkey")
        } else {
            print("❌ HotkeyManager: Failed to register hotkey: \(registerStatus)")
        }
    }

    private func setupLocalMonitor() {
        // Local monitor receives events when our app's windows are focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Handle annotation mode keys
            if self.handleAnnotationKey(event: event) {
                return nil  // Consume the event
            }

            return event
        }

        print("✅ HotkeyManager: Local event monitor set up")
    }

    private func handleAnnotationKey(event: NSEvent) -> Bool {
        guard let appState = appState else { return false }

        let keyCode = Int(event.keyCode)
        let hasCommand = event.modifierFlags.contains(.command)
        let hasShift = event.modifierFlags.contains(.shift)

        // Always handle Cmd+6 for screenshot (even when not annotating)
        if hasCommand && keyCode == kVK_ANSI_6 {
            onScreenshot?()
            return true
        }

        // Only handle other keys when annotating
        guard appState.isAnnotating else { return false }

        // Keys without modifiers
        if !hasCommand {
            switch keyCode {
            case kVK_ANSI_R:
                appState.setColor(.red)
                print("🔴 Color: Red")
                return true

            case kVK_ANSI_G:
                appState.setColor(.green)
                print("🟢 Color: Green")
                return true

            case kVK_ANSI_B:
                appState.setColor(.blue)
                print("🔵 Color: Blue")
                return true

            case kVK_ANSI_Y:
                appState.setColor(.yellow)
                print("🟡 Color: Yellow")
                return true

            case kVK_ANSI_E:
                if appState.currentTool == .eraser {
                    appState.setTool(.pen)
                    print("🖊️ Tool: Pen")
                } else {
                    appState.setTool(.eraser)
                    print("🧹 Tool: Eraser")
                }
                return true

            case kVK_ANSI_C:
                appState.clearAll()
                print("🗑️ Cleared all")
                return true

            // Shape keys 1/2/3 removed - now use modifier keys:
            // Shift + drag = rectangle
            // ⌘+Shift + drag = arrow
            // Option + drag = circle

            case kVK_Escape:
                onToggle()
                print("⎋ Exit annotation mode")
                return true

            default:
                break
            }
        }

        // Cmd+Z for undo, Cmd+Shift+Z for redo
        if hasCommand && keyCode == kVK_ANSI_Z {
            if hasShift {
                appState.redo()
                print("↪️ Redo")
            } else {
                appState.undo()
                print("↩️ Undo")
            }
            return true
        }

        // Cmd+= (plus) to increase line width
        if hasCommand && keyCode == kVK_ANSI_Equal {
            appState.increaseLineWidth()
            print("➕ Line width: \(appState.currentLineWidth)")
            return true
        }

        // Cmd+- (minus) to decrease line width
        if hasCommand && keyCode == kVK_ANSI_Minus {
            appState.decreaseLineWidth()
            print("➖ Line width: \(appState.currentLineWidth)")
            return true
        }

        // Cmd+T for text tool
        if hasCommand && keyCode == kVK_ANSI_T {
            appState.setTool(.text)
            print("📝 Tool: Text")
            return true
        }

        return false
    }

    func stop() {
        // Unregister Carbon hotkey
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        // Remove event handler
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }

        // Remove local monitor
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }

        callbackRef = nil

        print("🛑 HotkeyManager: Stopped")
    }

    deinit {
        // Note: deinit is nonisolated, so we just clean up directly
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
