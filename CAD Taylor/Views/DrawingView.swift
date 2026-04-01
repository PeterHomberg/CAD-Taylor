// ============================================
// File: DrawingView.swift
// Core Graphics rendering with Integrated NSScrollView
// GRID UPDATE: Passes GridSettings into DrawingNSView so it can
//              draw the grid overlay and apply snap inside mouse events.
// ============================================

import SwiftUI
import AppKit

protocol DrawingViewDelegate: AnyObject {
    func drawingView(_ drawingView: DrawingNSView, newCoordinate: CGPoint)
}

// MARK: - SwiftUI Wrapper

struct DrawingView: NSViewRepresentable {
    @ObservedObject var model: DrawingModel
    let shapes: [Shape]
    @Binding var canvasSize: CGSize
    @Binding var zoomLevel: CGFloat
    let selectedShapeID: UUID?
    let editMode: EditMode

    // MARK: Grid (NEW)
    let gridSettings: GridSettings

    var onMouseMoved:     ((CGPoint) -> Void)?
    var onMouseDown:      ((CGPoint) -> Void)?
    var onMouseDragged:   ((CGPoint) -> Void)?
    var onMouseUp:        ((CGPoint) -> Void)?
    var onShapeCommitted: ((Shape)   -> Void)?

    class ViewNSDelegate: NSObject, DrawingViewDelegate {
        var model: DrawingModel
        init(model: DrawingModel) { self.model = model }
        func drawingView(_ drawingView: DrawingNSView, newCoordinate: CGPoint) {
            model.coordinate = newCoordinate
        }
    }

    func makeCoordinator() -> ViewNSDelegate {
        ViewNSDelegate(model: model)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller   = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers    = true
        scrollView.drawsBackground       = true
        scrollView.backgroundColor       = NSColor.windowBackgroundColor
        scrollView.allowsMagnification   = true

        let drawingView = DrawingNSView(bezierSegments: model.bezierSegments)
        drawingView.frame = NSRect(origin: .zero, size: canvasSize)

        scrollView.documentView = drawingView
        configureDrawingView(drawingView, context: context)
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let drawingView = nsView.documentView as? DrawingNSView else { return }

        if drawingView.frame.size != canvasSize {
            drawingView.frame = NSRect(origin: .zero, size: canvasSize)
        }
        if nsView.magnification != zoomLevel {
            nsView.magnification = zoomLevel
        }

        drawingView.shapes       = shapes
        drawingView.onMouseMoved = onMouseMoved
        drawingView.onMouseDown  = onMouseDown
        drawingView.onMouseDragged = onMouseDragged
        drawingView.onMouseUp    = onMouseUp

        drawingView.isUpdatingFromModel = true
        if drawingView.bezierSegments.count != model.bezierSegments.count {
            drawingView.bezierSegments = model.bezierSegments
        }
        drawingView.isUpdatingFromModel = false

        drawingView.penMode             = model.penMode
        drawingView.selectedDrawingMode = model.selectedDrawingMode
        drawingView.interactionMode     = model.interactionMode
        drawingView.selectedShapeID     = selectedShapeID
        drawingView.selectedEditMode    = editMode

        // MARK: Grid (NEW) — forward current settings every update cycle
        drawingView.gridSettings = gridSettings

        if model.clearTemporaryShape {
            drawingView.temporaryShape    = nil
            model.clearTemporaryShape     = false
        }

        drawingView.needsDisplay = true
    }

    private func configureDrawingView(_ view: DrawingNSView, context: Context) {
        view.onMouseMoved        = onMouseMoved
        view.onMouseDown         = onMouseDown
        view.onMouseDragged      = onMouseDragged
        view.onMouseUp           = onMouseUp
        view.onShapeCommitted    = onShapeCommitted
        view.selectedDrawingMode = model.selectedDrawingMode
        view.interactionMode     = model.interactionMode
        view.gridSettings        = gridSettings          // MARK: Grid (NEW)
        view.onSegmentsChanged   = { [weak model] segments in
            model?.bezierSegments = segments
        }
        view.delegate = context.coordinator
    }
}

// MARK: - Core Graphics NSView

class DrawingNSView: NSView {
    weak var delegate: DrawingViewDelegate?
    var selectedDrawingMode: DrawingMode?
    var interactionMode: InteractionMode = .draw

