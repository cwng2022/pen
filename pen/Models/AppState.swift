//
//  AppState.swift
//  pen
//

import SwiftUI

@MainActor
@Observable
class AppState {
    var isAnnotating: Bool = false
    var currentTool: Tool = .pen
    var currentShapeType: ShapeType = .rectangle
    var currentColor: AnnotationColor = .red
    var currentLineWidth: CGFloat = 5.0
    var elements: [DrawingElement] = []
    var undoStack: [[DrawingElement]] = []
    var redoStack: [[DrawingElement]] = []

    // Line width constraints
    let minLineWidth: CGFloat = 1.0
    let maxLineWidth: CGFloat = 50.0
    let lineWidthStep: CGFloat = 2.0

    func toggleAnnotating() {
        isAnnotating.toggle()
    }

    func setTool(_ tool: Tool) {
        currentTool = tool
    }

    func setShapeType(_ shapeType: ShapeType) {
        currentShapeType = shapeType
    }

    func setColor(_ color: AnnotationColor) {
        currentColor = color
    }

    func increaseLineWidth() {
        currentLineWidth = min(currentLineWidth + lineWidthStep, maxLineWidth)
    }

    func decreaseLineWidth() {
        currentLineWidth = max(currentLineWidth - lineWidthStep, minLineWidth)
    }

    func addElement(_ element: DrawingElement) {
        saveStateForUndo()
        elements.append(element)
        redoStack.removeAll()
    }

    func removeElement(at index: Int) {
        guard index >= 0 && index < elements.count else { return }
        saveStateForUndo()
        elements.remove(at: index)
        redoStack.removeAll()
    }

    func clearAll() {
        guard !elements.isEmpty else { return }
        saveStateForUndo()
        elements.removeAll()
        redoStack.removeAll()
    }

    func undo() {
        guard let previousState = undoStack.popLast() else { return }
        redoStack.append(elements)
        elements = previousState
    }

    func redo() {
        guard let nextState = redoStack.popLast() else { return }
        undoStack.append(elements)
        elements = nextState
    }

    private func saveStateForUndo() {
        undoStack.append(elements)
        // Limit undo stack size
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }
}
