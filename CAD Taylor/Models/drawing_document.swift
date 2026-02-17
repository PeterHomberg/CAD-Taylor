// ============================================
// File: DrawingDocument.swift
// Serializable drawing document model
// ============================================

import Foundation
import CoreGraphics

struct DrawingDocument: Codable {
    var lines: [SerializableLine]
    var shapes: [SerializableShape]?  // NEU: Optional für Backwards-Kompatibilität
    var canvasSize: SerializableSize
    var version: String = "1.0"
    
    struct SerializableLine: Codable {
        var points: [SerializablePoint]
        var color: String
        var width: Double
    }
    
    struct SerializableShape: Codable {
        var id: String
        var type: String  // "freehand", "straightLine", "rectangle", "circleArc"
        var points: [SerializablePoint]
        var color: String
        var width: Double
    }
    
    struct SerializablePoint: Codable {
        var x: Double
        var y: Double
    }
    
    struct SerializableSize: Codable {
        var width: Double
        var height: Double
    }
    
    // NEU: Convert from Shapes to serializable model
    init(shapes: [Shape], canvasSize: CGSize) {
        // Convert shapes to serializable format
        self.shapes = shapes.map { shape in
            SerializableShape(
                id: shape.id.uuidString,
                type: shapeTypeToString(shape.type),
                points: shape.points.map { point in
                    SerializablePoint(x: Double(point.x), y: Double(point.y))
                },
                color: shape.color,
                width: Double(shape.width)
            )
        }
        
        // Also save as lines for backwards compatibility
        self.lines = shapes.map { shape in
            SerializableLine(
                points: shape.points.map { point in
                    SerializablePoint(x: Double(point.x), y: Double(point.y))
                },
                color: shape.color,
                width: Double(shape.width)
            )
        }
        
        self.canvasSize = SerializableSize(
            width: Double(canvasSize.width),
            height: Double(canvasSize.height)
        )
    }
    
    // Legacy: Convert from Lines (for old code)
    init(lines: [Line], canvasSize: CGSize) {
        self.lines = lines.map { line in
            SerializableLine(
                points: line.points.map { point in
                    SerializablePoint(x: Double(point.x), y: Double(point.y))
                },
                color: line.color,
                width: Double(line.width)
            )
        }
        self.canvasSize = SerializableSize(
            width: Double(canvasSize.width),
            height: Double(canvasSize.height)
        )
    }
    
    // Convert to app model
    func toLines() -> [Line] {
        return lines.map { serializableLine in
            Line(
                points: serializableLine.points.map { point in
                    CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                },
                color: serializableLine.color,
                width: CGFloat(serializableLine.width)
            )
        }
    }
    
    // NEU: Convert to Shapes
    func toShapes() -> [Shape] {
        // Prefer shapes array if available (new format)
        if let shapes = shapes {
            return shapes.map { serializableShape in
                Shape(
                    type: stringToShapeType(serializableShape.type),
                    points: serializableShape.points.map { point in
                        CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                    },
                    color: serializableShape.color,
                    width: CGFloat(serializableShape.width)
                )
            }
        }
        
        // Fallback to lines for backwards compatibility
        // Try to detect rectangles by point count
        return lines.map { serializableLine in
            let points = serializableLine.points.map { point in
                CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
            }
            
            // Heuristik: 4 Punkte = wahrscheinlich Rectangle
            let type: ShapeType = (points.count == 4) ? .rectangle : .freehand
            
            return Shape(
                type: type,
                points: points,
                color: serializableLine.color,
                width: CGFloat(serializableLine.width)
            )
        }
    }
    
    func toCanvasSize() -> CGSize {
        return CGSize(width: CGFloat(canvasSize.width), height: CGFloat(canvasSize.height))
    }
}

// Helper functions for ShapeType conversion
private func shapeTypeToString(_ type: ShapeType) -> String {
    switch type {
    case .freehand: return "freehand"
    case .straightLine: return "straightLine"
    case .rectangle: return "rectangle"
    case .circleArc: return "circleArc"
    }
}

private func stringToShapeType(_ string: String) -> ShapeType {
    switch string {
    case "freehand": return .freehand
    case "straightLine": return .straightLine
    case "rectangle": return .rectangle
    case "circleArc": return .circleArc
    default: return .freehand
    }
}
