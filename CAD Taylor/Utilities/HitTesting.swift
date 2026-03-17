// ============================================
// File: HitTesting.swift
// Hit-testing logic for shape selection
// ============================================

import Foundation
import CoreGraphics

struct HitTesting {
    
    /// Findet das erste Shape an der gegebenen Position
    static func findShape(at point: CGPoint, in shapes: [Shape], tolerance: CGFloat = 15) -> Shape? {
        // Rückwärts durchsuchen (zuletzt gezeichnete zuerst)
        for shape in shapes.reversed() {
            switch shape.type {
            case.cubicBezier:
                if isMouseNearBezier(mousePoint: point, segments: shape.bezierSegments) {
                    return shape
                }
            default:
                if isPointNear(point, shape: shape, tolerance: tolerance) {
                    return shape
                }
            }
        }
        return nil
    }
    
    /// Prüft ob ein Punkt nahe genug an einem Shape ist
    static func isPointNear(_ point: CGPoint, shape: Shape, tolerance: CGFloat) -> Bool {
        // Erste schnelle Prüfung: Bounding Box
        if !shape.boundingBox.contains(point) {
            return false
        }
        
        // Detaillierte Prüfung je nach Shape-Typ
        switch shape.type {
        case .straightLine:
            return distanceToStraightLine(point, shape: shape) < tolerance
            
        case .rectangle:
            return distanceToRectangle(point, shape: shape) < tolerance
            
        case .freehand, .circleArc:
            return distanceToPolyline(point, shape: shape) < tolerance
        case .text:
            return false // not yet implemeted
        case .cubicBezier:
            return false // not yet implemented
        }
    }
    static func hitTestBezierPoints(mousePosition: CGPoint, bezierSegments: [BezierSegment],   threshold: CGFloat = 10) -> HitResult? {
        for(index,point) in bezierSegments.enumerated() {
            if mousePosition.distance(to: point.curvePoint) < threshold {
                return .curvePoint(index: index)
            }
            if point.controlPoint != .zero,
               mousePosition.distance(to: point.controlPoint) < threshold{
                return .controlPoint(index: index)
            }
            if point.controlPoint1 != .zero,
               mousePosition.distance(to: point.controlPoint1) < threshold{
                return .controlPoint1(index: index)
            }

        }
        return nil
    }

    static func isMouseNearBezier(mousePoint: CGPoint,
                           segments: [BezierSegment],
                           threshold: CGFloat = 6.0) -> Bool {
        guard segments.count > 1 else { return false }

        for i in 1..<segments.count {
            let p0 = segments[i-1].curvePoint
            let p1 = segments[i-1].controlPoint
            let p2 = segments[i-1].controlPoint1
            let p3 = segments[i].curvePoint

            let steps = 60
            for step in 0...steps {
                let t = CGFloat(step) / CGFloat(steps)
                let mt = 1 - t
                let x = mt*mt*mt*p0.x + 3*mt*mt*t*p1.x + 3*mt*t*t*p2.x + t*t*t*p3.x
                let y = mt*mt*mt*p0.y + 3*mt*mt*t*p1.y + 3*mt*t*t*p2.y + t*t*t*p3.y
                let sample = CGPoint(x: x, y: y)

                if hypot(sample.x - mousePoint.x, sample.y - mousePoint.y) < threshold {
                    return true
                }
            }
        }
        return false
    }

    
    /// Berechnet Distanz von Punkt zu gerader Linie
    private static func distanceToStraightLine(_ point: CGPoint, shape: Shape) -> CGFloat {
        guard shape.points.count >= 2 else { return .infinity }
        
        let p1 = shape.points[0]
        let p2 = shape.points[shape.points.count - 1]
        
        return distanceFromPointToLineSegment(point, lineStart: p1, lineEnd: p2)
    }
    
    /// Berechnet Distanz von Punkt zu Rechteck (Kanten)
    private static func distanceToRectangle(_ point: CGPoint, shape: Shape) -> CGFloat {
        guard shape.points.count >= 4 else { return .infinity }
        
        // Rechteck besteht aus 4 Linien-Segmenten
        var minDistance: CGFloat = .infinity
        
        for i in 0..<4 {
            let p1 = shape.points[i]
            let p2 = shape.points[(i + 1) % 4]
            let distance = distanceFromPointToLineSegment(point, lineStart: p1, lineEnd: p2)
            minDistance = min(minDistance, distance)
        }
        
        return minDistance
    }
    
    /// Berechnet Distanz von Punkt zu Polyline (Freehand, Arc)
    private static func distanceToPolyline(_ point: CGPoint, shape: Shape) -> CGFloat {
        guard shape.points.count >= 2 else {
            // Einzelner Punkt
            if let p = shape.points.first {
                return hypot(point.x - p.x, point.y - p.y)
            }
            return .infinity
        }
        
        var minDistance: CGFloat = .infinity
        
        for i in 0..<(shape.points.count - 1) {
            let p1 = shape.points[i]
            let p2 = shape.points[i + 1]
            let distance = distanceFromPointToLineSegment(point, lineStart: p1, lineEnd: p2)
            minDistance = min(minDistance, distance)
        }
        
        return minDistance
    }
    
    /// Berechnet die kürzeste Distanz von einem Punkt zu einem Liniensegment
    private static func distanceFromPointToLineSegment(
        _ point: CGPoint,
        lineStart: CGPoint,
        lineEnd: CGPoint
    ) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        
        if dx == 0 && dy == 0 {
            // Linie ist nur ein Punkt
            return hypot(point.x - lineStart.x, point.y - lineStart.y)
        }
        
        // Projektion des Punkts auf die Linie (parametrisiert von 0 bis 1)
        let t = max(0, min(1, ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (dx * dx + dy * dy)))
        
        // Nächster Punkt auf dem Liniensegment
        let closestX = lineStart.x + t * dx
        let closestY = lineStart.y + t * dy
        
        // Distanz berechnen
        return hypot(point.x - closestX, point.y - closestY)
    }
}
