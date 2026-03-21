// ============================================
// File: DrawingView.swift
// Core Graphics rendering
//
// Coordinate note:
// convert(event.locationInWindow, from: nil) returns points, not pixels.
// On macOS, AppKit always works in points (72 pt/inch), the same unit as
// PDF points. On Retina displays there are 2 pixels per point but NSView
// always gives you points. Raw pixels are only accessible via convertToBacking.
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

    func makeNSView(context: Context) -> DrawingNSView {
        let view = DrawingNSView(bezierSegments: model.bezierSegments)
        view.shapes              = shapes
        view.onMouseMoved        = onMouseMoved
        view.onMouseDown         = onMouseDown
        view.onMouseDragged      = onMouseDragged
        view.onMouseUp           = onMouseUp
        view.onShapeCommitted    = onShapeCommitted
        view.selectedDrawingMode = model.selectedDrawingMode
        view.interactionMode     = model.interactionMode
        view.onSegmentsChanged   = { [weak model] segments in
            model?.bezierSegments = segments
        }
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: DrawingNSView, context: Context) {
        nsView.shapes            = shapes
        nsView.onMouseMoved      = onMouseMoved
        nsView.onMouseDown       = onMouseDown
        nsView.onMouseDragged    = onMouseDragged
        nsView.onMouseUp         = onMouseUp

        nsView.isUpdatingFromModel = true
        if nsView.bezierSegments.count != model.bezierSegments.count {
            nsView.bezierSegments = model.bezierSegments
        }
        nsView.isUpdatingFromModel = false

        nsView.penMode             = model.penMode
        nsView.selectedDrawingMode = model.selectedDrawingMode
        nsView.interactionMode     = model.interactionMode

        if model.clearTemporaryShape {
            nsView.temporaryShape     = nil
            model.clearTemporaryShape = false
        }

        nsView.needsDisplay = true
    }
}

// MARK: - Core Graphics NSView

class DrawingNSView: NSView {
    weak var delegate: DrawingViewDelegate?
    var selectedDrawingMode: DrawingMode?
    var interactionMode: InteractionMode = .draw

    var shapes: [Shape] = []        { didSet { needsDisplay = true } }
    var temporaryShape: TemporaryShape? { didSet { needsDisplay = true } }

    var arcClickCount: Int = 0

    override var isFlipped: Bool         { true }
    override var acceptsFirstResponder: Bool { true }

    // MARK: Callbacks
    var onMouseMoved:     ((CGPoint) -> Void)?
    var onMouseDown:      ((CGPoint) -> Void)?
    var onMouseDragged:   ((CGPoint) -> Void)?
    var onMouseUp:        ((CGPoint) -> Void)?
    var onShapeCommitted: ((Shape)   -> Void)?

