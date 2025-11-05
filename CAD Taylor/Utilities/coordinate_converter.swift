// ============================================
// File: CoordinateConverter.swift
// Coordinate conversion utilities for mm/px
// ============================================

import Foundation
import CoreGraphics

struct CoordinateConverter {
    // Standard PDF resolution: 72 points per inch
    // 1 inch = 25.4 mm
    // Therefore: 1 point = 25.4/72 mm ≈ 0.3527777778 mm
    static let pointsPerInch: CGFloat = 72.0
    static let mmPerInch: CGFloat = 25.4
    static let mmPerPoint: CGFloat = mmPerInch / pointsPerInch
    
    /// Convert points (pixels) to millimeters
    static func pointsToMillimeters(_ points: CGFloat) -> CGFloat {
        return points * mmPerPoint
    }
    
    /// Convert millimeters to points (pixels)
    static func millimetersToPoints(_ mm: CGFloat) -> CGFloat {
        return mm / mmPerPoint
    }
    
    /// Format coordinate for display
    static func formatCoordinate(_ value: CGFloat, inMillimeters: Bool) -> String {
        if inMillimeters {
            let mm = pointsToMillimeters(value)
            return String(format: "%.1f", mm)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    /// Get unit label
    static func unitLabel(inMillimeters: Bool) -> String {
        return inMillimeters ? "mm" : "px"
    }
}
