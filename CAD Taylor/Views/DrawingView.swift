// ============================================
// File: DrawingView.swift
// Core Graphics rendering – ersetzt SwiftUI Path
// ============================================

import SwiftUI
import AppKit

// MARK: - SwiftUI-Wrapper (NSViewRepresentable)

struct DrawingView: NSViewRepresentable {
    @ObservedObject var model: DrawingModel

    let shapes: [Shape]
    let currentShape: Shape?
    let temporaryShape: TemporaryShape?
    @Binding var canvasSize: CGSize

    // callback for mouse move
    var onMouseMoved: ((CGPoint) -> Void)?
    var onMouseDown:    ((CGPoint) -> Void)?
    var onMouseDragged: ((CGPoint) -> Void)?
    var onMouseUp:      ((CGPoint) -> Void)?

    func makeNSView(context: Context) -> DrawingNSView {
        let view = DrawingNSView(bezierSegments: model.bezierSegments)
        view.shapes = shapes
        view.currentShape = currentShape
        view.temporaryShape = temporaryShape
        view.onMouseMoved = onMouseMoved
        view.onMouseDown    = onMouseDown
        view.onMouseDragged = onMouseDragged
        view.onMouseUp      = onMouseUp
        view.bezierMode = model.bezierMode
        // Push any NSView-side changes back to the model immediately,
        // so updateNSView never overwrites them with stale data.
        view.onSegmentsChanged = { [weak model] segments in
          model?.bezierSegments = segments
        }
             return view
    }

    func updateNSView(_ nsView: DrawingNSView, context: Context) {
        nsView.shapes = shapes
        nsView.currentShape = currentShape
        nsView.temporaryShape = temporaryShape
        nsView.onMouseMoved = onMouseMoved
        nsView.onMouseDown    = onMouseDown
        nsView.onMouseDragged = onMouseDragged
        nsView.onMouseUp      = onMouseUp
        
        nsView.isUpdatingFromModel = true
        if nsView.bezierSegments.count != model.bezierSegments.count {
            // Only sync when the model was changed externally (e.g. undo/clear),
            // not on every redraw triggered by the NSView itself.
            nsView.bezierSegments = model.bezierSegments
        }
        nsView.isUpdatingFromModel = false
        nsView.penMode = model.penMode
        nsView.bezierMode = model.bezierMode

        
        // Canvas-Größe synchronisieren
        DispatchQueue.main.async {
            let newSize = nsView.bounds.size
            if newSize != .zero, newSize != canvasSize {
                canvasSize = newSize
            }
        }

        nsView.needsDisplay = true
    }
}

// MARK: - Core Graphics NSView

class DrawingNSView: NSView {
    var oldCount = 0
    // Daten – bei Änderung needsDisplay setzen
    var shapes: [Shape] = [] { didSet { needsDisplay = true } }
    var currentShape: Shape?  { didSet { needsDisplay = true } }
    var temporaryShape: TemporaryShape? { didSet { needsDisplay = true } }

    // Transparenter Hintergrund (der weiße Canvas liegt darunter)
    override var isFlipped: Bool { true }   // Koordinatenursprung oben-links, Y wächst nach unten
    override var acceptsFirstResponder: Bool {true}
    
    // callback for mouse events
    var onMouseMoved: ((CGPoint) -> Void)?
    var onMouseDown:    ((CGPoint) -> Void)?
    var onMouseDragged: ((CGPoint) -> Void)?
    var onMouseUp:      ((CGPoint) -> Void)?
    
    // Bezier elements
    var bezierSegments: [BezierSegment] = []{
        didSet {
            if !isUpdatingFromModel {
                onSegmentsChanged?(bezierSegments)}
        }
    }
    var onSegmentsChanged: (([BezierSegment]) -> Void)?
    var lastMousePosition: CGPoint = .zero

    var isUpdatingFromModel = false
    var penMode: Bool = true
    var bezierMode: Bool = false
    init(bezierSegments: [BezierSegment]) {
        self.bezierSegments = bezierSegments
        super.init(frame: .zero)
    }
    // NSView also requires this initializer for Interface Builder / Storyboards
    required init?(coder: NSCoder) {
        self.bezierSegments = []
        super.init(coder: coder)
    }

