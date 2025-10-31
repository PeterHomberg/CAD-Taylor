// ============================================
// File: DrawingDocument.swift
// Serializable drawing document model
// ============================================

import Foundation
import CoreGraphics

struct DrawingDocument: Codable {
    var lines: [SerializableLine]
    var canvasSize: SerializableSize
    var version: String = "1.0"
    
    struct SerializableLine: Codable {
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
    
    // Convert from app model to serializable model
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
    
    func toCanvasSize() -> CGSize {
        return CGSize(width: CGFloat(canvasSize.width), height: CGFloat(canvasSize.height))
    }
}
