//
//  CanvasView.swift
//  pen
//

import SwiftUI

struct CanvasView: View {
    @Bindable var appState: AppState
    let screenID: UInt32

    @State private var currentStroke: Stroke?
    @State private var currentShape: ShapeAnnotation?

    // Modifier key states for shape drawing
    @State private var isShiftPressed: Bool = false
    @State private var isOptionPressed: Bool = false
    @State private var isCommandPressed: Bool = false

    // Text input state
    @State private var isEditingText: Bool = false
    @State private var textInputPosition: CGPoint = .zero
    @State private var textInputContent: String = ""

    // Mouse position for cursor overlay
    @State private var mousePosition: CGPoint = .zero
    @State private var isMouseInThisWindow: Bool = false

    // Canvas size for coordinate conversion
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        ZStack {
            Canvas { context, size in
                // 保存 Canvas 大小供座標轉換使用
                DispatchQueue.main.async {
                    if canvasSize != size {
                        canvasSize = size
                    }
                }

                // Draw all existing elements for this screen only
                for element in appState.elements where element.screenID == screenID {
                    drawElement(element, in: &context)
                }

                // Draw current stroke being drawn
                if let stroke = currentStroke {
                    drawStroke(stroke, in: &context)
                }

                // Draw current shape being drawn
                if let shape = currentShape {
                    drawShape(shape, in: &context)
                }
            }
            .gesture(drawingGesture)

            // 光標只在滑鼠位於這個視窗時顯示
            if isMouseInThisWindow {
                CursorOverlay(
                    position: mousePosition,
                    size: appState.currentLineWidth,
                    color: appState.currentColor,
                    tool: appState.currentTool,
                    shapeType: getShapeTypeFromModifiers()
                )
            }

            // Text input overlay
            if isEditingText {
                TextInputOverlay(
                    position: textInputPosition,
                    text: $textInputContent,
                    color: appState.currentColor,
                    onSubmit: { text in
                        if !text.isEmpty {
                            let textAnnotation = TextAnnotation(
                                text: text,
                                position: Point(textInputPosition),
                                color: appState.currentColor,
                                fontSize: appState.currentLineWidth * 4, // Scale font size
                                screenID: screenID
                            )
                            appState.addElement(.text(textAnnotation))
                        }
                        isEditingText = false
                        textInputContent = ""
                    },
                    onCancel: {
                        isEditingText = false
                        textInputContent = ""
                    }
                )
            }
        }
        .onAppear {
            setupKeyMonitor()
        }
    }

    private var drawingGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = Point(value.location)

                // Text tool - just record position, handle on end
                if appState.currentTool == .text {
                    return
                }

                // 直接讀取當前修飾鍵狀態（不依賴 @State 變數）
                let modifierFlags = NSEvent.modifierFlags
                let shapeType = getShapeTypeFromFlags(modifierFlags)

                if appState.currentTool == .eraser {
                    eraseAt(point: value.location)
                } else if let shapeType = shapeType {
                    // Shape drawing mode based on modifier keys:
                    // Shift = rectangle, ⌘+Shift = arrow, Option = circle
                    if currentShape == nil {
                        currentShape = ShapeAnnotation(
                            shapeType: shapeType,
                            startPoint: point,
                            endPoint: point,
                            color: appState.currentColor,
                            lineWidth: appState.currentLineWidth,
                            screenID: screenID
                        )
                    } else {
                        currentShape?.endPoint = point
                    }
                } else {
                    // Pen drawing mode
                    if currentStroke == nil {
                        currentStroke = Stroke(
                            points: [point],
                            color: appState.currentColor,
                            lineWidth: appState.currentLineWidth,
                            screenID: screenID
                        )
                    } else {
                        currentStroke?.points.append(point)
                    }
                }
            }
            .onEnded { value in
                // Text tool - show input at tap location
                if appState.currentTool == .text {
                    textInputPosition = value.location
                    textInputContent = ""
                    isEditingText = true
                    return
                }

                if let stroke = currentStroke {
                    appState.addElement(.stroke(stroke))
                    currentStroke = nil
                }
                if let shape = currentShape {
                    appState.addElement(.shape(shape))
                    currentShape = nil
                }
            }
    }

    private func setupKeyMonitor() {
        // Monitor modifier key changes for shape drawing
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            isShiftPressed = event.modifierFlags.contains(.shift)
            isOptionPressed = event.modifierFlags.contains(.option)
            isCommandPressed = event.modifierFlags.contains(.command)
            return event
        }

        // Track mouse movement for cursor overlay
        // 只在滑鼠進入這個視窗時顯示光標
        NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { event in
            if let eventWindow = event.window,
               let eventScreenID = eventWindow.screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 {
                if eventScreenID == screenID {
                    isMouseInThisWindow = true
                    mousePosition = event.locationInWindow
                } else {
                    isMouseInThisWindow = false
                }
            } else {
                isMouseInThisWindow = false
            }
            return event
        }

        // 當滑鼠離開視窗時隱藏光標
        NSEvent.addLocalMonitorForEvents(matching: .mouseExited) { event in
            isMouseInThisWindow = false
            return event
        }

        // 當滑鼠進入視窗時顯示光標
        NSEvent.addLocalMonitorForEvents(matching: .mouseEntered) { event in
            if let eventWindow = event.window,
               let eventScreenID = eventWindow.screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32,
               eventScreenID == screenID {
                isMouseInThisWindow = true
            }
            return event
        }
    }

    /// Determine shape type based on NSEvent modifier flags
    /// - ⌘ (Command) = rectangle
    /// - ⌘+Shift = arrow
    /// - Option = circle
    private func getShapeTypeFromFlags(_ flags: NSEvent.ModifierFlags) -> ShapeType? {
        let hasShift = flags.contains(.shift)
        let hasOption = flags.contains(.option)
        let hasCommand = flags.contains(.command)

        if hasCommand && hasShift {
            return .arrow
        } else if hasCommand {
            return .rectangle
        } else if hasOption {
            return .circle
        }
        return nil
    }

    /// For cursor overlay - read current modifier flags directly
    private func getShapeTypeFromModifiers() -> ShapeType? {
        return getShapeTypeFromFlags(NSEvent.modifierFlags)
    }

    private func eraseAt(point: CGPoint) {
        let eraseRadius = appState.currentLineWidth * 2

        // 座標轉換：DragGesture 使用的是視圖座標（Y 從上往下）
        // 所以不需要轉換，直接使用 point
        // 注意：之前的問題可能是因為 canvasSize 還沒初始化

        // Find elements to remove (only from this screen, in reverse order)
        var indicesToRemove: [Int] = []

        for (index, element) in appState.elements.enumerated() {
            guard element.screenID == screenID else { continue }
            if elementIntersects(element, with: point, radius: eraseRadius) {
                indicesToRemove.append(index)
            }
        }

        // Remove in reverse order
        for index in indicesToRemove.reversed() {
            appState.removeElement(at: index)
        }
    }

    private func elementIntersects(_ element: DrawingElement, with point: CGPoint, radius: CGFloat) -> Bool {
        switch element {
        case .stroke(let stroke):
            // 檢查每個點是否在擦除範圍內
            for strokePoint in stroke.points {
                let distance = hypot(strokePoint.x - point.x, strokePoint.y - point.y)
                // 增加判斷範圍，確保筆畫可以被擦除
                if distance < radius + stroke.lineWidth {
                    return true
                }
            }
            // 也檢查線段之間的區域
            if stroke.points.count >= 2 {
                for i in 0..<(stroke.points.count - 1) {
                    let p1 = stroke.points[i]
                    let p2 = stroke.points[i + 1]
                    let dist = pointToLineDistance(point: point, lineStart: p1.cgPoint, lineEnd: p2.cgPoint)
                    if dist < radius + stroke.lineWidth {
                        return true
                    }
                }
            }
        case .shape(let shape):
            // Simple bounding box check for shapes
            let minX = min(shape.startPoint.x, shape.endPoint.x)
            let maxX = max(shape.startPoint.x, shape.endPoint.x)
            let minY = min(shape.startPoint.y, shape.endPoint.y)
            let maxY = max(shape.startPoint.y, shape.endPoint.y)

            if point.x >= minX - radius && point.x <= maxX + radius &&
               point.y >= minY - radius && point.y <= maxY + radius {
                return true
            }
        case .text(let text):
            let distance = hypot(text.position.x - point.x, text.position.y - point.y)
            if distance < radius + 50 { // Rough estimate for text hit area
                return true
            }
        }
        return false
    }

    /// 計算點到線段的最短距離
    private func pointToLineDistance(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        let lengthSquared = dx * dx + dy * dy

        if lengthSquared == 0 {
            // 線段長度為 0，直接計算到起點的距離
            return hypot(point.x - lineStart.x, point.y - lineStart.y)
        }

        // 計算投影點的參數 t
        let t = max(0, min(1, ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / lengthSquared))

        // 計算最近點
        let nearestX = lineStart.x + t * dx
        let nearestY = lineStart.y + t * dy

        return hypot(point.x - nearestX, point.y - nearestY)
    }

    private func drawElement(_ element: DrawingElement, in context: inout GraphicsContext) {
        switch element {
        case .stroke(let stroke):
            drawStroke(stroke, in: &context)
        case .shape(let shape):
            drawShape(shape, in: &context)
        case .text(let text):
            drawText(text, in: &context)
        }
    }

    private func drawStroke(_ stroke: Stroke, in context: inout GraphicsContext) {
        guard stroke.points.count > 1 else { return }

        var path = Path()
        path.move(to: stroke.points[0].cgPoint)

        for i in 1..<stroke.points.count {
            path.addLine(to: stroke.points[i].cgPoint)
        }

        context.stroke(
            path,
            with: .color(stroke.color.color),
            style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawShape(_ shape: ShapeAnnotation, in context: inout GraphicsContext) {
        let start = shape.startPoint.cgPoint
        let end = shape.endPoint.cgPoint

        var path = Path()

        switch shape.shapeType {
        case .rectangle:
            let rect = CGRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
            path.addRect(rect)

        case .circle:
            let rect = CGRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
            path.addEllipse(in: rect)

        case .arrow:
            // Draw arrow from start to end
            path.move(to: start)
            path.addLine(to: end)

            // Calculate arrow head
            let angle = atan2(end.y - start.y, end.x - start.x)
            let arrowLength: CGFloat = 20
            let arrowAngle: CGFloat = .pi / 6

            let arrowPoint1 = CGPoint(
                x: end.x - arrowLength * cos(angle - arrowAngle),
                y: end.y - arrowLength * sin(angle - arrowAngle)
            )
            let arrowPoint2 = CGPoint(
                x: end.x - arrowLength * cos(angle + arrowAngle),
                y: end.y - arrowLength * sin(angle + arrowAngle)
            )

            path.move(to: end)
            path.addLine(to: arrowPoint1)
            path.move(to: end)
            path.addLine(to: arrowPoint2)
        }

        context.stroke(
            path,
            with: .color(shape.color.color),
            style: StrokeStyle(lineWidth: shape.lineWidth, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawText(_ text: TextAnnotation, in context: inout GraphicsContext) {
        context.draw(
            Text(text.text)
                .font(.system(size: text.fontSize))
                .foregroundColor(text.color.color),
            at: text.position.cgPoint,
            anchor: .topLeading
        )
    }
}

// MARK: - Text Input Overlay

struct TextInputOverlay: View {
    let position: CGPoint
    @Binding var text: String
    let color: AnnotationColor
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            TextField("輸入文字...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color.color)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(color.color, lineWidth: 2)
                        )
                )
                .frame(width: 300)
                .position(
                    x: min(max(position.x + 150, 160), geometry.size.width - 160),
                    y: min(max(position.y, 30), geometry.size.height - 30)
                )
                .focused($isFocused)
                .onSubmit {
                    onSubmit(text)
                }
                .onExitCommand {
                    onCancel()
                }
                .onAppear {
                    isFocused = true
                }
        }
    }
}

// MARK: - Cursor Overlay

struct CursorOverlay: View {
    let position: CGPoint
    let size: CGFloat
    let color: AnnotationColor
    let tool: Tool
    let shapeType: ShapeType?

    var body: some View {
        GeometryReader { geometry in
            // Convert window coordinates to view coordinates
            let viewPosition = CGPoint(
                x: position.x,
                y: geometry.size.height - position.y  // Flip Y coordinate
            )

            // Only show cursor when mouse is in the view
            if viewPosition.x >= 0 && viewPosition.x <= geometry.size.width &&
               viewPosition.y >= 0 && viewPosition.y <= geometry.size.height {

                ZStack {
                    // Main cursor circle showing brush size
                    Circle()
                        .stroke(color.color, lineWidth: 2)
                        .frame(width: size, height: size)
                        .position(viewPosition)

                    // Shape indicator when modifier keys are pressed
                    if let shapeType = shapeType {
                        shapeIndicator(for: shapeType)
                            .position(x: viewPosition.x, y: viewPosition.y - size / 2 - 16)
                    }

                    // Tool indicator
                    if tool == .eraser {
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                            .frame(width: size * 2, height: size * 2)
                            .position(viewPosition)
                    } else if tool == .text {
                        Image(systemName: "character.cursor.ibeam")
                            .font(.system(size: 20))
                            .foregroundColor(color.color)
                            .position(viewPosition)
                    }
                }
            }
        }
        .allowsHitTesting(false)  // Don't block mouse events
    }

    @ViewBuilder
    private func shapeIndicator(for type: ShapeType) -> some View {
        Group {
            switch type {
            case .rectangle:
                Image(systemName: "rectangle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color.color)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
            case .circle:
                Image(systemName: "circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color.color)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
            case .arrow:
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color.color)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
            }
        }
    }
}
