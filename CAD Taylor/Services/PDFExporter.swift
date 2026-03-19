// ============================================
// File: PDFExporter.swift
// PDF export functionality
// Single-page and multi-page tiled export
// ============================================

import AppKit
import CoreGraphics
import PDFKit

// MARK: - Page Layout


// MARK: - PDFExporter

class PDFExporter {
    private var context: CGContext
    private let pageSize: CGSize       // paper size used at init
    private let pageHeight: CGFloat
    private let pdfData = NSMutableData()
    private let marginMM = CGFloat(5)

    let pdfMetaData = [
        kCGPDFContextCreator: "SwiftUI Canvas Drawing",
        kCGPDFContextAuthor:  "Canvas App"
    ]

    /// pageSize is in PDF points (NSView / CoreGraphics native unit).
    init?(pageSize: CGSize) {
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        self.pageSize   = pageSize
        self.pageHeight = pageSize.height

        guard let dataConsumer = CGDataConsumer(data: pdfData),
              let ctx = CGContext(consumer: dataConsumer,
                                  mediaBox: &mediaBox,
                                  pdfMetaData as CFDictionary) else {
            return nil
        }
        self.context = ctx
        self.context.setStrokeColor(NSColor.black.cgColor)
        self.context.setLineWidth(3.0)
        self.context.setLineCap(.round)
        self.context.setLineJoin(.round)
    }

    // MARK: - Single-page primitives

    func beginPage() {
        context.beginPDFPage(nil)
        // PDF origin is bottom-left; canvas origin is top-left — flip Y axis.
        context.translateBy(x: 0, y: pageHeight)
        context.scaleBy(x: 1.0, y: -1.0)
    }

    func endPage() {
        context.endPDFPage()
    }

    func finish() -> Data {
        context.closePDF()
        return pdfData as Data
    }

    // MARK: - Single-page export

    func exportToPDF(shapes: [Shape]) -> Data {
        beginPage()
        drawShapes(shapes)
        endPage()
        return finish()
    }

    // MARK: - Multi-page export

    /// Exports the drawing tiled across multiple pages according to layout.
    /// Each page clips to its canvas region and draws cutting/alignment marks.
    func exportMultiPagePDF(shapes: [Shape], layout: PageLayout) -> Data {
        for row in 0..<layout.rows {
            for col in 0..<layout.columns {
                beginMultiPage(layout: layout, column: col, row: row)
                drawShapes(shapes)
                drawCuttingMarks(layout: layout, column: col, row: row)
                endMultiPage()
            }
        }
        return finish()
    }

    /// Begins a page clipped to the canvas region for [column, row].
    private func beginMultiPage(layout: PageLayout, column: Int, row: Int) {
        context.beginPDFPage(nil)

        // Flip Y axis (PDF = bottom-left, canvas = top-left)
        context.translateBy(x: 0, y: layout.paperSize.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // The canvas region this page covers
        let canvasRect = layout.canvasRect(column: column, row: row)

        // Clip to printable area (inside cutting mark margins)
        let printable = printableRect(paperSize: layout.paperSize)
        context.clip(to: printable)

        // Translate so this page's canvas origin maps to the printable area origin.
        // canvasRect.origin is the top-left corner of this page in canvas space.
        context.translateBy(
            x: -canvasRect.minX + printable.minX,
            y: -canvasRect.minY + printable.minY
        )
    }

    private func endMultiPage() {
        context.resetClip()
        context.endPDFPage()
    }

    // MARK: - Cutting and alignment marks

    private let markLength: CGFloat = CGFloat(8).pts   // 8 mm
    private let markOffset: CGFloat = CGFloat(3).pts   // 3 mm from edge
    private let markLineWidth: CGFloat = 0.3

    /// The printable area inside the cutting mark margins.
    private func printableRect(paperSize: CGSize) -> CGRect {
        let inset = markOffset + markLength
        return CGRect(
            x: inset,
            y: inset,
            width:  paperSize.width  - inset * 2,
            height: paperSize.height - inset * 2
        )
    }

    /// Draws corner cutting marks and a page label.
    /// Must be called AFTER endMultiPage resets the clip/transform.
    private func drawCuttingMarks(layout: PageLayout,
                                   column: Int, row: Int) {
        // Reset to page coordinate system (no canvas transform active here
        // because we call this before endMultiPage resets the clip but after
        // drawing shapes — so we save/restore state around it).
        context.saveGState()
        context.resetClip()

        // Undo the canvas translation so we draw in paper space
        // by saving gState before beginMultiPage's transforms — but since
        // we cannot do that here we reconstruct page coordinates directly.
        // Solution: draw marks in a fresh gState with identity transform
        // relative to the PDF page origin (bottom-left).
        let w = layout.paperSize.width
        let h = layout.paperSize.height
        let o = markOffset
        let l = markLength

        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(markLineWidth)
        context.setLineDash(phase: 0, lengths: [3, 2])
        context.setLineCap(.square)

        // Corner marks — in PDF space (Y up, origin bottom-left)
        // so top-left in PDF is (0, h), bottom-left is (0, 0)
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            // bottom-left (= top-left of page visually)
            (CGPoint(x: o,     y: o + l), CGPoint(x: o,     y: o), CGPoint(x: o + l, y: o)),
            // bottom-right
            (CGPoint(x: w-o-l, y: o),     CGPoint(x: w-o,   y: o), CGPoint(x: w-o,   y: o+l)),
            // top-left (= bottom-left of page visually)
            (CGPoint(x: o,     y: h-o-l), CGPoint(x: o,     y: h-o), CGPoint(x: o+l, y: h-o)),
            // top-right
            (CGPoint(x: w-o-l, y: h-o),   CGPoint(x: w-o,   y: h-o), CGPoint(x: w-o, y: h-o-l))
        ]

        for (a, corner, b) in corners {
            context.beginPath()
            context.move(to: a)
            context.addLine(to: corner)
            context.addLine(to: b)
            context.strokePath()
        }

        // Overlap indicator bands — shaded zone showing the glue area
        context.setLineDash(phase: 0, lengths: [])
        context.setFillColor(NSColor.gray.withAlphaComponent(0.12).cgColor)
        let ov = layout.overlap

        if column > 0 {
            // Left overlap band (in PDF Y-up space: x near 0, full height)
            context.fill(CGRect(x: o + l,
                                y: o + l,
                                width: ov,
                                height: h - (o + l) * 2))
        }
        if row > 0 {
            // Top overlap band (in PDF Y-up space: near top = large y)
            context.fill(CGRect(x: o + l,
                                y: h - o - l - ov,
                                width: w - (o + l) * 2,
                                height: ov))
        }

        // Page label — bottom-left corner inside mark zone
        let pageNumber = row * layout.columns + column + 1
        let label = "Page \(pageNumber)/\(layout.totalPages)  [\(column + 1)×\(row + 1)]"
        let attrs: [NSAttributedString.Key: Any] = [
            .font:            NSFont.systemFont(ofSize: 6),
            .foregroundColor: NSColor.gray
        ]
        let attrStr = NSAttributedString(string: label, attributes: attrs)
        // Draw in PDF space — y near bottom of page
        attrStr.draw(at: CGPoint(x: o + l + 2, y: o + 2))

        context.restoreGState()
    }

