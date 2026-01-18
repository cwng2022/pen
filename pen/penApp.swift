//
//  penApp.swift
//  pen
//

import SwiftUI

@main
struct penApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
