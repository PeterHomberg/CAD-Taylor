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
}

// Für temporäre Zeichnungen während der Erstellung
struct TemporaryShape {
    var mode: DrawingMode
    var points: [CGPoint] = []
    var isComplete: Bool = false
}