    var shapes: [Shape] = []            { didSet { needsDisplay = true } }
    var temporaryShape: TemporaryShape? { didSet { needsDisplay = true } }
    var selectedShapeID: UUID?          { didSet { needsDisplay = true } }
    var selectedEditMode: EditMode = .move { didSet { needsDisplay = true } }

    // MARK: Grid (NEW)
    var gridSettings: GridSettings = GridSettings() { didSet { needsDisplay = true } }

    var arcClickCount: Int = 0

    override var isFlipped: Bool          { true }
    override var acceptsFirstResponder: Bool { true }

    var onMouseMoved:     ((CGPoint) -> Void)?
    var onMouseDown:      ((CGPoint) -> Void)?
    var onMouseDragged:   ((CGPoint) -> Void)?
    var onMouseUp:        ((CGPoint) -> Void)?
    var onShapeCommitted: ((Shape)   -> Void)?

    private var dragStartedInside = false

    var bezierSegments: [BezierSegment] = [] {
        didSet {
            if !isUpdatingFromModel { onSegmentsChanged?(bezierSegments) }
        }
    }
    var onSegmentsChanged: (([BezierSegment]) -> Void)?
    var lastMousePosition: CGPoint = .zero
    var showCrosshair: Bool = false
    var isUpdatingFromModel = false
    var penMode: Bool = true
    var hitPoint: HitResult? = nil