    override func viewDidMoveToWindow() {
        window?.acceptsMouseMovedEvents = true
        becomeFirstResponder()
    }
    var hitPoint: HitResult? = nil

    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        onMouseMoved?(location)
    }
    // Click pressed down
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if bezierMode{
            if penMode == false {return}
            let location = convert(event.locationInWindow, from: nil)
            lastMousePosition = location
            print("Mouse down at: \(location)")
            hitPoint = hitTest(mousePosition: location)
            if let hit = hitPoint {
                switch hit {
                case.curvePoint(let index):
                    print("Hit curve point \(index)")
                case .controlPoint(let index):
                    print("Hit control point \(index)")
                case .controlPoint1(let index):
                    print("Hit control point1 \(index)")
                }
            } else {
                print("Hit nothing")
                let newBezierSegment = BezierSegment(curvePoint: lastMousePosition, controlPoint: .zero)
                bezierSegments.append(newBezierSegment)
                let cnt = bezierSegments.count
                if cnt > 1 {
                    bezierSegments[cnt-2].curvePoint1 = lastMousePosition
                }
            }

            needsDisplay = true

        }else { // back to DrawingCanvasView
            
            onMouseDown?(location)
        }
    }
    // Dragged while button held
    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if bezierMode {
            if penMode == false {return}

            let location = convert(event.locationInWindow, from: nil)
            //print("Dragging at: \(location)")
            lastMousePosition = location
            needsDisplay = true   // triggers draw(_:) again
            let cnt = bezierSegments.count
            if let hit = hitPoint {
                switch hit {
                case.curvePoint(let index):
                    bezierSegments[index].curvePoint = location
                    if bezierSegments.count > 1 {
                        bezierSegments[bezierSegments.count-2].curvePoint1 = location
                    }
                    //print("Hit curve point \(index)")
                case .controlPoint(let index):
                    bezierSegments[index].controlPoint=location
                    //print("Hit control point \(index)")
                case .controlPoint1(let index):
                    bezierSegments[index].controlPoint1 = location
                    print("Hit control point1 \(index)")
                }

            } else {
                if cnt > 0{
                    bezierSegments[cnt-1].controlPoint = lastMousePosition
                    if cnt > 1 {
                        let mirrorControlPoint = createMirrorControlPoint(curvePoint: bezierSegments[cnt-1].curvePoint,
                                                                          controlPoint: bezierSegments[cnt-1].controlPoint)
                        bezierSegments[cnt-2].controlPoint1 = mirrorControlPoint
                    }
                }
            }

        }else { // back to DrawingCanvasView
            onMouseDragged?(location)
        }
    }
    // Button released
    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        onMouseUp?(location)
    }
