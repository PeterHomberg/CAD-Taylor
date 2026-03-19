// ============================================
// File: DrawingView.swift
// Core Graphics rendering – ersetzt SwiftUI Path
// ============================================

import SwiftUI
import AppKit

//MARK: -
/*
 
 The coordinates from convert(event.locationInWindow, from: nil) in NSView are in points, not pixels. On macOS, AppKit always works in points — the same unit as PDF points at 72 pt/inch.
 
 However — and this is the important part — on a non-Retina display points and pixels happen to be the same value (1:1 ratio). On a Retina display there are 2 pixels per point, but NSView still gives you points. You never see raw pixels in AppKit unless you explicitly ask for them via convertToBacking.
 
 
 */





protocol DrawingViewDelegate: AnyObject {
    func drawingView(_ drawingView: DrawingNSView,  newCoordinate: CGPoint)
}

// MARK: - SwiftUI-Wrapper (NSViewRepresentable)

struct DrawingView: NSViewRepresentable {
    @ObservedObject var model: DrawingModel
    
    
    // Coordinator to communicate NSView coordinates to SwiftUI views
    //**********************************************************************************************
    class ViewNSDelegate: NSObject, DrawingViewDelegate {
        var model: DrawingModel
        init(model: DrawingModel) {
            self.model = model
        }
        
        func drawingView(_ drawingView: DrawingNSView,  newCoordinate: CGPoint) {
            model.coordinate = newCoordinate
        }
        
    }
    func makeCoordinator() -> ViewNSDelegate {
        ViewNSDelegate(model: model)
    }
    
    
    
    
    
    
    
    
    //*************************************************************************************************
    let shapes: [Shape]
    @Binding var canvasSize: CGSize
    
    // callback for mouse move
    var onMouseMoved: ((CGPoint) -> Void)?
    var onMouseDown:    ((CGPoint) -> Void)?
    var onMouseDragged: ((CGPoint) -> Void)?
    var onMouseUp:      ((CGPoint) -> Void)?
    var onShapeCommitted: ((Shape) -> Void)?
    var onEdgeReached: ((DrawingNSView.EdgeDirection) -> Void)?

    func makeNSView(context: Context) -> DrawingNSView {
        let view = DrawingNSView(bezierSegments: model.bezierSegments)
        view.shapes = shapes
        view.onShapeCommitted = { shape in
            // This closure runs in DrawingCanvasView's context
        }
        view.onMouseMoved = onMouseMoved
        view.onMouseDown    = onMouseDown
        view.onMouseDragged = onMouseDragged
        view.onMouseUp      = onMouseUp
        view.selectedDrawingMode = model.selectedDrawingMode
        view.interactionMode = model.interactionMode
        view.onShapeCommitted = onShapeCommitted
        // Push any NSView-side changes back to the model immediately,
        // so updateNSView never overwrites them with stale data.
        view.onSegmentsChanged = { [weak model] segments in
            model?.bezierSegments = segments
        }
        view.delegate = context.coordinator
        view.onEdgeReached = onEdgeReached
        return view
    }
    
    func updateNSView(_ nsView: DrawingNSView, context: Context) {
        nsView.shapes = shapes
        // Only overwrite temporaryShape if we're not mid-arc-input
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
        nsView.selectedDrawingMode = model.selectedDrawingMode
        nsView.interactionMode = model.interactionMode
        
        if model.clearTemporaryShape {
            nsView.temporaryShape = nil
            model.clearTemporaryShape = false
        }
        // Canvas-Größe synchronisieren
        DispatchQueue.main.async {
            let newSize = nsView.bounds.size
            if newSize != .zero, newSize != canvasSize {
                canvasSize = newSize
            }
        }
        nsView.onEdgeReached = onEdgeReached
        nsView.needsDisplay = true
    }
}

// MARK: - Core Graphics NSView

class DrawingNSView: NSView {
    weak var delegate: DrawingViewDelegate?
    var selectedDrawingMode: DrawingMode?
    var interactionMode: InteractionMode = .draw
    var oldCount = 0
    var oldPoint: CGPoint = .zero
    // Daten – bei Änderung needsDisplay setzen
    var shapes: [Shape] = [] { didSet { needsDisplay = true } }
    var temporaryShape: TemporaryShape? { didSet { needsDisplay = true } }
    
    var arcClickCount: Int = 0
    // Transparenter Hintergrund (der weiße Canvas liegt darunter)
    override var isFlipped: Bool { true }   // Koordinatenursprung oben-links, Y wächst nach unten
    override var acceptsFirstResponder: Bool {true}
    
    //MARK: - callbacks
    var onMouseMoved: ((CGPoint) -> Void)?
    var onMouseDown:    ((CGPoint) -> Void)?
    var onMouseDragged: ((CGPoint) -> Void)?
    var onMouseUp:      ((CGPoint) -> Void)?
    var onShapeCommitted: ((Shape) -> Void)?
    
