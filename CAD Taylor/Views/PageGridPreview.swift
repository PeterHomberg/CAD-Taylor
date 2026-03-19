//
//  PageGridPreview.swift
//  CAD Taylor
//
//  Created by Peter Homberg on 3/19/26.
//

import SwiftUI

// ============================================
// File: PageGridPreview.swift
// Shows a scaled grid of pages for print setup
// ============================================

import SwiftUI

struct PageGridPreview: View {
    let layout: PageLayout

    // Visual constants
    private let gap: CGFloat        = 6
    private let overlapWidth: CGFloat = 6
    private let markLength: CGFloat = 6
    private let markOffset: CGFloat = 3
    private let pageNumberSize: CGFloat = 9

    var body: some View {
        GeometryReader { geo in
            let pageSize = scaledPageSize(in: geo.size)
            let totalW   = CGFloat(layout.columns) * pageSize.width
                         + CGFloat(layout.columns - 1) * gap
            let totalH   = CGFloat(layout.rows) * pageSize.height
                         + CGFloat(layout.rows - 1) * gap

            // Center the grid inside the available space
            ZStack {
                Canvas { ctx, _ in
                    for row in 0..<layout.rows {
                        for col in 0..<layout.columns {
                            let origin = CGPoint(
                                x: CGFloat(col) * (pageSize.width  + gap),
                                y: CGFloat(row) * (pageSize.height + gap)
                            )
                            drawPage(ctx: &ctx,
                                     origin: origin,
                                     size: pageSize,
                                     row: row, col: col)
                        }
                    }
                }
                .frame(width: totalW, height: totalH)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Draw one page cell

    private func drawPage(ctx: inout GraphicsContext,
                          origin: CGPoint,
                          size: CGSize,
                          row: Int, col: Int) {
        let rect = CGRect(origin: origin, size: size)

        // Page background
        ctx.fill(Path(roundedRect: rect, cornerRadius: 3),
                 with: .color(Color(NSColor.controlBackgroundColor)))

        // Page border
        ctx.stroke(Path(roundedRect: rect, cornerRadius: 3),
                   with: .color(Color(NSColor.separatorColor)),
                   lineWidth: 0.5)

        // Left overlap band (for all pages except first column)
        if col > 0 {
            let band = CGRect(
                x: origin.x,
                y: origin.y + overlapWidth,
                width: overlapWidth,
                height: size.height - overlapWidth * 2
            )
            ctx.fill(Path(band),
                     with: .color(Color(NSColor.separatorColor).opacity(0.35)))
        }

        // Top overlap band (for all pages except first row)
        if row > 0 {
            let band = CGRect(
                x: origin.x + overlapWidth,
                y: origin.y,
                width: size.width - overlapWidth * 2,
                height: overlapWidth
            )
            ctx.fill(Path(band),
                     with: .color(Color(NSColor.separatorColor).opacity(0.35)))
        }

        // Corner cutting marks (L-shapes at each corner)
        drawCuttingMarks(ctx: &ctx, origin: origin, size: size)

        // Page number centered in the cell
        let pageNumber = row * layout.columns + col + 1
        let label = Text("\(pageNumber)")
            .font(.system(size: pageNumberSize))
            .foregroundColor(Color(NSColor.secondaryLabelColor))

        ctx.draw(label, at: CGPoint(
            x: origin.x + size.width  / 2,
            y: origin.y + size.height / 2
        ))
    }

    // MARK: - Cutting marks

    private func drawCuttingMarks(ctx: inout GraphicsContext,
                                  origin: CGPoint,
                                  size: CGSize) {
        let color = Color(NSColor.separatorColor)
        let lw: CGFloat = 0.5
        let o = markOffset
        let l = markLength

        // Four corners — each is an L-shape (two lines)
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            // Top-left
            (CGPoint(x: origin.x + o,            y: origin.y + o + l),
             CGPoint(x: origin.x + o,            y: origin.y + o),
             CGPoint(x: origin.x + o + l,        y: origin.y + o)),
            // Top-right
            (CGPoint(x: origin.x + size.width - o - l, y: origin.y + o),
             CGPoint(x: origin.x + size.width - o,     y: origin.y + o),
             CGPoint(x: origin.x + size.width - o,     y: origin.y + o + l)),
            // Bottom-left
            (CGPoint(x: origin.x + o,            y: origin.y + size.height - o - l),
             CGPoint(x: origin.x + o,            y: origin.y + size.height - o),
             CGPoint(x: origin.x + o + l,        y: origin.y + size.height - o)),
            // Bottom-right
            (CGPoint(x: origin.x + size.width - o - l, y: origin.y + size.height - o),
             CGPoint(x: origin.x + size.width - o,     y: origin.y + size.height - o),
             CGPoint(x: origin.x + size.width - o,     y: origin.y + size.height - o - l))
        ]

        for (a, corner, b) in corners {
            var path = Path()
            path.move(to: a)
            path.addLine(to: corner)
            path.addLine(to: b)
            ctx.stroke(path, with: .color(color), lineWidth: lw)
        }
    }

    // MARK: - Scale calculation

    private func scaledPageSize(in available: CGSize) -> CGSize {
        let maxPageW = (available.width  - gap * CGFloat(layout.columns - 1))
                       / CGFloat(layout.columns)
        let maxPageH = (available.height - gap * CGFloat(layout.rows - 1))
                       / CGFloat(layout.rows)

        // Preserve A4 aspect ratio (210:297)
        let aspect = layout.paperSize.width / layout.paperSize.height
        let byWidth  = CGSize(width: maxPageW, height: maxPageW / aspect)
        let byHeight = CGSize(width: maxPageH * aspect, height: maxPageH)

        // Use whichever fits
        return byWidth.height <= maxPageH ? byWidth : byHeight
    }
}
