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
    func printableRect() -> CGRect {
        return CGRect(
            x: overlap,
            y: overlap,
            width:  paperSize.width  - overlap * 2,
            height: paperSize.height - overlap * 2
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
    
    // Draw overlap indicator and page label on a CGContext
    func draw(in ctx: CGContext, layout: PageLayout,
              column: Int, row: Int,
              totalColumns: Int, totalRows: Int) {

        ctx.saveGState()

        // --- Page label ---
        let label = "Page \(row * totalColumns + column + 1)/\(totalColumns * totalRows)"
            + "  [\(column + 1)×\(row + 1)]"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 7),
            .foregroundColor: NSColor.red
        ]
        let str = NSAttributedString(string: label, attributes: attrs)
        let textSize = str.size()

        // Context is top-left origin. NSAttributedString.draw needs bottom-left origin.
        // So flip locally just for text: translate to where text top-left should be,
        // then flip so AppKit sees bottom-left origin at that point.
        let textTopLeft = CGPoint(
            x: 100,
            y: 5  // Y measured from top
        )
        ctx.saveGState()
        ctx.translateBy(x: textTopLeft.x, y: textTopLeft.y + textSize.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        print("textTopLeft.y: \(textTopLeft.y)  textSize.height: \(textSize.height) ")
        print("CTM before str.draw: \(ctx.ctm)")
        
        
        
        let fontSize: CGFloat = 12
        let font =  NSFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.red]
        
        let attributedString = NSAttributedString(string: label, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        
        ctx.textPosition = .zero
        CTLineDraw(line, ctx)

        
        
        
        
        
        
        
        
        
        
        //str.draw(at: .zero)
        ctx.restoreGState()
        print("CTM before mark overlap bands: \(ctx.ctm)")
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

        ctx.restoreGState()
    }
    
}


