// ============================================
// File: GridSettings.swift
// Grid and snap-to-grid configuration model
// ============================================

import CoreGraphics
import Foundation

struct GridSettings: Codable {

    // MARK: - Properties

    /// Whether the grid is drawn on the canvas
    var isVisible: Bool = false

    /// Whether mouse positions are snapped to the nearest grid point
    var snapEnabled: Bool = false

    /// Grid spacing in millimetres (user-facing unit)
    var spacingMM: Double = 10.0

    // MARK: - Computed helpers

    /// Grid spacing converted to points (the internal coordinate unit)
    var spacingPts: CGFloat {
        CoordinateConverter.millimetersToPoints(CGFloat(spacingMM))
    }

    // MARK: - Snap helper

    /// Rounds a canvas point to the nearest grid intersection.
    /// Returns the point unchanged when snap is disabled.
    func snap(_ point: CGPoint) -> CGPoint {
        guard snapEnabled else { return point }
        let s = spacingPts
        guard s > 0 else { return point }
        return CGPoint(
            x: (point.x / s).rounded() * s,
            y: (point.y / s).rounded() * s
        )
    }
}
