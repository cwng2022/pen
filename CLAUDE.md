# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the project (Debug)
xcodebuild -project pen.xcodeproj -scheme pen -configuration Debug build

# Build the project (Release)
xcodebuild -project pen.xcodeproj -scheme pen -configuration Release build

# Clean build folder
xcodebuild -project pen.xcodeproj -scheme pen clean

# Run tests (when test target is added)
xcodebuild -project pen.xcodeproj -scheme pen test
```

Alternatively, open `pen.xcodeproj` in Xcode and use Cmd+B to build, Cmd+R to run.

## Architecture

This is a SwiftUI macOS application using the standard App protocol pattern:

- **penApp.swift**: App entry point using `@main`, defines the `WindowGroup` scene
- **ContentView.swift**: Main view displayed in the window
- **Assets.xcassets**: Asset catalog for images, colors, and app icon

The project uses Swift 6 concurrency features with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY` enabled.

## Project Configuration

- Bundle ID: `code.pen`
- Deployment target: macOS 26.2
- App Sandbox: Enabled
- Swift version: 5.0
