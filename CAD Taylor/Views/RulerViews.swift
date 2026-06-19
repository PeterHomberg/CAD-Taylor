// ============================================
// File: RulerViews.swift
// Horizontal ruler, vertical ruler, corner square
// ============================================

import SwiftUI
import AppKit

// MARK: - Constants

private enum Ruler {
    static let thickness: CGFloat = 20       // ruler bar width/height in points
    static let background = NSColor(white: 0.92, alpha: 1)
    static let tickColor  = NSColor(white: 0.35, alpha: 1)
    static let textColor  = NSColor(white: 0.35, alpha: 1)
    static let cursorColor = NSColor.systemBlue
    static let font = NSFont.monospacedSystemFont(ofSize: 7, weight: .regular)
}

// MARK: - Corner square (top-left where rulers meet)

struct RulerCorner: View {
    var body: some View {
        Rectangle()
            .fill(Color(Ruler.background))
            .frame(width: Ruler.thickness, height: Ruler.thickness)
            .overlay(
                Rectangle()
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
    }
}

// MARK: - Horizontal ruler (top edge)

struct HRulerView: NSViewRepresentable {
    let canvasSize:  CGSize
    let zoomLevel:   CGFloat
    let cursorX:     CGFloat       // canvas coordinate
    let inMillimeters: Bool

    func makeNSView(context: Context) -> HRulerNSView {
        HRulerNSView()
    }

    func updateNSView(_ nsView: HRulerNSView, context: Context) {
        nsView.canvasSize    = canvasSize
        nsView.zoomLevel     = zoomLevel
        nsView.cursorX       = cursorX
        nsView.inMillimeters = inMillimeters
        nsView.needsDisplay  = true
    }
}

class HRulerNSView: NSView {
    var canvasSize:    CGSize  = .zero
    var zoomLevel:     CGFloat = 1.0
    var cursorX:       CGFloat = 0
    var inMillimeters: Bool    = true

    override func draw(_ dirtyRect: NSRect) {
        Ruler.background.setFill()
        bounds.fill()

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // NSScrollView pins its documentView to origin (0,0) — there is no
        // horizontal centering offset. The ruler's own bounds may be wider than
        // the canvas when the window is large, so we just start ticks at x=0.
        let canvasOriginX: CGFloat = 0

        drawTicks(ctx: ctx, canvasOriginX: canvasOriginX)
        drawCursorLine(ctx: ctx, canvasOriginX: canvasOriginX)
        drawBorder(ctx: ctx)
    }

    private func drawTicks(ctx: CGContext, canvasOriginX: CGFloat) {
        // Choose tick spacing in real units depending on zoom and unit system
        let (majorSpacingPts, minorDivisions) = tickSpacing()

        let majorStepPx = majorSpacingPts * zoomLevel
        guard majorStepPx > 0 else { return }

        let minorStepPx = majorStepPx / CGFloat(minorDivisions)

        // Range of canvas points visible
        let startPts = -canvasOriginX / zoomLevel
        let endPts   = (bounds.width - canvasOriginX) / zoomLevel

        // First major index to the left of visible area
        let firstMajor = floor(startPts / majorSpacingPts)

        var majorIndex = firstMajor
        while majorIndex * majorSpacingPts <= endPts {
            let majorCanvasX = majorIndex * majorSpacingPts
            let screenX = canvasOriginX + majorCanvasX * zoomLevel

            // Minor ticks
            for m in 1..<minorDivisions {
                let minorScreenX = screenX + CGFloat(m) * minorStepPx
                guard minorScreenX >= 0 && minorScreenX <= bounds.width else { continue }
                drawTick(ctx: ctx, x: minorScreenX, height: bounds.height * 0.3)
            }

            // Major tick + label
            guard screenX >= 0 && screenX <= bounds.width else {
                majorIndex += 1
                continue
            }
            drawTick(ctx: ctx, x: screenX, height: bounds.height * 0.6)

            let labelValue = inMillimeters
                ? CoordinateConverter.pointsToMillimeters(majorCanvasX)
                : majorCanvasX
            let labelText = formatLabel(labelValue)
            drawLabel(ctx: ctx, text: labelText, x: screenX + 2, y: 1)

            majorIndex += 1
        }
    }

    private func drawCursorLine(ctx: CGContext, canvasOriginX: CGFloat) {
        let screenX = canvasOriginX + cursorX * zoomLevel
        guard screenX >= 0 && screenX <= bounds.width else { return }

        ctx.setStrokeColor(Ruler.cursorColor.cgColor)
        ctx.setLineWidth(1.0)
        ctx.move(to: CGPoint(x: screenX, y: 0))
        ctx.addLine(to: CGPoint(x: screenX, y: bounds.height))
        ctx.strokePath()
    }

