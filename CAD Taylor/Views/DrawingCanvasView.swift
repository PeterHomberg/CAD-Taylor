// ============================================
// File: DrawingCanvasView.swift
// Main canvas view with drawing and selection functionality
// FIXED: Zoom now respects canvas boundaries and hit-test works correctly
// ============================================

import SwiftUI

struct DrawingCanvasView: View {
    // Shape-based system (replaces lines)
    @State private var shapes: [Shape] = []
    @State private var currentShape: Shape?
    @State private var temporaryShape: TemporaryShape?
    @State private var selectedShapeID: UUID?
    
    // Interaction modes
    @State private var interactionMode: InteractionMode = .draw
    @State private var editMode: EditMode = .move
    @State private var selectedDrawingMode: DrawingMode = .freehand
    
    // Drag state for editing
    @State private var dragStartPoint: CGPoint?
    @State private var originalShape: Shape?
    @State private var activeResizeHandle: ResizeHandle?
    
    // UI state
    @State private var currentCoordinates = CGPoint.zero
    @State private var canvasSize = CGSize(width: 600, height: 400)
    @State private var showCoordinates = true
    @State private var zoomLevel: CGFloat = 1.0
    
    @Binding var showInMillimeters: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Main canvas area
            VStack {
                // Drawing canvas with GeometryReader for proper zoom handling
                GeometryReader { geometry in
                    ZStack {
                        Rectangle()
                            .fill(Color.white)
                            .border(Color.gray, width: 1)
                        
                        // Mouse tracking overlay
                        MouseTrackingView { location in
                            // Transform mouse coordinates for zoom
                            let canvasCenter = CGPoint(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2
                            )
                            
                            let offsetFromCenter = CGPoint(
                                x: location.x - canvasCenter.x,
                                y: location.y - canvasCenter.y
                            )
                            
                            let adjustedLocation = CGPoint(
                                x: (offsetFromCenter.x / zoomLevel) + canvasCenter.x,
                                y: (offsetFromCenter.y / zoomLevel) + canvasCenter.y
                            )
                            currentCoordinates = adjustedLocation
                        }
                        
                        // Drawing view
                        DrawingView(
                            shapes: shapes,
                            currentShape: currentShape,
                            temporaryShape: temporaryShape,
                            canvasSize: $canvasSize
                        )
                        .scaleEffect(zoomLevel)
                        
                        // Selection overlay
                        if let selectedID = selectedShapeID,
                           let shape = shapes.first(where: { $0.id == selectedID }) {
                            SelectionOverlay(shape: shape)
                                .scaleEffect(zoomLevel)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // KRITISCH: Verhindert Zeichnen über Canvas-Grenzen hinaus
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleGesture(
                                    location: value.location,
                                    phase: .changed,
                                    canvasSize: geometry.size
                                )
                            }
                            .onEnded { value in
                                handleGesture(
                                    location: value.location,
                                    phase: .ended,
                                    canvasSize: geometry.size
                                )
                            }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom toolbar
                HStack {
                    // Mode toggle buttons
                    HStack(spacing: 8) {
                        Button(action: { interactionMode = .draw }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Draw")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(interactionMode == .draw ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            interactionMode = .select
                            selectedShapeID = nil // Deselect when switching modes
                        }) {
                            HStack {
                                Image(systemName: "hand.point.up.left")
                                Text("Select")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(interactionMode == .select ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Actions
                    Button("Clear Canvas") {
                        clearCanvas()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .foregroundColor(Color.white)
                    .cornerRadius(6)
                    .buttonStyle(PlainButtonStyle())
                    
                    Button("Export PDF") {
                        exportPDF()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(Color.white)
                    .cornerRadius(6)
                    .buttonStyle(PlainButtonStyle())
                    
                    // Delete button (nur wenn Shape ausgewählt)
                    if selectedShapeID != nil {
                        Button("Delete") {
                            deleteSelectedShape()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .foregroundColor(Color.white)
                        .cornerRadius(6)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    // Coordinates display
                    if showCoordinates {
                        let xFormatted = CoordinateConverter.formatCoordinate(currentCoordinates.x, inMillimeters: showInMillimeters)
                        let yFormatted = CoordinateConverter.formatCoordinate(currentCoordinates.y, inMillimeters: showInMillimeters)
                        let unit = CoordinateConverter.unitLabel(inMillimeters: showInMillimeters)
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("X: \(xFormatted) \(unit), Y: \(yFormatted) \(unit) | Zoom: \(Int(zoomLevel * 100))%")
                                .font(.system(size: 14, design: .monospaced))
                            
                            if let selectedID = selectedShapeID,
                               let shape = shapes.first(where: { $0.id == selectedID }) {
                                Text("Selected: \(shape.type.displayName)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.blue)
                            } else if interactionMode == .select {
                                Text("Click to select a shape")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            .padding()
            
            // Right sidebar with drawing tools
            if interactionMode == .draw {
                DrawingToolbar(
                    selectedMode: $selectedDrawingMode,
                    shapes: $shapes,
                    showInMillimeters: $showInMillimeters
                )
            } else {
                EditToolbar(
                    editMode: $editMode,
                    shapes: $shapes,
                    selectedShapeID: $selectedShapeID,
                    showInMillimeters: $showInMillimeters,
                    hasSelection: selectedShapeID != nil
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            // Migration: convert any existing lines to shapes
            // This would be needed if you have old data
        }
        .setupNotificationHandlers(
            shapes: $shapes,
            currentShape: $currentShape,
            currentCoordinates: $currentCoordinates,
            zoomLevel: $zoomLevel,
            showCoordinates: $showCoordinates,
            canvasSize: canvasSize,
            onExport: exportPDF,
            onSave: saveDrawing,
            onOpen: openDrawing
        )
    }
    
    // MARK: - Gesture Handling
    
    enum GesturePhase {
        case changed, ended
    }
    
    private func handleGesture(location: CGPoint, phase: GesturePhase, canvasSize: CGSize) {
        // KRITISCH: Korrekte Koordinaten-Transformation für Zoom
        let canvasCenter = CGPoint(
            x: canvasSize.width / 2,
            y: canvasSize.height / 2
        )
        
        let offsetFromCenter = CGPoint(
            x: location.x - canvasCenter.x,
            y: location.y - canvasCenter.y
        )
        
        let adjustedLocation = CGPoint(
            x: (offsetFromCenter.x / zoomLevel) + canvasCenter.x,
            y: (offsetFromCenter.y / zoomLevel) + canvasCenter.y
        )
        
        switch interactionMode {
        case .draw:
            if phase == .changed {
                handleDrawing(at: adjustedLocation)
            } else {
                handleDrawingEnd(at: adjustedLocation)
            }
            
        case .select:
            if phase == .changed {
                handleSelection(at: adjustedLocation)
            } else {
                handleSelectionEnd(at: adjustedLocation)
            }
        }
    }
    
    // MARK: - Drawing Mode Logic
    
    private func handleDrawing(at location: CGPoint) {
        currentCoordinates = location
        
        switch selectedDrawingMode {
        case .freehand:
            if currentShape == nil {
                currentShape = Shape(type: .freehand)
            }
            currentShape?.points.append(location)
            
        case .straightLine:
            if temporaryShape == nil {
                temporaryShape = TemporaryShape(mode: .straightLine, points: [location])
            } else {
                temporaryShape?.points = [temporaryShape!.points[0], location]
            }
            
        case .square:
            if temporaryShape == nil {
                temporaryShape = TemporaryShape(mode: .square, points: [location])
            } else {
                temporaryShape?.points = [temporaryShape!.points[0], location]
            }
            
        case .circleArc:
            break
        }
    }
    
    private func handleDrawingEnd(at location: CGPoint) {
        switch selectedDrawingMode {
        case .freehand:
            if let shape = currentShape, !shape.points.isEmpty {
                shapes.append(shape)
            }
            currentShape = nil
            
        case .straightLine:
            if let temp = temporaryShape, temp.points.count == 2 {
                var shape = Shape(type: .straightLine)
                shape.points = temp.points
                shapes.append(shape)
                temporaryShape = nil
            }
            
        case .square:
            if let temp = temporaryShape, temp.points.count == 2, let rect = temp.rect {
                var shape = Shape(type: .rectangle)
                // 4 Eckpunkte im Uhrzeigersinn
                shape.points = [
                    CGPoint(x: rect.minX, y: rect.minY),
                    CGPoint(x: rect.maxX, y: rect.minY),
                    CGPoint(x: rect.maxX, y: rect.maxY),
                    CGPoint(x: rect.minX, y: rect.maxY)
                ]
                shapes.append(shape)
                temporaryShape = nil
            }
            
        case .circleArc:
            if temporaryShape == nil {
                temporaryShape = TemporaryShape(mode: .circleArc, points: [location])
            } else if temporaryShape!.points.count == 1 {
                temporaryShape?.points.append(location)
            } else if temporaryShape!.points.count == 2 {
                temporaryShape?.points.append(location)
                if let arc = calculateCircleArc(points: temporaryShape!.points) {
                    shapes.append(arc)
                }
                temporaryShape = nil
            }
        }
    }
    
    private func calculateCircleArc(points: [CGPoint]) -> Shape? {
        guard points.count == 3 else { return nil }
        
        let p1 = points[0]
        let p2 = points[1]
        let p3 = points[2]
        
        let d = 2 * (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y))
        guard abs(d) > 0.001 else { return nil }
        
        let ux = ((p1.x * p1.x + p1.y * p1.y) * (p2.y - p3.y) +
                  (p2.x * p2.x + p2.y * p2.y) * (p3.y - p1.y) +
                  (p3.x * p3.x + p3.y * p3.y) * (p1.y - p2.y)) / d
        
        let uy = ((p1.x * p1.x + p1.y * p1.y) * (p3.x - p2.x) +
                  (p2.x * p2.x + p2.y * p2.y) * (p1.x - p3.x) +
                  (p3.x * p3.x + p3.y * p3.y) * (p2.x - p1.x)) / d
        
        let center = CGPoint(x: ux, y: uy)
        let radius = sqrt(pow(p1.x - center.x, 2) + pow(p1.y - center.y, 2))
        
        let angle1 = atan2(p1.y - center.y, p1.x - center.x)
        let angle3 = atan2(p3.y - center.y, p3.x - center.x)
        
        var arcPoints: [CGPoint] = []
        let segments = 50
        
        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let angle = angle1 + (angle3 - angle1) * t
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            arcPoints.append(CGPoint(x: x, y: y))
        }
        
        var shape = Shape(type: .circleArc)
        shape.points = arcPoints
        return shape
    }
    
    // MARK: - Selection Mode Logic (Phase 2, 3 & 4)
    
    private func handleSelection(at location: CGPoint) {
        currentCoordinates = location
        
        if dragStartPoint == nil {
            // Erster Klick: Prüfe ob ein Handle geklickt wurde (Phase 4)
            if editMode == .resize,
               let shapeID = selectedShapeID,
               let shape = shapes.first(where: { $0.id == shapeID }) {
                
                // Versuche einen Resize-Handle zu finden
                if let handle = ResizeHandle.findHandle(at: location, for: shape) {
                    activeResizeHandle = handle
                    dragStartPoint = location
                    
                    if let index = shapes.firstIndex(where: { $0.id == shapeID }) {
                        originalShape = shapes[index]
                    }
                    return
                }
            }
            
            // Kein Handle: Shape suchen und auswählen
            if let foundShape = HitTesting.findShape(at: location, in: shapes) {
                selectedShapeID = foundShape.id
                dragStartPoint = location
                
                // Original Shape für Undo speichern
                if let index = shapes.firstIndex(where: { $0.id == foundShape.id }) {
                    originalShape = shapes[index]
                }
            } else {
                // Klick ins Leere: Deselect
                selectedShapeID = nil
            }
        } else {
            // Drag: Shape bearbeiten
            if activeResizeHandle != nil {
                handleShapeResize(to: location)
            } else if editMode == .move {
                handleShapeMove(to: location)
            }
        }
    }
    
    private func handleSelectionEnd(at location: CGPoint) {
        dragStartPoint = nil
        originalShape = nil
        activeResizeHandle = nil
    }
    
    private func handleShapeMove(to location: CGPoint) {
        guard let shapeID = selectedShapeID,
              let index = shapes.firstIndex(where: { $0.id == shapeID }),
              let startPoint = dragStartPoint,
              let original = originalShape else { return }
        
        let delta = CGPoint(
            x: location.x - startPoint.x,
            y: location.y - startPoint.y
        )
        
        // Alle Punkte des Shapes verschieben
        shapes[index].points = original.points.map { point in
            CGPoint(x: point.x + delta.x, y: point.y + delta.y)
        }
    }
    
    private func handleShapeResize(to location: CGPoint) {
        guard let shapeID = selectedShapeID,
              let index = shapes.firstIndex(where: { $0.id == shapeID }),
              let handle = activeResizeHandle,
              let original = originalShape else { return }
        
        // Nutze ShapeResizer für die Resize-Logik
        shapes[index] = ShapeResizer.resize(
            shape: shapes[index],
            handle: handle,
            newPosition: location,
            originalShape: original
        )
    }
    
    private func deleteSelectedShape() {
        guard let shapeID = selectedShapeID else { return }
        shapes.removeAll { $0.id == shapeID }
        selectedShapeID = nil
    }
    
    // MARK: - Canvas Actions
    
    private func clearCanvas() {
        shapes.removeAll()
        currentShape = nil
        temporaryShape = nil
        selectedShapeID = nil
        currentCoordinates = CGPoint.zero
    }
    
    private func exportPDF() {
        // Convert shapes to lines, preserving type information via point count
        let lines = shapes.map { shape in
            Line(points: shape.points, color: shape.color, width: shape.width)
        }
        
        guard let pdf = PDFExporter(pageSize: canvasSize) else {
            print("Konnte pdf nicht erstellen")
            return
        }

        
        
        pdf.savePDFWithDialog(shapes: shapes)
    }
    
    private func saveDrawing() {
        // Save shapes directly (preserves type information)
        DrawingSerializer.saveDrawingWithDialog(shapes: shapes, canvasSize: canvasSize)
    }
    
    private func openDrawing() {
        DrawingSerializer.openDrawingWithDialog { result in
            switch result {
            case .success(let data):
                // Shapes are now loaded with correct type information!
                shapes = data.shapes
                canvasSize = data.canvasSize
                currentShape = nil
                currentCoordinates = CGPoint.zero
                selectedShapeID = nil
            case .failure(let error):
                print("Failed to open drawing: \(error)")
            }
        }
    }
}

// MARK: - Shape Type Extension
extension ShapeType {
    var displayName: String {
        switch self {
        case .freehand: return "Freehand"
        case .straightLine: return "Straight Line"
        case .rectangle: return "Rectangle"
        case .circleArc: return "Circle Arc"
        case .text: return "Text"
            
        }
    }
}

// MARK: - Mouse Tracking View
struct MouseTrackingView: NSViewRepresentable {
    let onMouseMoved: (CGPoint) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = MouseTrackingNSView()
        view.onMouseMoved = onMouseMoved
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let trackingView = nsView as? MouseTrackingNSView {
            trackingView.onMouseMoved = onMouseMoved
        }
    }
}

class MouseTrackingNSView: NSView {
    var onMouseMoved: ((CGPoint) -> Void)?
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .activeInKeyWindow,
            .inVisibleRect
        ]
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: options,
            owner: self,
            userInfo: nil
        )
        
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let flippedLocation = CGPoint(x: location.x, y: bounds.height - location.y)
        onMouseMoved?(flippedLocation)
    }
}