    // MARK: Bezier state
    var bezierSegments: [BezierSegment] = [] {
        didSet {
            if !isUpdatingFromModel {
                onSegmentsChanged?(bezierSegments)
            }
        }
    }
    var onSegmentsChanged: (([BezierSegment]) -> Void)?
    var lastMousePosition: CGPoint = .zero
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
        window?.acceptsMouseMovedEvents = true
        becomeFirstResponder()
    }

    // MARK: - Mouse moved

    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
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
    }

    // MARK: - Mouse down

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

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
                switch arcClickCount {
                case 1:
                    temporaryShape = TemporaryShape(mode: .circleArc, points: [location])
                case 2:
                    if let temp = temporaryShape {
                        temporaryShape?.points = [temp.points[0], location]
                    }
                case 3:
                    if temporaryShape!.points.count == 3 {
                        temporaryShape?.points[2] = location
                    } else {
                        temporaryShape?.points.append(location)
                    }
                    let shape = Shape(type: .circleArc, points: temporaryShape!.points)
                    onShapeCommitted?(shape)
                    temporaryShape = nil
                    arcClickCount = 0
                default:
                    break
                }

            case .square:
                temporaryShape = TemporaryShape(mode: .square, points: [location, location])

            case .cubicBezier:
                guard penMode else { return }
                lastMousePosition = location
                hitPoint = HitTesting.hitTestBezierPoints(
                    mousePosition: location, bezierSegments: bezierSegments)
                if hitPoint == nil {
                    let newSegment = BezierSegment(curvePoint: location, controlPoint: .zero)
                    bezierSegments.append(newSegment)
                    let cnt = bezierSegments.count
                    if cnt > 1 {
                        bezierSegments[cnt - 2].curvePoint1 = location
                    }
                    temporaryShape = TemporaryShape(mode: .cubicBezier,
                                                   bezierSegments: bezierSegments)
                }
                needsDisplay = true

            case .none:
                break
            }
        }

        if interactionMode == .select {
            onMouseDown?(location)
        }
    }

    // MARK: - Mouse dragged

    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        if interactionMode == .draw {
            switch selectedDrawingMode {
            case .straightLine, .square:
                if let temp = temporaryShape {
                    temporaryShape?.points = [temp.points[0], location]
                }

            case .some(.freehand):
                temporaryShape?.points.append(location)

            case .some(.circleArc):
                break

            case .some(.cubicBezier):
                guard penMode else { return }
                lastMousePosition = location
                needsDisplay = true
                let cnt = bezierSegments.count
                if let hit = hitPoint {
                    switch hit {
                    case .curvePoint(let index):
                        bezierSegments[index].curvePoint = location
                        if bezierSegments.count > 1 {
                            bezierSegments[bezierSegments.count - 2].curvePoint1 = location
                        }
                    case .controlPoint(let index):
                        bezierSegments[index].controlPoint = location
                    case .controlPoint1(let index):
                        bezierSegments[index].controlPoint1 = location
                    }
                } else {
                    if cnt > 0 {
                        bezierSegments[cnt - 1].controlPoint = lastMousePosition
                        if cnt > 1 {
                            let mirror = createMirrorControlPoint(
                                curvePoint:    bezierSegments[cnt - 1].curvePoint,
                                controlPoint:  bezierSegments[cnt - 1].controlPoint)
                            bezierSegments[cnt - 2].controlPoint1 = mirror
                        }
                    }
                }
                temporaryShape?.bezierSegments = bezierSegments

            case .none:
                break
            }
        }

        if interactionMode == .select {
            onMouseDragged?(location)
        }
    }

    // MARK: - Mouse up

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        if interactionMode == .draw {
            switch selectedDrawingMode {
            case .straightLine:
                if let temp = temporaryShape, temp.points.count == 2 {
                    var shape = Shape(type: .straightLine)
                    shape.points = temp.points
                    onShapeCommitted?(shape)
                    temporaryShape = nil
                }

            case .some(.freehand):
                if let temp = temporaryShape, temp.points.count > 0 {
                    var shape = Shape(type: .freehand)
                    shape.points = temp.points
                    onShapeCommitted?(shape)
                    temporaryShape = nil
                }

            case .some(.circleArc):
                break

            case .some(.square):
                if let temp = temporaryShape, temp.points.count == 2, let rect = temp.rect {
                    var shape = Shape(type: .rectangle)
                    shape.points = [
                        CGPoint(x: rect.minX, y: rect.minY),
                        CGPoint(x: rect.maxX, y: rect.minY),
                        CGPoint(x: rect.maxX, y: rect.maxY),
                        CGPoint(x: rect.minX, y: rect.maxY)
                    ]
                    onShapeCommitted?(shape)
                    temporaryShape = nil
                }

            case .some(.cubicBezier):
                break

            case .none:
                break
            }
        }

        if interactionMode == .select {
            onMouseUp?(location)
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        for shape in shapes {
            drawShape(shape, in: ctx)
        }

        if let temp = temporaryShape {
            drawTemporaryShape(ctx: ctx, temp: temp)
        }

        if penMode {
            for segment in bezierSegments {
                segment.draw(ctx: ctx)
            }
        }
        if bezierSegments.count > 1 {
            drawBezierCurve(segments: bezierSegments, ctx: ctx)
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
                let ellipse = CGRect(x: point.x - r, y: point.y - r,
                                     width: r * 2, height: r * 2)
                ctx.fillEllipse(in: ellipse)
                ctx.strokeEllipse(in: ellipse)
            }
            if temp.points.count == 2 {
                ctx.move(to: temp.points[0])
                ctx.addLine(to: temp.points[1])
                ctx.strokePath()
            }
            if temp.points.count == 3 {
                ctx.move(to: temp.points[0])
                ctx.addLine(to: temp.points[1])
                ctx.strokePath()
                ctx.move(to: temp.points[0])
                ctx.addLine(to: temp.points[2])
                ctx.strokePath()
                let (center, radius, startAngle, endAngle) =
                    Shape.arcParameters(from: temp.points)
                ctx.addArc(center: center, radius: radius,
                           startAngle: endAngle, endAngle: startAngle,
                           clockwise: false)
                ctx.strokePath()
            }

        case .square:
            if let rect = temp.rect { ctx.stroke(rect) }

        case .cubicBezier:
            if let segs = temporaryShape?.bezierSegments {
                if penMode {
                    for segment in segs { segment.draw(ctx: ctx) }
                }
                if segs.count > 1 {
                    drawBezierCurve(segments: segs, ctx: ctx)
                }
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
            ctx.addLine(to: shape.points[shape.points.count - 1])
            ctx.strokePath()

        case .rectangle:
            guard shape.points.count >= 4 else { break }
            ctx.move(to: shape.points[0])
            for point in shape.points.dropFirst() { ctx.addLine(to: point) }
            ctx.closePath()
            ctx.strokePath()

        case .circleArc:
            guard shape.points.count == 3 else { break }
            let (center, radius, startAngle, endAngle) =
                Shape.arcParameters(from: shape.points)
            ctx.addArc(center: center, radius: radius,
                       startAngle: endAngle, endAngle: startAngle,
                       clockwise: false)
            ctx.strokePath()

        case .cubicBezier:
            guard shape.bezierSegments.count > 1 else { break }
            drawBezierCurve(segments: shape.bezierSegments, ctx: ctx)

        case .text:
            break
        }

        ctx.restoreGState()
    }

    // MARK: - Helpers

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

    private func createMirrorControlPoint(curvePoint: CGPoint,
                                          controlPoint: CGPoint) -> CGPoint {
        let delta = controlPoint - curvePoint
        return CGPoint(x: curvePoint.x - delta.width,
                       y: curvePoint.y - delta.height)
    }

    private func drawBezierCurve(segments: [BezierSegment], ctx: CGContext) {
        ctx.move(to: segments[0].curvePoint)
        for i in 1..<segments.count {
            let end   = segments[i]
            let start = segments[i - 1]
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