    init(bezierSegments: [BezierSegment]) {
        self.bezierSegments = bezierSegments
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        self.bezierSegments = []
        super.init(coder: coder)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateTrackingAreas()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited,
                      .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    // MARK: - Mouse Events

    override func mouseEntered(with event: NSEvent) {
        showCrosshair = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        showCrosshair = false
        needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        lastMousePosition = location
        delegate?.drawingView(self, newCoordinate: location)

        if interactionMode == .draw {
            if temporaryShape?.points.count == 3 && temporaryShape?.mode == .circleArc {
                temporaryShape?.points[2] = location
                needsDisplay = true
            } else if temporaryShape?.mode == .circleArc && temporaryShape?.points.count == 2 {
                temporaryShape?.points.append(location)
                needsDisplay = true
            }
        }
        onMouseMoved?(location)
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        let raw = convert(event.locationInWindow, from: nil)
        // MARK: Grid (NEW) — snap before forwarding to draw logic
        let location = gridSettings.snap(raw)

        dragStartedInside = true

        if interactionMode == .draw {
            switch selectedDrawingMode {
            case .straightLine:
                temporaryShape = TemporaryShape(mode: .straightLine, points: [location, location])
            case .freehand:
                var temp = TemporaryShape(mode: .freehand)
                temp.points.append(location)
                temporaryShape = temp
            case .circleArc:
                arcClickCount += 1
                handleArcClick(at: location)
            case .square:
                temporaryShape = TemporaryShape(mode: .square, points: [location, location])
            case .cubicBezier:
                handleBezierMouseDown(at: location)
            case .none:
                break
            }
        }

        if interactionMode == .select {
            onMouseDown?(location)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragStartedInside else { return }
        let raw = convert(event.locationInWindow, from: nil)
        // MARK: Grid (NEW) — snap drag position
        let location = gridSettings.snap(raw)

        lastMousePosition = location
        onMouseMoved?(location)

        if interactionMode == .draw {
            switch selectedDrawingMode {
            case .straightLine, .square:
                if let temp = temporaryShape {
                    temporaryShape?.points = [temp.points[0], location]
                }
            case .some(.freehand):
                // Freehand intentionally not snapped — it would ruin the stroke
                temporaryShape?.points.append(raw)
            case .some(.cubicBezier):
                handleBezierMouseDragged(at: location)
            default:
                break
            }
        }

        if interactionMode == .select {
            onMouseDragged?(location)
        }
    }

    override func mouseUp(with event: NSEvent) {
        defer { dragStartedInside = false }
        guard dragStartedInside else { return }
        let raw = convert(event.locationInWindow, from: nil)
        // MARK: Grid (NEW) — snap the commit point
        let location = gridSettings.snap(raw)

        if interactionMode == .draw {
            commitTemporaryShape(snappedLocation: location)
        }

        if interactionMode == .select {
            onMouseUp?(location)
        }
    }

    // MARK: - Drawing Logic

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        dirtyRect.fill()

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // MARK: Grid (NEW) — draw grid first so it sits behind all shapes
        if gridSettings.isVisible {
            drawGrid(ctx: ctx)
        }

        for shape in shapes {
            drawShape(shape, in: ctx)
        }

        if let temp = temporaryShape {
            drawTemporaryShape(ctx: ctx, temp: temp)
        }

        if let selectedID = selectedShapeID,
           let shape = shapes.first(where: { $0.id == selectedID }) {
            drawSelectionOverlay(shape: shape, in: ctx)
        }

        if penMode {
            for segment in bezierSegments {
                segment.draw(ctx: ctx)
            }
        }
        if bezierSegments.count > 1 {
            drawBezierCurve(segments: bezierSegments, ctx: ctx)
        }

        if showCrosshair {
            drawCrosshair(ctx: ctx, at: lastMousePosition)
        }
    }

    // MARK: - Grid rendering (NEW)

    /// Draws a dot-grid (or line-grid) using the current GridSettings.
    /// Called from draw(_:) before any shapes are rendered.
    private func drawGrid(ctx: CGContext) {
        ctx.saveGState()

        let spacing = gridSettings.spacingPts
        guard spacing > 1 else {
            ctx.restoreGState()
            return
        }

        let w = bounds.width
        let h = bounds.height

        // Draw subtle dots at every grid intersection.
        // Dots are less visually distracting than full grid lines
        // but still give clear snap targets.
        ctx.setFillColor(NSColor.systemGray.withAlphaComponent(0.35).cgColor)
        let dotRadius: CGFloat = 0.8

        var x: CGFloat = 0
        while x <= w {
            var y: CGFloat = 0
            while y <= h {
                let dot = CGRect(x: x - dotRadius, y: y - dotRadius,
                                 width: dotRadius * 2, height: dotRadius * 2)
                ctx.fillEllipse(in: dot)
                y += spacing
            }
            x += spacing
        }

        ctx.restoreGState()
    }

    // MARK: - Internal Handlers

    private func drawCrosshair(ctx: CGContext, at point: CGPoint) {
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(0.5)
        ctx.setLineDash(phase: 0, lengths: [4, 3])
        ctx.move(to: CGPoint(x: 0,            y: point.y))
        ctx.addLine(to: CGPoint(x: bounds.width, y: point.y))
        ctx.move(to: CGPoint(x: point.x, y: 0))
        ctx.addLine(to: CGPoint(x: point.x, y: bounds.height))
        ctx.strokePath()
        ctx.restoreGState()
    }

    private func handleArcClick(at location: CGPoint) {
        switch arcClickCount {
        case 1:
            temporaryShape = TemporaryShape(mode: .circleArc, points: [location])
        case 2:
            if let temp = temporaryShape { temporaryShape?.points = [temp.points[0], location] }
        case 3:
            if var temp = temporaryShape {
                if temp.points.count == 3 { temp.points[2] = location }
                else { temp.points.append(location) }
                onShapeCommitted?(Shape(type: .circleArc, points: temp.points))
            }
            temporaryShape = nil
            arcClickCount  = 0
        default: break
        }
    }

    private func handleBezierMouseDown(at location: CGPoint) {
        guard penMode else { return }
        lastMousePosition = location
        hitPoint = HitTesting.hitTestBezierPoints(mousePosition: location, bezierSegments: bezierSegments)
        if hitPoint == nil {
            let newSegment = BezierSegment(curvePoint: location, controlPoint: .zero)
            bezierSegments.append(newSegment)
            if bezierSegments.count > 1 {
                bezierSegments[bezierSegments.count - 2].curvePoint1 = location
            }
            temporaryShape = TemporaryShape(mode: .cubicBezier, bezierSegments: bezierSegments)
        }
        needsDisplay = true
    }

    private func handleBezierMouseDragged(at location: CGPoint) {
        guard penMode else { return }
        lastMousePosition = location
        let cnt = bezierSegments.count
        if let hit = hitPoint {
            updateBezierHitPoint(hit, to: location)
        } else if cnt > 0 {
            bezierSegments[cnt - 1].controlPoint = lastMousePosition
            if cnt > 1 {
                let mirror = createMirrorControlPoint(
                    curvePoint: bezierSegments[cnt - 1].curvePoint,
                    controlPoint: bezierSegments[cnt - 1].controlPoint
                )
                bezierSegments[cnt - 2].controlPoint1 = mirror
            }
        }
        temporaryShape?.bezierSegments = bezierSegments
        needsDisplay = true
    }

    private func updateBezierHitPoint(_ hit: HitResult, to location: CGPoint) {
        switch hit {
        case .curvePoint(let index):
            let delta = CGPoint(
                x: location.x - bezierSegments[index].curvePoint.x,
                y: location.y - bezierSegments[index].curvePoint.y
            )
            // Move the curve point itself
            bezierSegments[index].curvePoint = location
/*
            // curvePoint1 is the anchor on the same segment used by draw() to
            // paint the dashed line to controlPoint1 — it must follow the drag
            if bezierSegments[index].curvePoint1 != .zero {
                bezierSegments[index].curvePoint1 = CGPoint(
                    x: bezierSegments[index].curvePoint1.x + delta.x,
                    y: bezierSegments[index].curvePoint1.y + delta.y
                )
            }
 */

            // The previous segment stores this curvePoint as its own curvePoint1
            // (the right-hand anchor for its handle line) — keep it in sync
            if index > 0 {
                bezierSegments[index - 1].curvePoint1 = location
            }

            // Shift the control points so handles keep their relative offset
            if bezierSegments[index].controlPoint != .zero {
                bezierSegments[index].controlPoint = CGPoint(
                    x: bezierSegments[index].controlPoint.x + delta.x,
                    y: bezierSegments[index].controlPoint.y + delta.y
                )
            }
            if bezierSegments[index].controlPoint1 != .zero {
                bezierSegments[index].controlPoint1 = CGPoint(
                    x: bezierSegments[index].controlPoint1.x + delta.x,
                    y: bezierSegments[index].controlPoint1.y + delta.y
                )
            }

        case .controlPoint(let index):  bezierSegments[index].controlPoint  = location
        case .controlPoint1(let index): bezierSegments[index].controlPoint1 = location
        }
    }

    /// mouseUp passes the already-snapped location here so the committed shape
    /// has its final point on a grid intersection.
    private func commitTemporaryShape(snappedLocation: CGPoint) {
        guard let temp = temporaryShape else { return }
        switch temp.mode {
        case .straightLine where temp.points.count == 2:
            // Replace the end point with the snapped position
            let pts = [temp.points[0], snappedLocation]
            onShapeCommitted?(Shape(type: .straightLine, points: pts))
        case .freehand where !temp.points.isEmpty:
            onShapeCommitted?(Shape(type: .freehand, points: temp.points))
        case .square where temp.rect != nil:
            let r = temp.rect!
            let pts = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                       CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]
            onShapeCommitted?(Shape(type: .rectangle, points: pts))
        default: break
        }
        temporaryShape = nil
    }

