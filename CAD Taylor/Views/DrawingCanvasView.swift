// ============================================
// File: DrawingCanvasView.swift
// Main canvas view with drawing and selection functionality
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

    // UI state
    @State private var currentCoordinates = CGPoint.zero
    @State private var canvasSize = DrawingCanvasView.a4Size
    @State private var showCoordinates = true
    @State private var zoomLevel: CGFloat = 1.0
    @State private var mouseDownLocation: CGPoint?
    @Binding var showInMillimeters: Bool
    @StateObject var model = DrawingModel()

    // Scroll proxy for programmatic scrolling
    @State private var scrollProxy: ScrollViewProxy? = nil

    // Canvas auto-expansion
    private let expansionStep: CGFloat = 60
    private let edgeThreshold: CGFloat = 20

    // Print setup
    @State private var showPrintSetup = false
    @State private var selectedPaper: PaperSize = .a4

    
    var body: some View {
        HStack(spacing: 0) {

            // MARK: - Main canvas area
            VStack {
                ScrollViewReader { proxy in
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        ZStack {
                            // Background (shadow effect around A4 page)
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

                                DrawingView(
                                    model: model,
                                    shapes: shapes,
                                    canvasSize: $canvasSize,

                                    onMouseMoved: { location in
                                        currentCoordinates = model.coordinate
                                    },
                                    onMouseDown: { location in
                                        let adjusted = CGPoint(
                                            x: location.x / zoomLevel,
                                            y: location.y / zoomLevel
                                        )
                                        mouseDownLocation = adjusted
                                        handleMouseDown(at: adjusted)
                                    },
                                    onMouseDragged: { location in
                                        let adjusted = CGPoint(
                                            x: location.x / zoomLevel,
                                            y: location.y / zoomLevel
                                        )
                                        handleMouseDragged(at: adjusted)
                                    },
                                    onMouseUp: { location in
                                        let adjusted = CGPoint(
                                            x: location.x / zoomLevel,
                                            y: location.y / zoomLevel
                                        )
                                        handleMouseUp(at: adjusted)
                                    },
                                    onShapeCommitted: { shape in
                                        shapes.append(shape)
                                    },
                                    onEdgeReached: { direction in
                                        handleEdgeReached(direction)
                                    }
                                )

                                if let selectedID = selectedShapeID,
                                   let shape = shapes.first(where: { $0.id == selectedID }) {
                                    SelectionOverlay(shape: shape)
                                }
                            }
                            .frame(width: canvasSize.width, height: canvasSize.height)
                            .scaleEffect(zoomLevel)

                            // Scroll anchors
                            VStack {
                                HStack {
                                    Color.clear
                                        .frame(width: 1, height: 1)
                                        .id("canvasTopLeft")
                                    Spacer()
                                }
                                Spacer()
                                HStack {
                                    Spacer()
                                    Color.clear
                                        .frame(width: 1, height: 1)
                                        .id("canvasBottomRight")
                                }
                            }
                        }
                        // MARK: - ZStack end
                        .frame(
                            width: canvasSize.width * zoomLevel + 40,
                            height: canvasSize.height * zoomLevel + 40
                        )
                    }
                    // MARK: - ScrollView end
                    .onAppear { scrollProxy = proxy }
                }
                // MARK: - ScrollViewReader end
                .background(Color(NSColor.windowBackgroundColor))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // MARK: - Bottom toolbar
                HStack {
                    // Mode toggle buttons
                    HStack(spacing: 8) {
                        Button(action: { model.interactionMode = .draw }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Draw")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(model.interactionMode == .draw
                                        ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            model.interactionMode = .select
                            selectedShapeID = nil
                        }) {
                            HStack {
                                Image(systemName: "hand.point.up.left")
                                Text("Select")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(model.interactionMode == .select
                                        ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Divider()
                        .frame(height: 30)

                    Button("Clear Canvas") { clearCanvas() }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .foregroundColor(Color.white)
                        .cornerRadius(6)
                        .buttonStyle(PlainButtonStyle())

                    Button("Export PDF") { exportPDF() }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(Color.white)
                        .cornerRadius(6)
                        .buttonStyle(PlainButtonStyle())

                    if selectedShapeID != nil {
                        Button("Delete") { deleteSelectedShape() }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .foregroundColor(Color.white)
                            .cornerRadius(6)
                            .buttonStyle(PlainButtonStyle())
                    }
                    Button("Print Pages") { showPrintSetup = true }
                        .sheet(isPresented: $showPrintSetup) {
                            PrintSetupView(
                                canvasSize: canvasSize,
                                selectedPaper: $selectedPaper,
                                onExport: { layout in
                                    exportPDF()
                                    showPrintSetup = false
                                }
                            )
                        }

                    Spacer()

                    // Coordinates display
                    if showCoordinates {
                        let xFormatted = CoordinateConverter.formatCoordinate(
                            currentCoordinates.x, inMillimeters: showInMillimeters)
                        let yFormatted = CoordinateConverter.formatCoordinate(
                            currentCoordinates.y, inMillimeters: showInMillimeters)
                        let unit = CoordinateConverter.unitLabel(
                            inMillimeters: showInMillimeters)

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("X: \(xFormatted) \(unit), Y: \(yFormatted) \(unit) | Zoom: \(Int(zoomLevel * 100))%")
                                .font(.system(size: 14, design: .monospaced))

                            if let selectedID = selectedShapeID,
                               let shape = shapes.first(where: { $0.id == selectedID }) {
                                Text("Selected: \(shape.type.displayName)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.blue)
                            } else if model.interactionMode == .select {
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
                .padding()
            }
            // MARK: - VStack end
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)

            Divider()

            // MARK: - Right sidebar
            if model.interactionMode == .draw {
                DrawingToolbar(
                    shapes: $shapes,
                    showInMillimeters: $showInMillimeters,
                    model: model,
                    onCommitBezier: commitBezierShape
                )
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxHeight: .infinity)
            } else {
                EditToolbar(
                    editMode: $editMode,
                    shapes: $shapes,
                    selectedShapeID: $selectedShapeID,
                    showInMillimeters: $showInMillimeters,
                    hasSelection: selectedShapeID != nil
                )
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxHeight: .infinity)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear { }
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

    // MARK: - Edge Detection + Auto-Expand

    private func handleEdgeReached(_ direction: DrawingNSView.EdgeDirection) {
        guard model.interactionMode == .draw else { return }

        var newWidth  = canvasSize.width
        var newHeight = canvasSize.height
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0

        switch direction {
        case .right:
            newWidth += expansionStep
        case .bottom:
            newHeight += expansionStep
        case .left:
            offsetX = expansionStep
            newWidth += expansionStep
        case .top:
            offsetY = expansionStep
            newHeight += expansionStep
        }

        // Shift all existing shapes if canvas grows left or top
        if offsetX != 0 || offsetY != 0 {
            offsetAllShapes(dx: offsetX, dy: offsetY)
        }

        canvasSize = CGSize(width: newWidth, height: newHeight)

        // Scroll to follow the drawing direction — deferred so
        // the layout updates before the scroll fires
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.15)) {
                switch direction {
                case .right, .bottom:
                    scrollProxy?.scrollTo("canvasBottomRight",
                                          anchor: .bottomTrailing)
                case .left, .top:
                    scrollProxy?.scrollTo("canvasTopLeft",
                                          anchor: .topLeading)
                }
            }
        }
    }

    private func offsetAllShapes(dx: CGFloat, dy: CGFloat) {
        shapes = shapes.map { shape in
            var s = shape
            switch shape.geometry {
            case .points(let pts):
                s.points = pts.map {
                    CGPoint(x: $0.x + dx, y: $0.y + dy)
                }
            case .bezier(let segs):
                s.bezierSegments = segs.map { seg in
                    var seg = seg
                    seg.curvePoint    = CGPoint(x: seg.curvePoint.x    + dx,
                                                y: seg.curvePoint.y    + dy)
                    seg.controlPoint  = CGPoint(x: seg.controlPoint.x  + dx,
                                                y: seg.controlPoint.y  + dy)
                    seg.controlPoint1 = CGPoint(x: seg.controlPoint1.x + dx,
                                                y: seg.controlPoint1.y + dy)
                    return seg
                }
            }
            return s
        }
    }

    // MARK: - Mouse Event Handlers
    //
    //   mouseDown    = first contact, set start point
    //   mouseDragged = continuous update while button held
    //   mouseUp      = commit / finalise
    //
    //   Freehand    : down=start shape, drag=add points, up=commit shape
    //   StraightLine: down=set start, drag=update end preview, up=commit
    //   Square      : down=set start, drag=update corner preview, up=commit
    //   CircleArc   : down=add point (3 clicks total), drag ignored, up unused
    //   CubicBezier : handled inside DrawingNSView

    private func handleMouseDown(at location: CGPoint) {
        currentCoordinates = location
        switch model.interactionMode {
        case .draw:
            break
        case .select:
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
                originalShape = foundShape
            } else {
                selectedShapeID = nil
                dragStartPoint = nil
            }
        }
    }

    private func handleMouseDragged(at location: CGPoint) {
        currentCoordinates = location
        switch model.interactionMode {
        case .draw:
            break   // edge detection handled inside DrawingNSView
        case .select:
            guard dragStartPoint != nil else { return }
            if activeResizeHandle != nil {
                handleShapeResize(to: location)
            } else if editMode == .move {
                handleShapeMove(to: location)
            }
        }
    }

    private func handleMouseUp(at location: CGPoint) {
        switch model.interactionMode {
        case .draw:
            break
        case .select:
            dragStartPoint = nil
            originalShape = nil
            activeResizeHandle = nil
        }
        mouseDownLocation = nil
    }

    // MARK: - Shape Move / Resize

    private func handleShapeMove(to location: CGPoint) {
        guard let shapeID = selectedShapeID,
              let index = shapes.firstIndex(where: { $0.id == shapeID }),
              let startPoint = dragStartPoint,
              let original = originalShape else { return }

        let delta = CGPoint(
            x: location.x - startPoint.x,
            y: location.y - startPoint.y
        )

        switch original.geometry {
        case .bezier:
            shapes[index].bezierSegments = original.bezierSegments.map { seg in
                var s = seg
                s.curvePoint    = CGPoint(x: seg.curvePoint.x    + delta.x,
                                          y: seg.curvePoint.y    + delta.y)
                s.controlPoint  = CGPoint(x: seg.controlPoint.x  + delta.x,
                                          y: seg.controlPoint.y  + delta.y)
                s.controlPoint1 = CGPoint(x: seg.controlPoint1.x + delta.x,
                                          y: seg.controlPoint1.y + delta.y)
                return s
            }
        case .points:
            shapes[index].points = original.points.map { point in
                CGPoint(x: point.x + delta.x, y: point.y + delta.y)
            }
        }
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
        canvasSize = DrawingCanvasView.a4Size   // reset to A4 on clear
    }

    private func exportPDF() {
        guard let pdf = PDFExporter(pageSize: canvasSize) else {
            print("Konnte pdf nicht erstellen")
            return
        }
        let layout = PageLayout(paperSize: selectedPaper.size, canvasSize: canvasSize)
        pdf.saveMultiPagePDFWithDialog(shapes: shapes, layout: layout)
        //pdf.savePDFWithDialog(shapes: shapes)
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
        guard !model.bezierSegments.isEmpty else {
            print("commitBezierShape: model.bezierSegments is EMPTY — nothing to commit")
            return
        }
        let shape = Shape(type: .cubicBezier, bezierSegments: model.bezierSegments)
        shapes.append(shape)
        model.clear()
        model.clearTemporaryShape = true
        model.selectedDrawingMode = .freehand
    }
}

// MARK: - Shape Type Extension

extension ShapeType {
    var displayName: String {
        switch self {
        case .freehand:     return "Freehand"
        case .straightLine: return "Straight Line"
        case .rectangle:    return "Rectangle"
        case .circleArc:    return "Circle Arc"
        case .text:         return "Text"
        case .cubicBezier:  return "Cubic Bezier"
        }
    }
}
