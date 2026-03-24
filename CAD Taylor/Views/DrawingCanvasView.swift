// ============================================
// File: DrawingCanvasView.swift
// Updated for Integrated NSScrollView and Custom Button Styles
// ============================================

import SwiftUI

struct DrawingCanvasView: View {
    static let a4Size = CGSize(width: CGFloat(210).pts, height: CGFloat(297).pts)
    
    // Shape-based system
    @State private var shapes: [Shape] = []
    @State private var currentShape: Shape?
    @State private var temporaryShape: TemporaryShape?
    @State private var selectedShapeID: UUID?
    
    // Interaction modes
    @State private var editMode: EditMode = .move
    
    // Drag state for editing
    @State private var dragStartPoint: CGPoint?
    @State private var originalShape: Shape?
    @State private var activeResizeHandle: ResizeHandle?
    @State private var activeBezierHit: HitResult?
    
    // UI state
    @State private var currentCoordinates = CGPoint.zero
    @State private var canvasSize = DrawingCanvasView.a4Size
    @State private var showCoordinates = true
    @State private var zoomLevel: CGFloat = 1.0
    @State private var mouseDownLocation: CGPoint?
    @Binding var showInMillimeters: Bool
    @StateObject var model = DrawingModel()
    
    // Print setup
    @State private var showPrintSetup = false
    @State private var showCanvasSetup = false
    
    @State private var selectedPaper: PaperSize = .a4
    
    var body: some View {
        HStack(spacing: 0) {
            
            // MARK: - Main canvas area
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    DrawingView(
                        model: model,
                        shapes: shapes,
                        canvasSize: $canvasSize,
                        zoomLevel: $zoomLevel,
                        selectedShapeID: selectedShapeID,
                        editMode: editMode,
                        onMouseMoved: { location in
                            currentCoordinates = location
                        },
                        onMouseDown: { location in
                            mouseDownLocation = location
                            handleMouseDown(at: location)
                        },
                        onMouseDragged: { location in
                            handleMouseDragged(at: location)
                        },
                        onMouseUp: { location in
                            handleMouseUp(at: location)
                        },
                        onShapeCommitted: { shape in
                            shapes.append(shape)
                        }
                    )
                }
                .background(Color(NSColor.windowBackgroundColor))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // MARK: - Bottom toolbar
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Button(action: { model.interactionMode = .draw }) {
                            Label("Draw", systemImage: "pencil")
                        }
                        .toolbarButton(role: model.interactionMode == .draw ? .primary : .default)
                        
                        Button(action: {
                            model.interactionMode = .select
                            selectedShapeID = nil
                        }) {
                            Label("Select", systemImage: "hand.point.up.left")
                        }
                        .toolbarButton(role: model.interactionMode == .select ? .primary : .default)
                    }
                    
                    Divider().frame(height: 24)
                    
                    Button("Clear Canvas") { clearCanvas() }
                        .toolbarButton(role: .destructive)
                    
                    Button("Export PDF") { exportPDF() }
                        .toolbarButton(role: .confirm)
                    
                    if selectedShapeID != nil {
                        Button("Delete") { deleteSelectedShape() }
                            .toolbarButton(role: .destructive)
                    }
                    
                    Button("Print Pages") { showPrintSetup = true }
                        .toolbarButton(role: .primary)
                    
                    Button("Canvas Setup") { showCanvasSetup = true }
                        .toolbarButton(role: .default)
                    
                    Spacer()
                    