    private func drawSelectionOverlay(shape: Shape, in ctx: CGContext) {
        ctx.saveGState()
        let box = shape.boundingBox
        ctx.setStrokeColor(NSColor.systemBlue.cgColor)
        ctx.setLineWidth(2)
        ctx.setLineDash(phase: 0, lengths: [5, 3])
        ctx.stroke(box)
        ctx.setLineDash(phase: 0, lengths: [])

        switch shape.type {
        case .rectangle:
            let handlePoints: [CGPoint] = [
                CGPoint(x: box.minX, y: box.minY), CGPoint(x: box.maxX, y: box.minY),
                CGPoint(x: box.maxX, y: box.maxY), CGPoint(x: box.minX, y: box.maxY),
                CGPoint(x: box.midX, y: box.minY), CGPoint(x: box.maxX, y: box.midY),
                CGPoint(x: box.midX, y: box.maxY), CGPoint(x: box.minX, y: box.midY),
            ]
            drawHandles(at: handlePoints, color: NSColor.systemBlue.cgColor, size: 10, in: ctx)
        case .straightLine:
            if shape.points.count >= 2 {
                drawHandles(at: [shape.points.first!, shape.points.last!],
                            color: NSColor.systemBlue.cgColor, size: 10, in: ctx)
            }
        case .circleArc:
            drawHandles(at: shape.points, color: NSColor.orange.cgColor, size: 8, in: ctx)
        case .cubicBezier:
            if selectedEditMode == .resize {
                for segment in shape.bezierSegments { segment.draw(ctx: ctx) }
            }
        default:
            break
        }
        ctx.restoreGState()
    }

