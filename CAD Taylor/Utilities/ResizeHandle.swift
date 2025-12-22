// ============================================
// File: ResizeHandle.swift
// Handle identification for resize operations
// ============================================

import Foundation
import CoreGraphics

enum ResizeHandle: Equatable {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
    case topMiddle
    case rightMiddle
    case bottomMiddle
    case leftMiddle
    case lineStart      // Für straightLine
    case lineEnd        // Für straightLine
    
    /// Gibt die Position des Handles für ein gegebenes Shape zurück
    func position(for shape: Shape) -> CGPoint? {
        let box = shape.boundingBox
        
        switch self {
        case .topLeft:
            return CGPoint(x: box.minX, y: box.minY)
        case .topRight:
            return CGPoint(x: box.maxX, y: box.minY)
        case .bottomRight:
            return CGPoint(x: box.maxX, y: box.maxY)
        case .bottomLeft:
            return CGPoint(x: box.minX, y: box.maxY)
        case .topMiddle:
            return CGPoint(x: box.midX, y: box.minY)
        case .rightMiddle:
            return CGPoint(x: box.maxX, y: box.midY)
        case .bottomMiddle:
            return CGPoint(x: box.midX, y: box.maxY)
        case .leftMiddle:
            return CGPoint(x: box.minX, y: box.midY)
        case .lineStart:
            return shape.points.first
        case .lineEnd:
            return shape.points.last
        }
    }
    
    /// Findet den Handle an der gegebenen Position
    static func findHandle(at point: CGPoint, for shape: Shape, tolerance: CGFloat = 15) -> ResizeHandle? {
        let availableHandles = handles(for: shape.type)
        
        for handle in availableHandles {
            if let handlePos = handle.position(for: shape) {
                let distance = hypot(point.x - handlePos.x, point.y - handlePos.y)
                if distance < tolerance {
                    return handle
                }
            }
        }
        
        return nil
    }
    
    /// Gibt alle verfügbaren Handles für einen Shape-Typ zurück
    static func handles(for type: ShapeType) -> [ResizeHandle] {
        switch type {
        case .rectangle:
            return [
                .topLeft, .topRight, .bottomRight, .bottomLeft,
                .topMiddle, .rightMiddle, .bottomMiddle, .leftMiddle
            ]
        case .straightLine:
            return [.lineStart, .lineEnd]
        case .freehand, .circleArc:
            return []
        }
    }
}
