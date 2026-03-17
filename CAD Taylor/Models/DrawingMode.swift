//
//  DrawingMode.swift
//  CAD Taylor
//
//  Created by Peter Homberg on 11/6/25.
//

import Foundation
// ============================================
// File: DrawingMode.swift
// Drawing mode definitions
// ============================================

import Foundation
import CoreGraphics

enum DrawingMode {
    case freehand
    case straightLine
    case circleArc
    case square
    case cubicBezier
    
}

// Für temporäre Zeichnungen während der Erstellung
struct TemporaryShape {
    var mode: DrawingMode
    var points: [CGPoint] = []
    var bezierSegments: [BezierSegment] = []
    var isComplete: Bool = false
    
    // Computed rectangle for square mode
    var rect: CGRect? {
        guard mode == .square, points.count == 2 else { return nil }
        let topLeft = points[0]
        let bottomRight = points[1]
        return CGRect(
            x: min(topLeft.x, bottomRight.x),
            y: min(topLeft.y, bottomRight.y),
            width: abs(bottomRight.x - topLeft.x),
            height: abs(bottomRight.y - topLeft.y)
        )
    }
}