/*--------------------------------------------------------------------
    private func flipped(_ event: NSEvent) -> CGPoint {
        let p = convert(event.locationInWindow, from: nil)
        return CGPoint(x: p.x, y: bounds.height - p.y)
    }
----------------------------------------------------------------------*/
    // MARK: draw

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        if (bezierMode) {
            if bezierSegments.count != oldCount {
                print("bezierSegments.count: \(bezierSegments.count)")
                oldCount = bezierSegments.count
            }

            if penMode {
                for point in bezierSegments {
                    point.draw(ctx: ctx)
                }
            }
            if bezierSegments.count > 1 {
                drawBezierCurve(ctx: ctx)
            }

        }
        // -------------------------------------------------------
        // 1. Fertige Shapes
        // -------------------------------------------------------
        for shape in shapes {
            drawShape(shape, in: ctx)
        }

        // -------------------------------------------------------
        // 2. Aktuell in Bearbeitung
        // -------------------------------------------------------
        if let current = currentShape {
            drawShape(current, in: ctx)
        }

        // -------------------------------------------------------
        // 3. Temporäre Vorschau (straightLine / square / circleArc)
        // -------------------------------------------------------
        if let temp = temporaryShape {
            ctx.saveGState()
            ctx.setStrokeColor(NSColor.systemBlue.cgColor)
            ctx.setLineWidth(2.0)
            ctx.setLineDash(phase: 0, lengths: [6, 3])
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)

            if temp.mode == .square, let rect = temp.rect {
                ctx.stroke(rect)
            } else if temp.points.count > 1 {
                ctx.move(to: temp.points[0])
                for point in temp.points.dropFirst() {
                    ctx.addLine(to: point)
                }
                ctx.strokePath()
            }

            // Ankerpunkte als Kreise
            ctx.setLineDash(phase: 0, lengths: [])
            ctx.setFillColor(NSColor.white.cgColor)
            for point in temp.points {
                let r: CGFloat = 4
                let ellipse = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
                ctx.fillEllipse(in: ellipse)
                ctx.strokeEllipse(in: ellipse)
            }

            ctx.restoreGState()
        }
    }

    // MARK: - Shape zeichnen

    private func drawShape(_ shape: Shape, in ctx: CGContext) {
        guard !shape.points.isEmpty else { return }

        ctx.saveGState()

        // Farbe
        let strokeColor = color(from: shape.color)
        ctx.setStrokeColor(strokeColor)
        ctx.setLineWidth(shape.width)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        switch shape.type {

        case .freehand, .circleArc:
            guard shape.points.count > 1 else { break }
            ctx.move(to: shape.points[0])
            for point in shape.points.dropFirst() {
                ctx.addLine(to: point)
            }
            ctx.strokePath()

        case .straightLine:
            guard shape.points.count >= 2 else { break }
            ctx.move(to: shape.points[0])
            ctx.addLine(to: shape.points[shape.points.count - 1])
            ctx.strokePath()

        case .rectangle:
            guard shape.points.count >= 4 else { break }
            ctx.move(to: shape.points[0])
            for point in shape.points.dropFirst() {
                ctx.addLine(to: point)
            }
            ctx.closePath()
            ctx.strokePath()

        case .text:
            break  // noch nicht implementiert
        }

        ctx.restoreGState()
    }

    // MARK: - Hilfsmethoden

    /// Wandelt den gespeicherten Farb-String in CGColor um.
    private func color(from name: String) -> CGColor {
        switch name.lowercased() {
        case "red":    return NSColor.systemRed.cgColor
        case "green":  return NSColor.systemGreen.cgColor
        case "blue":   return NSColor.systemBlue.cgColor
        case "black":  return NSColor.black.cgColor
        case "white":  return NSColor.white.cgColor
        case "gray":   return NSColor.gray.cgColor
        default:       return NSColor.black.cgColor
        }
    }
    private func hitTest(mousePosition: CGPoint, threshold: CGFloat = 10) -> HitResult? {
        for(index,point) in bezierSegments.enumerated() {
            if mousePosition.distance(to: point.curvePoint) < threshold {
                return .curvePoint(index: index)
            }
            if point.controlPoint != .zero,
               mousePosition.distance(to: point.controlPoint) < threshold{
                return .controlPoint(index: index)
            }
            if point.controlPoint1 != .zero,
               mousePosition.distance(to: point.controlPoint1) < threshold{
                return .controlPoint1(index: index)
            }

        }
        return nil
    }
    private func createMirrorControlPoint(curvePoint: CGPoint, controlPoint: CGPoint) -> CGPoint {
        var mirroredControlPoint: CGPoint = .zero
        let helpSize = controlPoint - curvePoint
        mirroredControlPoint = CGPoint(x: curvePoint.x - helpSize.width,
                                       y: curvePoint.y - helpSize.height)
        return mirroredControlPoint
    }
    private func drawBezierCurve(ctx: CGContext) -> () {
        ctx.move(to: bezierSegments[0].curvePoint)
        for i in 1..<bezierSegments.count {
            let endPoint=bezierSegments[i]
            let startPoint = bezierSegments[i-1]
            if endPoint.controlPoint != .zero {
                ctx.addCurve(to: endPoint.curvePoint, control1: startPoint.controlPoint , control2: startPoint.controlPoint1)
            }
        }
        ctx.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.setLineWidth(2)
        ctx.strokePath()

    }


}