                    if showCoordinates {
                        coordinateOverlay
                    }
                }
                .padding(10)
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
            
            Divider()
            
            sidebarArea
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $showPrintSetup) {
            PrintSetupView(canvasSize: canvasSize, selectedPaper: $selectedPaper) { layout in
                exportMultiPage(layout: layout)
                showPrintSetup = false
            }
        }
        .sheet(isPresented: $showCanvasSetup) {
            CanvasSetupView(showCanvasSetup: $showCanvasSetup, canvasSize: $canvasSize)
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
            zoomLevel = min(zoomLevel + 0.25, 3.0)
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
            zoomLevel = max(zoomLevel - 0.25, 0.25)
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetZoom)) { _ in
            zoomLevel = 1.0
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
    // MARK: - View Components
    
    private var coordinateOverlay: some View {
        let xFormatted = CoordinateConverter.formatCoordinate(currentCoordinates.x, inMillimeters: showInMillimeters)
        let yFormatted = CoordinateConverter.formatCoordinate(currentCoordinates.y, inMillimeters: showInMillimeters)
        let unit = CoordinateConverter.unitLabel(inMillimeters: showInMillimeters)
        
        return VStack(alignment: .trailing, spacing: 2) {
            Text("X: \(xFormatted) \(unit), Y: \(yFormatted) \(unit)")
                .font(.system(size: 13, design: .monospaced))
            
            if let selectedID = selectedShapeID,
               let shape = shapes.first(where: { $0.id == selectedID }) {
                Text("Selected: \(shape.type.displayName)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.blue)
            }
        }
        .padding(6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }
    
    @ViewBuilder
    private var sidebarArea: some View {
        if model.interactionMode == .draw {
            DrawingToolbar(
                shapes: $shapes,
                showInMillimeters: $showInMillimeters,
                model: model,
                onCommitBezier: commitBezierShape
            )
            .fixedSize(horizontal: true, vertical: false)
        } else {
            EditToolbar(
                editMode: $editMode,
                shapes: $shapes,
                selectedShapeID: $selectedShapeID,
                showInMillimeters: $showInMillimeters,
                hasSelection: selectedShapeID != nil
            )
            .fixedSize(horizontal: true, vertical: false)
        }
    }
    
    // MARK: - Mouse Event Handlers
    
    private func handleMouseDown(at location: CGPoint) {
        currentCoordinates = location
        if model.interactionMode == .select {
            if editMode == .resize,
               let shapeID = selectedShapeID,
               let shape = shapes.first(where: { $0.id == shapeID }) {
                // Bezier: hit-test control/curve points first
                if shape.type == .cubicBezier {
                    if let hit = HitTesting.hitTestBezierPoints(mousePosition: location, bezierSegments: shape.bezierSegments) {
                        activeBezierHit = hit
                        originalShape = shape
                        dragStartPoint = location
                        return
                    }
                } else if let handle = ResizeHandle.findHandle(at: location, for: shape) {
                    activeResizeHandle = handle
                    dragStartPoint = location
                    originalShape = shape
                    return
                }
            }
            if let foundShape = HitTesting.findShape(at: location, in: shapes) {
                selectedShapeID = foundShape.id
                dragStartPoint = location
                originalShape = foundShape
            } else {
                selectedShapeID = nil
                dragStartPoint = nil
            }
        }
    }
    
    private func handleMouseDragged(at location: CGPoint) {
        currentCoordinates = location
        if model.interactionMode == .select {
            if let hit = activeBezierHit {
                handleBezierPointDrag(to: location, hit: hit)
            } else if activeResizeHandle != nil {
                handleShapeResize(to: location)
            } else if editMode == .move,
                      let startPoint = dragStartPoint, let original = originalShape {
                handleShapeMove(to: location, from: startPoint, original: original)
            }
        }
    }
    
    private func handleMouseUp(at location: CGPoint) {
        dragStartPoint = nil
        originalShape = nil
        activeResizeHandle = nil
        activeBezierHit = nil
        mouseDownLocation = nil
    }
    
    private func handleBezierPointDrag(to location: CGPoint, hit: HitResult) {
        guard let shapeID = selectedShapeID,
              let index = shapes.firstIndex(where: { $0.id == shapeID }),
              shapes[index].type == .cubicBezier else { return }
        
        var segs = shapes[index].bezierSegments
        switch hit {
        case .curvePoint(let i):
            segs[i].curvePoint = location
            // Keep the mirror segment's curvePoint1 in sync
            if segs.count > 1 && i == segs.count - 1 {
                segs[segs.count - 2].curvePoint1 = location
            }
        case .controlPoint(let i):
            segs[i].controlPoint = location
        case .controlPoint1(let i):
            segs[i].controlPoint1 = location
        }
        shapes[index].bezierSegments = segs
    }
    
    private func handleShapeMove(to location: CGPoint, from startPoint: CGPoint, original: Shape) {
        guard let shapeID = selectedShapeID,
              let index = shapes.firstIndex(where: { $0.id == shapeID }) else { return }
        
        let delta = CGPoint(x: location.x - startPoint.x, y: location.y - startPoint.y)
        
        var updated = original
        if updated.type == .cubicBezier {
            updated.bezierSegments = original.bezierSegments.map { $0.translated(by: delta) }
        } else {
            updated.points = original.points.map { CGPoint(x: $0.x + delta.x, y: $0.y + delta.y) }
        }
        shapes[index] = updated
    }
    
    private func handleShapeResize(to location: CGPoint) {
        guard let shapeID = selectedShapeID,
              let index = shapes.firstIndex(where: { $0.id == shapeID }),
              let handle = activeResizeHandle,
              let original = originalShape else { return }
        
        shapes[index] = ShapeResizer.resize(
            shape: shapes[index],
            handle: handle,
            newPosition: location,
            originalShape: original
        )
    }
    
    // MARK: - Actions
    
    private func deleteSelectedShape() {
        guard let shapeID = selectedShapeID else { return }
        shapes.removeAll { $0.id == shapeID }
        selectedShapeID = nil
    }
    
    private func clearCanvas() {
        shapes.removeAll()
        selectedShapeID = nil
        currentCoordinates = .zero
    }
    
    private func exportPDF() {
        PDFExporter(pageSize: canvasSize)?.savePDFWithDialog(shapes: shapes)
    }
    
    private func exportMultiPage(layout: PageLayout) {
        PDFExporter(pageSize: layout.paperSize)?.saveMultiPagePDFWithDialog(shapes: shapes, layout: layout)
    }
    private func saveDrawing() {
        DrawingSerializer.saveDrawingWithDialog(shapes: shapes, canvasSize: canvasSize)
    }
    
    private func openDrawing() {
        DrawingSerializer.openDrawingWithDialog { result in
            switch result {
            case .success(let data):
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
        guard !model.bezierSegments.isEmpty else { return }
        let shape = Shape(type: .cubicBezier, bezierSegments: model.bezierSegments)
        shapes.append(shape)
        model.clear()
        model.clearTemporaryShape = true
    }
}

// MARK: - Extensions

extension BezierSegment {
    func translated(by delta: CGPoint) -> BezierSegment {
        var newSegment = self
        newSegment.curvePoint = CGPoint(x: curvePoint.x + delta.x, y: curvePoint.y + delta.y)
        newSegment.controlPoint = CGPoint(x: controlPoint.x + delta.x, y: controlPoint.y + delta.y)
        newSegment.controlPoint1 = CGPoint(x: controlPoint1.x + delta.x, y: controlPoint1.y + delta.y)
        return newSegment
    }
}

extension ShapeType {
    var displayName: String {
        switch self {
        case .freehand:     return "Freehand"
        case .straightLine: return "Straight Line"
        case .rectangle:    return "Rectangle"
        case .circleArc:    return "Circle Arc"
        case .cubicBezier:  return "Cubic Bezier"
        case .text:         return "Text"
        }
    }
}