    private func drawBorder(ctx: CGContext) {
        ctx.setStrokeColor(NSColor.separatorColor.cgColor)
        ctx.setLineWidth(0.5)
        // Bottom edge only
        ctx.move(to: CGPoint(x: 0, y: 0))
        ctx.addLine(to: CGPoint(x: bounds.width, y: 0))
        ctx.strokePath()
    }

    private func drawTick(ctx: CGContext, x: CGFloat, height: CGFloat) {
        ctx.setStrokeColor(Ruler.tickColor.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: x, y: 0))
        ctx.addLine(to: CGPoint(x: x, y: height))
        ctx.strokePath()
    }

    private func drawLabel( ctx: CGContext, text: String, x: CGFloat, y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Ruler.font,
            .foregroundColor: Ruler.textColor
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        // Draw in flipped coords: NSView is flipped by default for AppKit text
        let size = str.size()
        str.draw(at: CGPoint(x: x, y: bounds.height - y - size.height))
    }
}

// MARK: - Vertical ruler (left edge)

struct VRulerView: NSViewRepresentable {
    let canvasSize:  CGSize
    let zoomLevel:   CGFloat
    let cursorY:     CGFloat       // canvas coordinate
    let inMillimeters: Bool

    func makeNSView(context: Context) -> VRulerNSView {
        VRulerNSView()
    }

    func updateNSView(_ nsView: VRulerNSView, context: Context) {
        nsView.canvasSize    = canvasSize
        nsView.zoomLevel     = zoomLevel
        nsView.cursorY       = cursorY
        nsView.inMillimeters = inMillimeters
        nsView.needsDisplay  = true
    }
}

class VRulerNSView: NSView {
    var canvasSize:    CGSize  = .zero
    var zoomLevel:     CGFloat = 1.0
    var cursorY:       CGFloat = 0
    var inMillimeters: Bool    = true

    override func draw(_ dirtyRect: NSRect) {
        Ruler.background.setFill()
        bounds.fill()

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // NSScrollView pins documentView to origin — no vertical centering offset.
        let canvasOriginY: CGFloat = 0

        drawTicks(ctx: ctx, canvasOriginY: canvasOriginY)
        drawCursorLine(ctx: ctx, canvasOriginY: canvasOriginY)
        drawBorder(ctx: ctx)
    }

    private func drawTicks(ctx: CGContext, canvasOriginY: CGFloat) {
        let (majorSpacingPts, minorDivisions) = tickSpacing()

        let majorStepPx = majorSpacingPts * zoomLevel
        guard majorStepPx > 0 else { return }

        let minorStepPx = majorStepPx / CGFloat(minorDivisions)

        // Canvas is flipped: canvas y=0 is at the TOP of the canvas rect.
        // A canvas point at canvasY maps to NSView screen coords as:
        //   screenY = bounds.height - canvasOriginY - canvasY * zoomLevel

        let startPts = -canvasOriginY / zoomLevel
        let endPts   = (bounds.height - canvasOriginY) / zoomLevel

        let firstMajor = floor(startPts / majorSpacingPts)

        var majorIndex = firstMajor
        while majorIndex * majorSpacingPts <= endPts {
            let majorCanvasY = majorIndex * majorSpacingPts
            // Convert flipped canvas Y to NSView screen Y
            let screenY = bounds.height - canvasOriginY - majorCanvasY * zoomLevel

            // Minor ticks (going downward in canvas = decreasing screenY)
            for m in 1..<minorDivisions {
                let minorScreenY = screenY - CGFloat(m) * minorStepPx
                guard minorScreenY >= 0 && minorScreenY <= bounds.height else { continue }
                drawTick(ctx: ctx, y: minorScreenY, width: bounds.width * 0.3)
            }

            guard screenY >= 0 && screenY <= bounds.height else {
                majorIndex += 1
                continue
            }
            drawTick(ctx: ctx, y: screenY, width: bounds.width * 0.6)

            let labelValue = inMillimeters
                ? CoordinateConverter.pointsToMillimeters(majorCanvasY)
                : majorCanvasY
            let labelText = formatLabel(labelValue)
            drawRotatedLabel(ctx: ctx, text: labelText, y: screenY - 2)

            majorIndex += 1
        }
    }

    private func drawCursorLine(ctx: CGContext, canvasOriginY: CGFloat) {
        let screenY = bounds.height - canvasOriginY - cursorY * zoomLevel
        guard screenY >= 0 && screenY <= bounds.height else { return }

        ctx.setStrokeColor(Ruler.cursorColor.cgColor)
        ctx.setLineWidth(1.0)
        ctx.move(to: CGPoint(x: 0,            y: screenY))
        ctx.addLine(to: CGPoint(x: bounds.width, y: screenY))
        ctx.strokePath()
    }