    //MARK: -  Edge detection
    var onEdgeReached: ((EdgeDirection) -> ())?
    let edgeThreshold: CGFloat = 20
    enum EdgeDirection {
        case right, bottom, left, top
    }
    // Clamps a point to the current view bounds
    private func clampToBounds(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: max(0, min(point.x, bounds.width)),
            y: max(0, min(point.y, bounds.height))
        )
    }
    // Checks if point is near an edge and fires callback
    private func checkEdge(_ point: CGPoint) {
        guard interactionMode == .draw else { return }

        if point.x >= bounds.width - edgeThreshold {
            onEdgeReached?(.right)
        }
        if point.y >= bounds.height - edgeThreshold {
            onEdgeReached?(.bottom)
        }
        if point.x <= edgeThreshold {
            onEdgeReached?(.left)
        }
        if point.y <= edgeThreshold {
            onEdgeReached?(.top)
        }
    }


    //MARK: -  Bezier elements
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
    //var bezierMode: Bool = false
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
        var location = convert(event.locationInWindow, from: nil)
        let shiftHeld = event.modifierFlags.contains(.shift)
        if interactionMode == .draw && shiftHeld{
            switch selectedDrawingMode {
            case .cubicBezier:
                if !bezierSegments.isEmpty {
                    // in the middle of drawing bezier curve
                    let rawlocation = convert(event.locationInWindow, from: nil)
                    checkEdge(rawlocation)                        // check before clamping
                    location = clampToBounds(rawlocation)     // clamp for drawing

                }
                break
            default:
                break
            }
        }
        /*
         if location != oldPoint {
         print("NSView mouseMoved: \(location)")
         oldPoint = location
         }
         */
        delegate?.drawingView(self, newCoordinate: location)
        if interactionMode == .draw {
            if temporaryShape?.points.count == 3 && temporaryShape?.mode == .circleArc{
                temporaryShape?.points[2] = location
                needsDisplay = true
            } else if temporaryShape?.mode == .circleArc && temporaryShape?.points.count == 2 {
                temporaryShape?.points.append(location)
                needsDisplay = true
            }
        }
            onMouseMoved?(location)
        
    }
    // Click pressed down
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if interactionMode == .draw {
            switch selectedDrawingMode{
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
                    //print("Circle Arc click 1: \(location)")
                case 2:
                    if let temp = temporaryShape {
                        temporaryShape?.points = [temp.points[0], location]
                    }
                    //print("Circle Arc click 2: \(location)")
                case 3:
                    // Replace the preview 3rd point with the actual click location
                    if temporaryShape!.points.count == 3 {
                        temporaryShape?.points[2] = location
                    } else {
                        temporaryShape?.points.append(location)
                    }
                    //print("Circle Arc click 3: \(location)")
                    let shape = Shape(type: .circleArc, points: temporaryShape!.points)
                    onShapeCommitted?(shape)
                    temporaryShape = nil
                    arcClickCount = 0   // reset for next arc
                default:
                    break
                } //switch arcClickCount
                
            case .square:
                temporaryShape = TemporaryShape(mode: .square, points: [location, location])
            case .cubicBezier:
                if penMode == false {return}
                let location = convert(event.locationInWindow, from: nil)
                lastMousePosition = location
                print("Mouse down at: \(location)")
                hitPoint = HitTesting.hitTestBezierPoints(mousePosition: location, bezierSegments: bezierSegments)
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
                    temporaryShape = TemporaryShape(mode: .cubicBezier, bezierSegments: bezierSegments)
                }
                
                needsDisplay = true
                
            case .none:
                break
            } // switch selectedDrawingMode
        }// if interactionMode == .draw
            onMouseDown?(location)
        
    }
    // Dragged while button held
    override func mouseDragged(with event: NSEvent) {
        let rawlocation = convert(event.locationInWindow, from: nil)
        checkEdge(rawlocation)                        // check before clamping
        let location = clampToBounds(rawlocation)     // clamp for drawing

        if interactionMode == .draw {
            //print("Mouse dragged  \(selectedDrawingMode ?? .freehand)")
            switch selectedDrawingMode{
            case .straightLine, .square:
                if let temp = temporaryShape {
                    temporaryShape?.points = [temp.points[0], location]
                    //print("Mouse Dragged   temp.points[0]: \(temp.points[0])  location: \(location)")
                }
            case .none:
                break
            case .some(.freehand):
                temporaryShape?.points.append(location)
                //print("Mouse Dragged .freehand  temp.points[0]: \(temporaryShape!)")
            case .some(.circleArc):
                break
            case .some(.cubicBezier):
                if penMode == false {return}
                
                //let location = convert(event.locationInWindow, from: nil) //this is most probably a bug
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
                            let mirrorControlPoint = createMirrorControlPoint(curvePoint: bezierSegments[cnt-1].curvePoint, controlPoint: bezierSegments[cnt-1].controlPoint)
                            bezierSegments[cnt-2].controlPoint1 = mirrorControlPoint
                        }
                    }
                }
                temporaryShape?.bezierSegments = bezierSegments
            }
        }
            onMouseDragged?(location)
    }
    // Button released
    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if interactionMode == .draw {
            switch selectedDrawingMode{
            case .straightLine:
                if let temp = temporaryShape, temp.points.count == 2 {
                    var shape = Shape(type: .straightLine)
                    shape.points = temp.points
                    onShapeCommitted?(shape)
                    temporaryShape = nil
                }
            case .none:
                break
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
            }
            
        }
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
        // -------------------------------------------------------
        // 1. Fertige Shapes
        // -------------------------------------------------------
        for shape in shapes {
            drawShape(shape, in: ctx)
        }
        // -------------------------------------------------------
        // 2. Temporary Shape
        // -------------------------------------------------------
        
        if let temp = temporaryShape {
            drawTemporaryShape(ctx: ctx, temp: temp)
        }
    }
    
    private func drawTemporaryShape(ctx: CGContext, temp: TemporaryShape) ->() {
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.systemBlue.cgColor)
        ctx.setLineWidth(2.0)
        ctx.setLineDash(phase: 0, lengths: [6, 3])
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        
        switch temp.mode {
        case .freehand, .straightLine:
            print("freehand points.count \(temp.points.count)")
            if temp.points.count > 1 {
                ctx.move(to: temp.points[0])
                for point in temp.points.dropFirst() {
                    ctx.addLine(to: point)
                }
                ctx.strokePath()
            }
            
        case .circleArc:
            ctx.setLineDash(phase: 0, lengths: [])
            ctx.setFillColor(NSColor.white.cgColor)
            for point in temp.points {
                let r: CGFloat = 4
                let ellipse = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
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
                ctx.addLine(to: temp.points[1])   // center → radius point
                ctx.strokePath()
                ctx.move(to: temp.points[0])
                ctx.addLine(to: temp.points[2])   // center → mouse point
                ctx.strokePath()
                let (center, radius, startAngle, endAngle) = Shape.arcParameters(from: temp.points)
                // Angles are computed in flipped screen space (Y down), but CGContext lives in
                // Y-up space. The Y-flip mirrors all angles, reversing the sweep direction.
                // Swapping start/end compensates, and clockwise:false then correctly draws
                // the short arc counter-clockwise from points[1] to points[2].
                ctx.addArc(center: center, radius: radius,
                           startAngle: endAngle, endAngle: startAngle,
                           clockwise: false)
                ctx.strokePath()
                
            }
            
            
        case .square:
            if let rect = temp.rect {
                ctx.stroke(rect)
            }
            
        case .cubicBezier:
            if let bezierSegs = temporaryShape?.bezierSegments {
                if penMode {
                    for point in bezierSegs {
                        point.draw(ctx: ctx)
                    }
                }
                if bezierSegs.count > 1 {
                    drawBezierCurve(segments: bezierSegs, ctx: ctx)
                }

            }
            
        }
        ctx.restoreGState()
        
    }
    /// Derives CGContext arc parameters from three points:
    ///   points[0] = center
    ///   points[1] = start of arc (defines radius and startAngle)
    ///   points[2] = end of arc (defines endAngle; mouse position)
    
    // MARK: - Shape zeichnen
    
    private func drawShape(_ shape: Shape, in ctx: CGContext) {
        
        
        ctx.saveGState()
        
        // Farbe
        let strokeColor = color(from: shape.color)
        ctx.setStrokeColor(strokeColor)
        ctx.setLineWidth(shape.width)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        
        switch shape.type {
            
        case .freehand:
            
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
        case .circleArc:
            guard shape.points.count == 3 else { break }
            let (center, radius, startAngle, endAngle) = Shape.arcParameters(from: shape.points)
            ctx.addArc(center: center, radius: radius,
                       startAngle: endAngle, endAngle: startAngle,
                       clockwise: false)
            ctx.strokePath()
        case .text:
            break  // noch nicht implementiert
        case .cubicBezier:
            //print("drawShape: entering cubicBezier case")
            guard shape.bezierSegments.count > 1 else {
                print("drawShape: not enough segments")
                break
            }
            drawBezierCurve(segments: shape.bezierSegments, ctx: ctx)
            
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
    private func drawBezierCurve(segments: [BezierSegment], ctx: CGContext) -> () {
        ctx.move(to: segments[0].curvePoint)
        for i in 1..<segments.count {
            let endPoint=segments[i]
            let startPoint = segments[i-1]
            if endPoint.controlPoint != .zero {
                ctx.addCurve(to: endPoint.curvePoint, control1: startPoint.controlPoint , control2: startPoint.controlPoint1)
            }
        }
        ctx.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.setLineWidth(2)
        ctx.strokePath()
        
    }
    
}