    private func drawHandles(at points: [CGPoint], color: CGColor, size: CGFloat, in ctx: CGContext) {
        let r = size / 2
        for point in points {
            let rect = CGRect(x: point.x - r, y: point.y - r, width: size, height: size)
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: rect)
            ctx.setStrokeColor(color)
            ctx.setLineWidth(2)
            ctx.strokeEllipse(in: rect)
        }
    }

    private func drawTemporaryShape(ctx: CGContext, temp: TemporaryShape) {
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemBlue.cgColor)
        ctx.setLineWidth(2.0)
        ctx.setLineDash(phase: 0, lengths: [6, 3])
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        switch temp.mode {
        case .freehand, .straightLine:
            guard temp.points.count > 1 else { break }
            ctx.move(to: temp.points[0])
            for point in temp.points.dropFirst() { ctx.addLine(to: point) }
            ctx.strokePath()
        case .circleArc:
            ctx.setLineDash(phase: 0, lengths: [])
            ctx.setFillColor(NSColor.white.cgColor)
            for point in temp.points {
                let r: CGFloat = 4
                let ellipse = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
                ctx.fillEllipse(in: ellipse)
                ctx.strokeEllipse(in: ellipse)
            }
            if temp.points.count == 3 {
                let (center, radius, startAngle, endAngle) = Shape.arcParameters(from: temp.points)
                ctx.addArc(center: center, radius: radius,
                           startAngle: endAngle, endAngle: startAngle, clockwise: false)
                ctx.strokePath()
            }
        case .square:
            if let rect = temp.rect { ctx.stroke(rect) }
        case .cubicBezier:
            if let segs = temporaryShape?.bezierSegments {
                if penMode { for segment in segs { segment.draw(ctx: ctx) } }
                if segs.count > 1 { drawBezierCurve(segments: segs, ctx: ctx) }
            }
        }
        ctx.restoreGState()
    }

    private func drawShape(_ shape: Shape, in ctx: CGContext) {
        ctx.saveGState()
        ctx.setStrokeColor(color(from: shape.color))
        ctx.setLineWidth(shape.width)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        switch shape.type {
        case .freehand:
            guard shape.points.count > 1 else { break }
            ctx.move(to: shape.points[0])
            for point in shape.points.dropFirst() { ctx.addLine(to: point) }
            ctx.strokePath()
        case .straightLine:
            guard shape.points.count >= 2 else { break }
            ctx.move(to: shape.points[0])
            ctx.addLine(to: shape.points.last!)
            ctx.strokePath()
        case .rectangle:
            guard shape.points.count >= 4 else { break }
            ctx.move(to: shape.points[0])
            for point in shape.points.dropFirst() { ctx.addLine(to: point) }
            ctx.closePath()
            ctx.strokePath()
        case .circleArc:
            guard shape.points.count == 3 else { break }
            let (center, radius, startAngle, endAngle) = Shape.arcParameters(from: shape.points)
            ctx.addArc(center: center, radius: radius,
                       startAngle: endAngle, endAngle: startAngle, clockwise: false)
            ctx.strokePath()
        case .cubicBezier:
            guard shape.bezierSegments.count > 1 else { break }
            drawBezierCurve(segments: shape.bezierSegments, ctx: ctx)
        case .text: break
        }
        ctx.restoreGState()
    }

    private func color(from name: String) -> CGColor {
        switch name.lowercased() {
        case "red":   return NSColor.systemRed.cgColor
        case "green": return NSColor.systemGreen.cgColor
        case "blue":  return NSColor.systemBlue.cgColor
        case "white": return NSColor.white.cgColor
        case "gray":  return NSColor.gray.cgColor
        default:      return NSColor.black.cgColor
        }
    }

    private func createMirrorControlPoint(curvePoint: CGPoint, controlPoint: CGPoint) -> CGPoint {
        let delta = CGSize(width: controlPoint.x - curvePoint.x,
                           height: controlPoint.y - curvePoint.y)
        return CGPoint(x: curvePoint.x - delta.width, y: curvePoint.y - delta.height)
    }

    private func drawBezierCurve(segments: [BezierSegment], ctx: CGContext) {
        ctx.move(to: segments[0].curvePoint)
        for i in 1..<segments.count {
            let end = segments[i]; let start = segments[i - 1]
            if end.controlPoint != .zero {
                ctx.addCurve(to: end.curvePoint,
                             control1: start.controlPoint,
                             control2: start.controlPoint1)
            }
        }
        ctx.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.setLineWidth(2)
        ctx.strokePath()
    }
}
