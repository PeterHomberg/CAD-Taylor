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

    init(paperSize: CGSize, canvasSize: CGSize, overlap: CGFloat = CGFloat(30).pts) {
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
        print("inside PageLayout x: = column * (\(paperSize.width) - \(overlap)")
        let y = CGFloat(row)    * (paperSize.height - overlap)
        return CGRect(x: x, y: y, width: paperSize.width, height: paperSize.height)
    }
    /// The printable area inside the cutting mark margins.
    // In PageLayout — replace printableRect() with this:
    func printableRect(column: Int, row: Int) -> CGRect {
        let leftInset   = column > 0 ? overlap : 0
        let topInset    = row    > 0 ? overlap : 0
        let rightInset  = column < columns - 1 ? overlap : 0
        let bottomInset = row    < rows    - 1 ? overlap : 0

        return CGRect(
            x:      leftInset,
            y:      topInset,
            width:  paperSize.width  - leftInset - rightInset,
            height: paperSize.height - topInset  - bottomInset
        )
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
    let overlap: CGFloat
    
    init(overlap: CGFloat){
        self.overlap = overlap
    }
    
    enum PageEdge {
        case top, bottom, left, right
    }

    func drawTextEdge(ctx: CGContext, pageSize: CGSize, text: String, fontSize: CGFloat, edge: PageEdge, edgeDistance: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: NSColor.red
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let textSize = str.size()

        ctx.saveGState()

        switch edge {
        case .top:
            // Anchor = top-left of text, y measured from top
            ctx.translateBy(x: (pageSize.width - textSize.width) / 2,
                            y: edgeDistance + textSize.height)
            ctx.scaleBy(x: 1.0, y: -1.0)

        case .bottom:
            // Anchor = top-left of text, y measured from top
            ctx.translateBy(x: (pageSize.width - textSize.width) / 2,
                            y: pageSize.height - edgeDistance)
            ctx.scaleBy(x: 1.0, y: -1.0)

        case .left:
            ctx.translateBy(x: edgeDistance + textSize.height,
                            y: (pageSize.height + textSize.width) / 2)
            ctx.rotate(by: -.pi / 2)
            ctx.scaleBy(x: 1.0, y: -1.0)

        case .right:
            ctx.translateBy(x: pageSize.width - edgeDistance - textSize.height,
                            y: (pageSize.height - textSize.width) / 2)
            ctx.rotate(by: .pi / 2)
            ctx.scaleBy(x: 1.0, y: -1.0)        }

        let line = CTLineCreateWithAttributedString(str)
        ctx.textPosition = .zero
        CTLineDraw(line, ctx)

        ctx.restoreGState()
    }
    func drawText(ctx: CGContext, position: CGPoint, text: String, fontSize: CGFloat){
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: NSColor.red
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let textSize = str.size()
        // Context is top-left origin. NSAttributedString.draw needs bottom-left origin.
        // So flip locally just for text: translate to where text top-left should be,
        // then flip so AppKit sees bottom-left origin at that point.
        ctx.saveGState()
        ctx.translateBy(x: position.x, y: position.y + textSize.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        let line = CTLineCreateWithAttributedString(str)
        ctx.textPosition = .zero
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
    
    // Draw overlap indicator and page label on a CGContext
    func draw(in ctx: CGContext, layout: PageLayout,
              column: Int, row: Int,
              totalColumns: Int, totalRows: Int) {

        ctx.saveGState()

        
        // --- Overlap bands ---
        ctx.setFillColor(CGColor(gray: 0.9, alpha: 0.8))
        ctx.setLineDash(phase: 0, lengths: [])
        if column == 0 {
            // right overlap band
            ctx.fill(CGRect(x: layout.paperSize.width - overlap, y: 0,
                            width: layout.overlap,
                            height: layout.paperSize.height ))
        }
        else if column > 0 && column < totalColumns - 1 {
            // right overlap band
            ctx.fill(CGRect(x: layout.paperSize.width - overlap, y: 0,
                            width: layout.overlap,
                            height: layout.paperSize.height ))

            // left overlap band
            ctx.fill(CGRect(x: 0, y: 0,
                            width: layout.overlap,
                            height: layout.paperSize.height ))
        }
        else if column == totalColumns - 1 {
            // left overlap band
            ctx.fill(CGRect(x: 0, y: 0,
                            width: layout.overlap,
                            height: layout.paperSize.height ))

        }
        if row == 0 {
        
        }
        else if row > 0 && row < totalRows - 1 {
            // top overlap band
            ctx.fill(CGRect(x: 0, y: 0,
                            width: layout.paperSize.width,
                            height: layout.overlap))
            // bottom overlap band
            ctx.fill(CGRect(x: 0, y: layout.paperSize.height - overlap,
                            width: layout.paperSize.width,
                            height: layout.overlap))

            
        }
        else if row == totalRows - 1 {
            // top overlap band
            ctx.fill(CGRect(x: 0, y: 0,
                            width: layout.paperSize.width,
                            height: layout.overlap))

        }
        
        // ---  labels ---
        let pageNr       = row * totalColumns + column + 1
        let upperNeighbor = row > 0                ? pageNr - totalColumns : 0
        let lowerNeighbor = row < totalRows - 1    ? pageNr + totalColumns : 0
        let leftNeighbor  = column > 0             ? pageNr - 1            : 0
        let rightNeighbor = column < totalColumns - 1 ? pageNr + 1         : 0
        let label = "Page \(row * totalColumns + column + 1)/\(totalColumns * totalRows)"
            + "  [\(column + 1)×\(row + 1)]"
        
        /*
        drawText(ctx: ctx,
                 position: CGPoint(
                            x: CGFloat(50).pts,
                            y: CGFloat(10).pts
                            ),
                text: label,
                fontSize: CGFloat(12))
         */
        
        if upperNeighbor != 0 {
            let text: String = label + "          ^ page \(upperNeighbor)"
            drawTextEdge(ctx: ctx, pageSize: layout.paperSize, text: text, fontSize: 12, edge: .top, edgeDistance: overlap)
        }
        if lowerNeighbor != 0 {
            let text: String = label + "          v page \(lowerNeighbor)"
            drawTextEdge(ctx: ctx, pageSize: layout.paperSize, text: text, fontSize: 12, edge: .bottom, edgeDistance: overlap)

        }
        if leftNeighbor != 0 {
            let text: String = label + "          < page \(leftNeighbor)"
            drawTextEdge(ctx: ctx, pageSize: layout.paperSize, text: text, fontSize: 12, edge: .left, edgeDistance: overlap)

        }
        if rightNeighbor != 0 {
            let text: String = label + "          > page \(rightNeighbor)"
            drawTextEdge(ctx: ctx, pageSize: layout.paperSize, text: text, fontSize: 12, edge: .right, edgeDistance: overlap)

        }


        ctx.restoreGState()
    }
    
}


