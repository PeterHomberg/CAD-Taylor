// ============================================
// File: DrawingCanvasView.swift
// Main canvas view with drawing and selection functionality
// FIXED: Zoom now respects canvas boundaries and hit-test works correctly
// ============================================

import SwiftUI

struct DrawingCanvasView: View {
    static let a4Size = CGSize(width: CGFloat(210).pts, height: CGFloat(297).pts)
    
    // Shape-based system (replaces lines)
    @State private var shapes: [Shape] = []
    @State private var currentShape: Shape?
    @State private var temporaryShape: TemporaryShape?
    @State private var selectedShapeID: UUID?
    
    // Interaction modes
    @State private var interactionMode: InteractionMode = .draw
    @State private var editMode: EditMode = .move
    //@State private var selectedDrawingMode: DrawingMode = .freehand
    
    // Drag state for editing
    @State private var dragStartPoint: CGPoint?
    @State private var originalShape: Shape?
    @State private var activeResizeHandle: ResizeHandle?
    
    // UI state
    @State private var currentCoordinates = CGPoint.zero
    
    //@State private var canvasSize = CGSize(width: 210, height: 297)
    @State private var canvasSize = DrawingCanvasView.a4Size
    @State private var showCoordinates = true
    @State private var zoomLevel: CGFloat = 1.0
    @State private var mouseDownLocation: CGPoint?
    @Binding var showInMillimeters: Bool
    @State var oldPoint: CGPoint = .zero
    @StateObject var model = DrawingModel()
    var body: some View {
        HStack(spacing: 0) {
            // Main canvas area
            VStack {
                // Drawing canvas with GeometryReader for proper zoom handling
                // Neu:
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack {
                        // Hintergrund (Schatten-Effekt um A4-Seite)
                        Rectangle()
                            .fill(Color(NSColor.windowBackgroundColor))
                            .frame(
                                width: canvasSize.width * zoomLevel + 40,
                                height: canvasSize.height * zoomLevel + 40
                            )
                        
                        // A4 Canvas
                        ZStack {
                            Rectangle()
                                .fill(Color.white)
                                .border(Color.gray, width: 1)
                                .shadow(color: .gray.opacity(0.4), radius: 5, x: 2, y: 2)
                            /*----------------------------------------------------------------------
                            MouseTrackingView { location in
                                // Koordinaten direkt übernehmen (kein zoomLevel-Offset nötig,
                                // da der Canvas selbst skaliert wird)
                                let adjustedLocation = CGPoint(
                                    x: location.x / zoomLevel,
                                    y: location.y / zoomLevel
                                )
                                currentCoordinates = adjustedLocation
                            }
                            ------------------------------------------------------------------------*/
                            DrawingView(
                                model: model,
                                shapes: shapes,
                                canvasSize: $canvasSize,
                                
                                
                                onMouseMoved:{ location in
                                    // Koordinaten direkt übernehmen (kein zoomLevel-Offset nötig,
                                    // da der Canvas selbst skaliert wird)
                                    let adjustedLocation = CGPoint(
                                        x: location.x / zoomLevel,
                                        y: location.y / zoomLevel
                                    )

                                    currentCoordinates = model.coordinate
                                    /*
                                    if location != oldPoint {
                                        print("DrawingCanvasView mouseMoved: \(model.coordinate)")
                                        oldPoint = model.coordinate
                                    }
                                     */

                                },
                                onMouseDown: { location in
                                    let adjusted = CGPoint(x: location.x / zoomLevel,
                                                           y: location.y / zoomLevel)
                                    mouseDownLocation = adjusted
                                    handleMouseDown(at: adjusted)
                                },
                                onMouseDragged: { location in
                                     let adjusted = CGPoint(x: location.x / zoomLevel,
                                                            y: location.y / zoomLevel)
                                     handleMouseDragged(at: adjusted)
                                 },
                                 onMouseUp: { location in
                                     let adjusted = CGPoint(x: location.x / zoomLevel,
                                                            y: location.y / zoomLevel)
                                     handleMouseUp(at: adjusted)
                                 }
                            )
                            if let selectedID = selectedShapeID,
                               let shape = shapes.first(where: { $0.id == selectedID }) {
                                SelectionOverlay(shape: shape)
                            }
                        }
                        .frame(width: canvasSize.width, height: canvasSize.height)
                        .scaleEffect(zoomLevel)
                    }
                    .frame(
                        width: canvasSize.width * zoomLevel + 40,
                        height: canvasSize.height * zoomLevel + 40
                    )
                }
                .background(Color(NSColor.windowBackgroundColor))                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
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
                    //selectedMode: $selectedDrawingMode,
                    selectedMode: $model.selectedDrawingMode,
                    shapes: $shapes,
                    showInMillimeters: $showInMillimeters,
                    model: model,
                    onCommitBezier: commitBezierShape
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
    
    // MARK: - Mouse Event Handlers
    //
    // Mapping NSView events → drawing logic:
    //
    //   mouseDown    = first contact, set start point
    //   mouseDragged = continuous update while button held
    //   mouseUp      = commit / finalise
    //
    // Each mode uses the events differently:
    //   Freehand    : down=start shape, drag=add points, up=commit shape
    //   StraightLine: down=set start, drag=update end preview, up=commit
    //   Square      : down=set start, drag=update corner preview, up=commit
    //   CircleArc   : down=add point (3 clicks total), drag ignored, up unused
    //   CubicBezier : handled separately in handleBezierGesture
 
    private func handleMouseDown(at location: CGPoint) {
        currentCoordinates = location
 
        switch interactionMode {
        case .draw:
            break
        case .select:
            // Start selection / find handle
            if editMode == .resize,
               let shapeID = selectedShapeID,
               let shape = shapes.first(where: { $0.id == shapeID }),
               let handle = ResizeHandle.findHandle(at: location, for: shape) {
                activeResizeHandle = handle
                dragStartPoint = location
                if let index = shapes.firstIndex(where: { $0.id == shapeID }) {
                    originalShape = shapes[index]
                }
            } else if let foundShape = HitTesting.findShape(at: location, in: shapes) {
                selectedShapeID = foundShape.id
                dragStartPoint = location
                if let index = shapes.firstIndex(where: { $0.id == foundShape.id }) {
                    originalShape = shapes[index]
                }
            } else {
                selectedShapeID = nil
                dragStartPoint = nil
            }
        }
    }
 
    private func handleMouseDragged(at location: CGPoint) {
        currentCoordinates = location
 
        switch interactionMode {
        case .draw:
            break
        case .select:
            guard dragStartPoint != nil else { return }
            if activeResizeHandle != nil {
                handleShapeResize(to: location)
            } else if editMode == .move {
                handleShapeMove(to: location)
            }
        }
    }
 
    private func commitShape() {
        switch model.selectedDrawingMode {
        case .freehand:
            if let temp = model.shape, temp.type == .freehand &&
                                        temp.points.count > 0 {
                shapes.append(temp)
            }
        case .straightLine:
            if let temp = model.shape, model.shape?.points.count == 2 {
                shapes.append(temp)
                temporaryShape = nil
            }

        case .square:
            if let shape = model.shape, model.shape?.points.count == 4 {
                shapes.append(shape)
                temporaryShape = nil
            }

        case .circleArc:
            if let temp = model.shape, model.shape?.type == .circleArc &&
                                        model.shape?.points.count == 3{
                shapes.append(temp)
                temporaryShape = nil
            }


        case .cubicBezier:
            break
        }

    }
    private func handleMouseUp(at location: CGPoint) {
        switch interactionMode {
        case .draw:
            commitShape()
        case .select:
            dragStartPoint = nil
            originalShape = nil
            activeResizeHandle = nil
        }
 
        mouseDownLocation = nil
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
    private func commitBezierShape() {
        guard !model.bezierSegments.isEmpty else {
            print("commitBezierShape: model.bezierSegments is EMPTY — nothing to commit")
            return
        }
        let shape = Shape(type: .cubicBezier, bezierSegments: model.bezierSegments)
        print("commitBezierShape: created shape type=\(shape.type) segments=\(shape.bezierSegments.count)")
        print("commitBezierShape: geometry=\(shape.geometry)")
        shapes.append(shape)
        print("commitBezierShape: shapes.count=\(shapes.count), last type=\(shapes.last!.type)")
        model.clear()
        model.bezierMode = false        // ← triggers clean re-render with updated shapes
        model.selectedDrawingMode = .freehand // ← optional: switch tool back

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
        case .cubicBezier: return "Cubic Bezier"
            
        }
    }
}

/************************************************************************************
 no more needed
 
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
 ---------------------------------------------------------------*/
