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
                context.restoreGState()
                let cuttingMarks = CuttingMarks(overlap: layout.overlap)
                cuttingMarks.draw(in: context, layout: layout, column: col, row: row, totalColumns: layout.columns, totalRows: layout.rows)
                // Pop Y-flip → back to raw PDF space
                context.restoreGState()

                context.endPDFPage()
                //endMultiPage()
            }
        }
        return finish()
    }

    /// Begins a page clipped to the canvas region for [column, row].
    private func beginMultiPage(layout: PageLayout, column: Int, row: Int) {
        
        context.beginPDFPage(nil)
        context.saveGState()
        // Flip Y axis (PDF = bottom-left, canvas = top-left)
        context.translateBy(x: 0, y: layout.paperSize.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // The canvas region this page covers
        let canvasRect = layout.canvasRect(column: column, row: row)
        print("canvasRect: \(canvasRect)")

        // Clip to printable area (inside cutting mark margins)
        let printable = layout.printableRect()
        context.saveGState()
        context.clip(to: printable)
        print("printable: \(printable)")
        print("translateBy: x:\(-canvasRect.minX + printable.minX)")

        // Translate so this page's canvas origin maps to the printable area origin.
        // canvasRect.origin is the top-left corner of this page in canvas space.
        context.translateBy(
            x: -canvasRect.minX + printable.minX,
            y: -canvasRect.minY + printable.minY
        )
    }

    private func endMultiPage() {
        context.resetClip()
        //context.restoreGState()
        context.endPDFPage()
    }

    struct CornerMark {
        let verticalEnd: CGPoint
        let vertex: CGPoint
        let horizontalEnd: CGPoint
        
        init(verticalEnd: CGPoint, vertex: CGPoint, horizontaEnd: CGPoint){
            self.verticalEnd = verticalEnd
            self.vertex = vertex
            self.horizontalEnd = horizontaEnd
        }
        
        func draw(ctx: CGContext) {
            ctx.move(to: verticalEnd)
            ctx.addLine(to: vertex)
            ctx.addLine(to: horizontalEnd)
            ctx.strokePath()
        }

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
