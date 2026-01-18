//
//  Drawing.swift
//  pen
//

import Foundation

struct Point: Codable {
    var x: Double
    var y: Double

    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }

    init(_ cgPoint: CGPoint) {
        self.x = cgPoint.x
        self.y = cgPoint.y
    }

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

struct Stroke: Identifiable, Codable {
    let id: UUID
    var points: [Point]
    var color: AnnotationColor
    var lineWidth: CGFloat
    var screenID: UInt32  // CGDirectDisplayID

    init(points: [Point] = [], color: AnnotationColor = .red, lineWidth: CGFloat = 5.0, screenID: UInt32 = 0) {
        self.id = UUID()
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.screenID = screenID
    }
}

struct ShapeAnnotation: Identifiable, Codable {
    let id: UUID
    var shapeType: ShapeType
    var startPoint: Point
    var endPoint: Point
    var color: AnnotationColor
    var lineWidth: CGFloat
    var screenID: UInt32

    init(shapeType: ShapeType, startPoint: Point, endPoint: Point, color: AnnotationColor, lineWidth: CGFloat, screenID: UInt32 = 0) {
        self.id = UUID()
        self.shapeType = shapeType
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.lineWidth = lineWidth
        self.screenID = screenID
    }
}

struct TextAnnotation: Identifiable, Codable {
    let id: UUID
    var text: String
    var position: Point
    var color: AnnotationColor
    var fontSize: CGFloat
    var screenID: UInt32

    init(text: String, position: Point, color: AnnotationColor, fontSize: CGFloat, screenID: UInt32 = 0) {
        self.id = UUID()
        self.text = text
        self.position = position
        self.color = color
        self.fontSize = fontSize
        self.screenID = screenID
    }
}

enum DrawingElement: Identifiable, Codable {
    case stroke(Stroke)
    case shape(ShapeAnnotation)
    case text(TextAnnotation)

    var id: UUID {
        switch self {
        case .stroke(let s): return s.id
        case .shape(let s): return s.id
        case .text(let t): return t.id
        }
    }

    var screenID: UInt32 {
        switch self {
        case .stroke(let s): return s.screenID
        case .shape(let s): return s.screenID
        case .text(let t): return t.screenID
        }
    }
}

struct DrawingDocument: Codable {
    var elements: [DrawingElement]
    var createdAt: Date
    var modifiedAt: Date

    init(elements: [DrawingElement] = []) {
        self.elements = elements
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}