    private func drawBorder(ctx: CGContext) {
        ctx.setStrokeColor(NSColor.separatorColor.cgColor)
        ctx.setLineWidth(0.5)
        // Right edge only
        ctx.move(to: CGPoint(x: bounds.width, y: 0))
        ctx.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        ctx.strokePath()
    }

    private func drawTick(ctx: CGContext, y: CGFloat, width: CGFloat) {
        ctx.setStrokeColor(Ruler.tickColor.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: bounds.width - width, y: y))
        ctx.addLine(to: CGPoint(x: bounds.width,      y: y))
        ctx.strokePath()
    }

    /// Draw a short label rotated 90° counter-clockwise, right-aligned to the tick
    private func drawRotatedLabel( ctx: CGContext, text: String, y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Ruler.font,
            .foregroundColor: Ruler.textColor
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let size = str.size()

        ctx.saveGState()
        // Translate to the drawing origin, rotate, then draw
        ctx.translateBy(x: bounds.width - 2, y: y - size.width)
        ctx.rotate(by: .pi / 2)
        str.draw(at: .zero)
        ctx.restoreGState()
    }
}

// MARK: - Shared tick-spacing logic

/// Returns (majorSpacingInCanvasPoints, numberOfMinorDivisions)
/// Chooses a human-friendly spacing that keeps ticks ~40-80 px apart on screen.
private func tickSpacing(for zoomLevel: CGFloat = 1.0,
                          inMillimeters: Bool = true) -> (CGFloat, Int) {
    // Target: major ticks ~60 screen-pixels apart
    let targetPx: CGFloat = 60

    if inMillimeters {
        // Nice mm spacings: 1, 2, 5, 10, 20, 50, 100 …
        let niceStepsMM: [(CGFloat, Int)] = [
            (1,   5),
            (2,   4),
            (5,   5),
            (10,  5),
            (20,  4),
            (50,  5),
            (100, 5),
        ]
        for (mm, divs) in niceStepsMM {
            let pts = CoordinateConverter.millimetersToPoints(mm)
            if pts * zoomLevel >= targetPx {
                return (pts, divs)
            }
        }
        let pts = CoordinateConverter.millimetersToPoints(100)
        return (pts, 5)
    } else {
        // Nice pt/px spacings
        let niceStepsPts: [(CGFloat, Int)] = [
            (1,   1),
            (2,   2),
            (5,   5),
            (10,  5),
            (20,  4),
            (50,  5),
            (100, 5),
        ]
        for (pts, divs) in niceStepsPts {
            if pts * zoomLevel >= targetPx {
                return (pts, divs)
            }
        }
        return (100, 5)
    }
}

// Make tickSpacing available as an instance method on the NSView subclasses
extension HRulerNSView {
    func tickSpacing() -> (CGFloat, Int) {
        RulerViews_tickSpacing(zoomLevel: zoomLevel, inMillimeters: inMillimeters)
    }
}
extension VRulerNSView {
    func tickSpacing() -> (CGFloat, Int) {
        RulerViews_tickSpacing(zoomLevel: zoomLevel, inMillimeters: inMillimeters)
    }
}

// Rename the free function so it doesn't clash with the extension methods
private func RulerViews_tickSpacing(zoomLevel: CGFloat, inMillimeters: Bool) -> (CGFloat, Int) {
    let targetPx: CGFloat = 60

    if inMillimeters {
        let niceStepsMM: [(CGFloat, Int)] = [
            (1,  5), (2, 4), (5, 5), (10, 5), (20, 4), (50, 5), (100, 5)
        ]
        for (mm, divs) in niceStepsMM {
            let pts = CoordinateConverter.millimetersToPoints(mm)
            if pts * zoomLevel >= targetPx { return (pts, divs) }
        }
        return (CoordinateConverter.millimetersToPoints(100), 5)
    } else {
        let niceStepsPts: [(CGFloat, Int)] = [
            (1, 1), (2, 2), (5, 5), (10, 5), (20, 4), (50, 5), (100, 5)
        ]
        for (pts, divs) in niceStepsPts {
            if pts * zoomLevel >= targetPx { return (pts, divs) }
        }
        return (100, 5)
    }
}

private func formatLabel(_ value: CGFloat) -> String {
    if value == 0 { return "0" }
    // Show no decimal for whole numbers, one decimal otherwise
    return value.truncatingRemainder(dividingBy: 1) == 0
        ? String(format: "%.0f", value)
        : String(format: "%.1f", value)
}
