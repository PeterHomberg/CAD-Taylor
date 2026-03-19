//
//  PageLayout.swift
//  CAD Taylor
//
//  Created by Peter Homberg on 3/19/26.
//

import Foundation
import SwiftUI

/// Describes how a canvas is divided into printable pages.
struct PageLayout {
    let paperSize: CGSize     // paper size in PDF points
    let canvasSize: CGSize    // full drawing canvas in PDF points
    let overlap: CGFloat      // overlap between adjacent pages in pts (for gluing)

    init(paperSize: CGSize, canvasSize: CGSize, overlap: CGFloat = CGFloat(10).pts) {
        self.paperSize  = paperSize
        self.canvasSize = canvasSize
        self.overlap    = overlap
    }

    /// Number of pages horizontally
    var columns: Int {
        Int(ceil(canvasSize.width  / (paperSize.width  - overlap)))
    }

    /// Number of pages vertically
    var rows: Int {
        Int(ceil(canvasSize.height / (paperSize.height - overlap)))
    }

    var totalPages: Int { columns * rows }

    /// The region of the canvas that maps to page [column, row].
    func canvasRect(column: Int, row: Int) -> CGRect {
        let x = CGFloat(column) * (paperSize.width  - overlap)
        let y = CGFloat(row)    * (paperSize.height - overlap)
        return CGRect(x: x, y: y, width: paperSize.width, height: paperSize.height)
    }
}

// MARK: - Paper Sizes

enum PaperSize: String, CaseIterable {
    case a4     = "A4"
    case a3     = "A3"
    case a2     = "A2"
    case letter = "Letter"

    var size: CGSize {
        switch self {
        case .a4:     return CGSize(width: CGFloat(210).pts, height: CGFloat(297).pts)
        case .a3:     return CGSize(width: CGFloat(297).pts, height: CGFloat(420).pts)
        case .a2:     return CGSize(width: CGFloat(420).pts, height: CGFloat(594).pts)
        case .letter: return CGSize(width: CGFloat(215.9).pts, height: CGFloat(279.4).pts)
        }
    }
}


struct CuttingMarks {
    static let markLength: CGFloat = 10   // length of corner marks
    static let markOffset: CGFloat = 5    // distance from edge
    static let markColor = CGColor(gray: 0.4, alpha: 1)

    // Draw corner marks and page label on a CGContext
    static func draw(in ctx: CGContext,
                     pageRect: CGRect,
                     column: Int, row: Int,
                     totalColumns: Int, totalRows: Int) {

        ctx.saveGState()
        ctx.setStrokeColor(markColor)
        ctx.setLineWidth(0.5)
        ctx.setLineDash(phase: 0, lengths: [3, 2])

        // Corner marks — small L-shapes at each corner
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            // top-left
            (CGPoint(x: markOffset, y: markOffset + markLength),
             CGPoint(x: markOffset, y: markOffset),
             CGPoint(x: markOffset + markLength, y: markOffset)),
            // top-right
            (CGPoint(x: pageRect.width - markOffset - markLength, y: markOffset),
             CGPoint(x: pageRect.width - markOffset, y: markOffset),
             CGPoint(x: pageRect.width - markOffset, y: markOffset + markLength)),
            // bottom-left
            (CGPoint(x: markOffset, y: pageRect.height - markOffset - markLength),
             CGPoint(x: markOffset, y: pageRect.height - markOffset),
             CGPoint(x: markOffset + markLength, y: pageRect.height - markOffset)),
            // bottom-right
            (CGPoint(x: pageRect.width - markOffset - markLength,
                     y: pageRect.height - markOffset),
             CGPoint(x: pageRect.width - markOffset,
                     y: pageRect.height - markOffset),
             CGPoint(x: pageRect.width - markOffset,
                     y: pageRect.height - markOffset - markLength))
        ]

        for (a, corner, b) in corners {
            ctx.move(to: a)
            ctx.addLine(to: corner)
            ctx.addLine(to: b)
            ctx.strokePath()
        }

        // Page label — e.g. "Page 2/3 [Col 2, Row 1]"
        let label = "Page \(row * totalColumns + column + 1)/\(totalColumns * totalRows)"
            + "  [\(column + 1)×\(row + 1)]"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 7),
            .foregroundColor: NSColor.gray
        ]
        let str = NSAttributedString(string: label, attributes: attrs)
        str.draw(at: CGPoint(x: markOffset + markLength + 4,
                             y: pageRect.height - markOffset - 10))

        // Overlap indicator — shaded band showing the glue zone
        ctx.setFillColor(CGColor(gray: 0.9, alpha: 0.5))
        ctx.setLineDash(phase: 0, lengths: [])
        let overlap: CGFloat = 10
        if column > 0 {   // left overlap band
            ctx.fill(CGRect(x: markOffset, y: markOffset,
                            width: overlap, height: pageRect.height - markOffset * 2))
        }
        if row > 0 {      // top overlap band
            ctx.fill(CGRect(x: markOffset, y: markOffset,
                            width: pageRect.width - markOffset * 2, height: overlap))
        }

        ctx.restoreGState()
    }
}


