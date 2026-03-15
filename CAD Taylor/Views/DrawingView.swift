// ============================================
// File: DrawingView.swift
// Core Graphics rendering – ersetzt SwiftUI Path
// ============================================

import SwiftUI
import AppKit

// MARK: - SwiftUI-Wrapper (NSViewRepresentable)

struct DrawingView: NSViewRepresentable {
    let shapes: [Shape]
    let currentShape: Shape?
    let temporaryShape: TemporaryShape?
    @Binding var canvasSize: CGSize

    // callback for mouse move
    var onMouseMoved: ((CGPoint) -> Void)?
    

    func makeNSView(context: Context) -> DrawingNSView {
        let view = DrawingNSView()
        view.shapes = shapes
        view.currentShape = currentShape
        view.temporaryShape = temporaryShape
        view.onMouseMoved = onMouseMoved
        return view
    }

    func updateNSView(_ nsView: DrawingNSView, context: Context) {
        nsView.shapes = shapes
        nsView.currentShape = currentShape
        nsView.temporaryShape = temporaryShape
        nsView.onMouseMoved = onMouseMoved

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

    // Daten – bei Änderung needsDisplay setzen
    var shapes: [Shape] = [] { didSet { needsDisplay = true } }
    var currentShape: Shape?  { didSet { needsDisplay = true } }
    var temporaryShape: TemporaryShape? { didSet { needsDisplay = true } }

    // Transparenter Hintergrund (der weiße Canvas liegt darunter)
    override var isFlipped: Bool { true }   // Koordinatenursprung oben-links, Y wächst nach unten
    override var acceptsFirstResponder: Bool {true}
    
    // callback for mouse move
    var onMouseMoved: ((CGPoint) -> Void)?
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let flipped = CGPoint(x: location.x, y: bounds.height - location.y)
        onMouseMoved?(flipped)
    }
    // MARK: draw

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

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
}
