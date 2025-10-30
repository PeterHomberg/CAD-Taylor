// ============================================
// File: Line.swift
// Data model for drawing lines
// ============================================

import Foundation
import CoreGraphics

struct Line {
    var points: [CGPoint] = []
    var color: String = "blue" // For future color support
    var width: CGFloat = 3.0   // For future line width support
}
