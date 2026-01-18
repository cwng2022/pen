//
//  ScreenshotService.swift
//  pen
//
//  Screenshot capture service using ScreenCaptureKit
//

import AppKit
import ScreenCaptureKit

@MainActor
class ScreenshotService {
    enum ScreenshotDestination {
        case clipboard
        case desktop
        case file(URL)
    }

    /// Capture the main display
    static func captureScreen(destination: ScreenshotDestination = .desktop) {
        Task {
            do {
                // Get available content
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

                guard let display = content.displays.first else {
                    print("❌ Screenshot: No display found")
                    return
                }

                // Create filter for the display
                let filter = SCContentFilter(display: display, excludingWindows: [])

                // Configure capture
                let config = SCStreamConfiguration()
                config.width = display.width
                config.height = display.height
                config.pixelFormat = kCVPixelFormatType_32BGRA
                config.showsCursor = false

                // Capture screenshot
                let image = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: config
                )

                // Convert to NSImage
                let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))

                await MainActor.run {
                    switch destination {
                    case .clipboard:
                        copyToClipboard(image: nsImage)
                        print("📸 Screenshot copied to clipboard")

                    case .desktop:
                        saveToDesktop(image: nsImage)

                    case .file(let url):
                        saveToFile(image: nsImage, url: url)
                    }
                }

            } catch {
                print("❌ Screenshot failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private Methods

    private static func copyToClipboard(image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    private static func saveToDesktop(image: NSImage) {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "Pen Screenshot \(timestamp).png"
        let fileURL = desktopURL.appendingPathComponent(filename)

        saveToFile(image: image, url: fileURL)
    }

    private static func saveToFile(image: NSImage, url: URL) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("❌ Screenshot: Failed to convert image to PNG")
            return
        }

        do {
            try pngData.write(to: url)
            print("📸 Screenshot saved to: \(url.path)")

            // Play screenshot sound
            NSSound(named: "Funk")?.play()

        } catch {
            print("❌ Screenshot: Failed to save file: \(error)")
        }
    }
}
