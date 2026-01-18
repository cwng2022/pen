//
//  Tool.swift
//  pen
//

import Foundation

enum Tool: String, Codable {
    case pen
    case shape
    case text
    case eraser
}

enum ShapeType: String, Codable {
    case rectangle
    case circle
    case arrow
}
