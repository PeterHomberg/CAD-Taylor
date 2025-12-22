// ============================================
// File: ShapeResizer.swift
// Logic for resizing shapes
// ============================================

import Foundation
import CoreGraphics

struct ShapeResizer {
    
    /// Resize ein Shape basierend auf Handle und neuer Position
    static func resize(
        shape: Shape,
        handle: ResizeHandle,
        newPosition: CGPoint,
        originalShape: Shape
    ) -> Shape {
        var resizedShape = shape
        
        switch shape.type {
        case .rectangle:
            resizedShape = resizeRectangle(
                shape: shape,
                handle: handle,
                newPosition: newPosition,
                originalShape: originalShape
            )
            
        case .straightLine:
            resizedShape = resizeStraightLine(
                shape: shape,
                handle: handle,
                newPosition: newPosition
            )
            
        default:
            break
        }
        
        return resizedShape
    }
    
    // MARK: - Rectangle Resize
    
    private static func resizeRectangle(
        shape: Shape,
        handle: ResizeHandle,
        newPosition: CGPoint,
        originalShape: Shape
    ) -> Shape {
        var resized = shape
        
        // Original Eckpunkte
        guard originalShape.points.count >= 4 else { return shape }
        let originalPoints = originalShape.points
        
        // Bestimme welche Eckpunkte sich ändern
        let topLeft: CGPoint
        let topRight: CGPoint
        let bottomRight: CGPoint
        let bottomLeft: CGPoint
        
        switch handle {
        case .topLeft:
            topLeft = newPosition
            topRight = CGPoint(x: originalPoints[1].x, y: newPosition.y)
            bottomRight = originalPoints[2]
            bottomLeft = CGPoint(x: newPosition.x, y: originalPoints[3].y)
            
        case .topRight:
            topLeft = CGPoint(x: originalPoints[0].x, y: newPosition.y)
            topRight = newPosition
            bottomRight = CGPoint(x: newPosition.x, y: originalPoints[2].y)
            bottomLeft = originalPoints[3]
            
        case .bottomRight:
            topLeft = originalPoints[0]
            topRight = CGPoint(x: newPosition.x, y: originalPoints[1].y)
            bottomRight = newPosition
            bottomLeft = CGPoint(x: originalPoints[3].x, y: newPosition.y)
            
        case .bottomLeft:
            topLeft = CGPoint(x: newPosition.x, y: originalPoints[0].y)
            topRight = originalPoints[1]
            bottomRight = CGPoint(x: originalPoints[2].x, y: newPosition.y)
            bottomLeft = newPosition
            
        case .topMiddle:
            topLeft = CGPoint(x: originalPoints[0].x, y: newPosition.y)
            topRight = CGPoint(x: originalPoints[1].x, y: newPosition.y)
            bottomRight = originalPoints[2]
            bottomLeft = originalPoints[3]
            
        case .rightMiddle:
            topLeft = originalPoints[0]
            topRight = CGPoint(x: newPosition.x, y: originalPoints[1].y)
            bottomRight = CGPoint(x: newPosition.x, y: originalPoints[2].y)
            bottomLeft = originalPoints[3]
            
        case .bottomMiddle:
            topLeft = originalPoints[0]
            topRight = originalPoints[1]
            bottomRight = CGPoint(x: originalPoints[2].x, y: newPosition.y)
            bottomLeft = CGPoint(x: originalPoints[3].x, y: newPosition.y)
            
        case .leftMiddle:
            topLeft = CGPoint(x: newPosition.x, y: originalPoints[0].y)
            topRight = originalPoints[1]
            bottomRight = originalPoints[2]
            bottomLeft = CGPoint(x: newPosition.x, y: originalPoints[3].y)
            
        default:
            return shape
        }
        
        // Update die Punkte
        resized.points = [topLeft, topRight, bottomRight, bottomLeft]
        
        return resized
    }
    
    // MARK: - Straight Line Resize
    
    private static func resizeStraightLine(
        shape: Shape,
        handle: ResizeHandle,
        newPosition: CGPoint
    ) -> Shape {
        var resized = shape
        
        guard resized.points.count >= 2 else { return shape }
        
        switch handle {
        case .lineStart:
            resized.points[0] = newPosition
            
        case .lineEnd:
            resized.points[resized.points.count - 1] = newPosition
            
        default:
            break
        }
        
        return resized
    }
}
