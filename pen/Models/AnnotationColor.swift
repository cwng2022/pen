//
//  AnnotationColor.swift
//  pen
//

import SwiftUI

enum AnnotationColor: String, Codable, CaseIterable {
    case red
    case green
    case blue
    case yellow

    var color: Color {
        switch self {
        case .red: return Color(red: 1.0, green: 0.231, blue: 0.188)      // #FF3B30
        case .green: return Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759
        case .blue: return Color(red: 0.0, green: 0.478, blue: 1.0)      // #007AFF
        case .yellow: return Color(red: 1.0, green: 0.8, blue: 0.0)      // #FFCC00
        }
    }

    var nsColor: NSColor {
        switch self {
        case .red: return NSColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1.0)
        case .green: return NSColor(red: 0.204, green: 0.780, blue: 0.349, alpha: 1.0)
        case .blue: return NSColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
        case .yellow: return NSColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        }
    }

    static func fromKey(_ key: String) -> AnnotationColor? {
        switch key.lowercased() {
        case "r": return .red
        case "g": return .green
        case "b": return .blue
        case "y": return .yellow
        default: return nil
        }
    }
}