    // MARK: - Shape drawing (shared by single and multi-page)

    private func drawShapes(_ shapes: [Shape]) {
        for shape in shapes {
            context.saveGState()
            context.setStrokeColor(color(from: shape.color))
            context.setLineWidth(shape.width)
            context.setLineCap(.round)
            context.setLineJoin(.round)

            switch shape.type {

            case .freehand, .straightLine, .rectangle:
                guard shape.points.count > 1 else {
                    context.restoreGState()
                    continue
                }
                context.beginPath()
                context.move(to: shape.points[0])
                for point in shape.points.dropFirst() {
                    context.addLine(to: point)
                }
                if shape.type == .rectangle {
                    context.closePath()
                }
                context.strokePath()

            case .circleArc:
                guard shape.points.count == 3 else {
                    context.restoreGState()
                    continue
                }
                let (center, radius, startAngle, endAngle) =
                    Shape.arcParameters(from: shape.points)
                context.addArc(center: center, radius: radius,
                               startAngle: endAngle, endAngle: startAngle,
                               clockwise: false)
                context.strokePath()

            case .cubicBezier:
                guard shape.bezierSegments.count > 1 else {
                    context.restoreGState()
                    continue
                }
                context.beginPath()
                context.move(to: shape.bezierSegments[0].curvePoint)
                for i in 1..<shape.bezierSegments.count {
                    let end   = shape.bezierSegments[i]
                    let start = shape.bezierSegments[i - 1]
                    if end.controlPoint != .zero {
                        context.addCurve(
                            to:       end.curvePoint,
                            control1: start.controlPoint,
                            control2: start.controlPoint1
                        )
                    }
                }
                context.strokePath()

            case .text:
                break
            }

            context.restoreGState()
        }
    }

    // MARK: - Color helper

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

    // MARK: - Save dialogs

    /// Single-page save dialog (existing behaviour).
    func savePDFWithDialog(shapes: [Shape]) {
        let data = exportToPDF(shapes: shapes)
        saveWithDialog(data: data, filename: "canvas_drawing")
    }

    /// Multi-page save dialog.
    func saveMultiPagePDFWithDialog(shapes: [Shape], layout: PageLayout) {
        let data = exportMultiPagePDF(shapes: shapes, layout: layout)
        saveWithDialog(data: data, filename: "canvas_drawing_tiled_\(layout.columns)x\(layout.rows)")
    }

    private func saveWithDialog(data: Data, filename: String) {
        let savePanel = NSSavePanel()
        savePanel.title                 = "Save Canvas Drawing"
        savePanel.allowedContentTypes   = [.pdf]
        savePanel.nameFieldStringValue  = "\(filename)_\(Int(Date().timeIntervalSince1970)).pdf"
        savePanel.canCreateDirectories  = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            do {
                try data.write(to: url)
                print("PDF saved: \(url.lastPathComponent)")
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } catch {
                print("Error saving PDF: \(error)")
            }
        }
    }

    // MARK: - Open dialog

    static func openPDFWithDialog(completion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title                = "Open PDF File"
        openPanel.allowedContentTypes  = [.pdf]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false

        openPanel.begin { response in
            completion(response == .OK ? openPanel.url : nil)
        }
    }
}

// MARK: - Unit conversion extensions

extension CGFloat {
    /// Millimetres → PDF points (72 pt/inch, 25.4 mm/inch)
    var pts: CGFloat { self * 72.0 / 25.4 }
    /// PDF points → millimetres
    var mm:  CGFloat { self * 25.4 / 72.0 }
}

extension CGRect {
    /// Convenience init from millimetre values
    init(xMM x: CGFloat, yMM y: CGFloat,
         widthMM width: CGFloat, heightMM height: CGFloat) {
        self.init(x: x.pts, y: y.pts, width: width.pts, height: height.pts)
    }
}

extension CGPoint {
    var pts: CGPoint { CGPoint(x: x.pts, y: y.pts) }
}
