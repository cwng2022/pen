//
//  AppDelegate.swift
//  pen
//

import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var overlayWindowController: OverlayWindowController?
    private var hotkeyManager: HotkeyManager?
    private let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // No Accessibility permission needed with Carbon HotKey API!
        setupMenuBar()
        setupHotkeys()
        setupOverlayWindows()

        print("🚀 Pen app started (using Carbon HotKey - no permissions required)")
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "pencil.tip", accessibilityDescription: "Pen")
        }

        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "啟動標註模式", action: #selector(toggleAnnotation), keyEquivalent: "2")
        toggleItem.keyEquivalentModifierMask = .command
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let clearItem = NSMenuItem(title: "清除所有標註", action: #selector(clearAnnotations), keyEquivalent: "")
        menu.addItem(clearItem)

        let screenshotItem = NSMenuItem(title: "截圖", action: #selector(takeScreenshot), keyEquivalent: "6")
        screenshotItem.keyEquivalentModifierMask = .command
        menu.addItem(screenshotItem)

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(title: "關於 Pen", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func setupHotkeys() {
        hotkeyManager = HotkeyManager(
            appState: appState,
            onToggle: { [weak self] in
                self?.toggleAnnotation()
            },
            onScreenshot: { [weak self] in
                self?.takeScreenshot()
            }
        )
        hotkeyManager?.start()
    }

    private func setupOverlayWindows() {
        overlayWindowController = OverlayWindowController(appState: appState)
    }

    @objc private func toggleAnnotation() {
        appState.toggleAnnotating()
        updateMenuBarIcon()

        if appState.isAnnotating {
            overlayWindowController?.showOverlays()
            print("✏️ Annotation mode: ON")
        } else {
            overlayWindowController?.hideOverlays()
            print("✏️ Annotation mode: OFF")
        }
    }

    @objc private func clearAnnotations() {
        appState.clearAll()
        overlayWindowController?.refreshOverlays()
        print("🗑️ All annotations cleared")
    }

    @objc private func takeScreenshot() {
        // Capture screen with annotations visible
        ScreenshotService.captureScreen(destination: .desktop)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Pen"
        alert.informativeText = """
        螢幕標註工具 v1.0

        快捷鍵:
        ⌘+2 啟動/關閉標註
        R/G/B/Y 切換顏色
        ⌘++ / ⌘+- 調整筆刷大小
        E 橡皮擦
        ⌘+Z 撤銷 / ⌘+⇧+Z 重做
        ⌘+T 文字工具
        ⌘+6 截圖
        Esc 退出標註

        形狀繪製 (拖動時按住):
        ⌘ 矩形
        ⌘+Shift 箭頭
        Option 圓形
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "確定")
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func updateMenuBarIcon() {
        if let button = statusItem?.button {
            let imageName = appState.isAnnotating ? "pencil.tip.crop.circle.fill" : "pencil.tip"
            button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "Pen")
        }

        if let menu = statusItem?.menu, let toggleItem = menu.items.first {
            toggleItem.title = appState.isAnnotating ? "關閉標註模式" : "啟動標註模式"
        }
    }
}
