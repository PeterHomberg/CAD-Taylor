// ============================================
// File: DrawingDocument.swift
// Serializable drawing document model
// ============================================

import Foundation
import CoreGraphics

struct DrawingDocument: Codable {
    //var lines: [SerializableLine]
    var shapes: [SerializableShape]?
    var canvasSize: SerializableSize
    var version: String = "1.0"

    // MARK: - Serializable types

    struct SerializableLine: Codable {
        var points: [SerializablePoint]
        var color: String
        var width: Double
    }

    struct SerializableShape: Codable {
        var id: String
        var type: String  // "freehand", "straightLine", "rectangle", "circleArc", "cubicBezier"
        var points: [SerializablePoint]                          // used by all non-bezier shapes
        var bezierSegments: [SerializableBezierSegment]?         // only for cubicBezier
        var color: String
        var width: Double
    }

    struct SerializablePoint: Codable {
        var x: Double
        var y: Double
    }

    struct SerializableBezierSegment: Codable {
        var curvePoint:    SerializablePoint
        var controlPoint:  SerializablePoint
        var curvePoint1:   SerializablePoint
        var controlPoint1: SerializablePoint
    }

    struct SerializableSize: Codable {
        var width: Double
        var height: Double
    }

    // MARK: - Init from Shapes

    init(shapes: [Shape], canvasSize: CGSize) {
        self.shapes = shapes.map { shape in
            switch shape.geometry {
            case .points(let pts):
                return SerializableShape(
                    id: shape.id.uuidString,
                    type: shapeTypeToString(shape.type),
                    points: pts.map { SerializablePoint(x: Double($0.x), y: Double($0.y)) },
                    bezierSegments: nil,
                    color: shape.color,
                    width: Double(shape.width)
                )
            case .bezier(let segs):
                return SerializableShape(
                    id: shape.id.uuidString,
                    type: shapeTypeToString(shape.type),
                    points: [],
                    bezierSegments: segs.map { seg in
                        SerializableBezierSegment(
                            curvePoint:    SerializablePoint(x: Double(seg.curvePoint.x),    y: Double(seg.curvePoint.y)),
                            controlPoint:  SerializablePoint(x: Double(seg.controlPoint.x),  y: Double(seg.controlPoint.y)),
                            curvePoint1:   SerializablePoint(x: Double(seg.curvePoint1.x),   y: Double(seg.curvePoint1.y)),
                            controlPoint1: SerializablePoint(x: Double(seg.controlPoint1.x), y: Double(seg.controlPoint1.y))
                        )
                    },
                    color: shape.color,
                    width: Double(shape.width)
                )
            }
        }


        self.canvasSize = SerializableSize(
            width: Double(canvasSize.width),
            height: Double(canvasSize.height)
        )
    }


    // MARK: - Convert to app model


    func toShapes() -> [Shape] {
        // Prefer shapes array if available (new format)
        if let shapes = shapes {
            return shapes.map { s in
                let type = stringToShapeType(s.type)

                // Bezier shape — restore from bezierSegments if present
                if type == .cubicBezier, let segs = s.bezierSegments {
                    let bezierSegments = segs.map { seg in
                        BezierSegment(
                            curvePoint:    CGPoint(x: seg.curvePoint.x,    y: seg.curvePoint.y),
                            controlPoint:  CGPoint(x: seg.controlPoint.x,  y: seg.controlPoint.y),
                            curvePoint1:   CGPoint(x: seg.curvePoint1.x,   y: seg.curvePoint1.y),
                            controlPoint1: CGPoint(x: seg.controlPoint1.x, y: seg.controlPoint1.y)
                        )
                    }
                    return Shape(type: type, bezierSegments: bezierSegments, color: s.color, width: CGFloat(s.width))
                }

                // All other shapes — restore from points
                let points = s.points.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
                return Shape(type: type, points: points, color: s.color, width: CGFloat(s.width))
            }
        }
        return []
    }

    func toCanvasSize() -> CGSize {
        CGSize(width: CGFloat(canvasSize.width), height: CGFloat(canvasSize.height))
    }
}

// MARK: - ShapeType string conversion

private func shapeTypeToString(_ type: ShapeType) -> String {
    switch type {
    case .freehand:     return "freehand"
    case .straightLine: return "straightLine"
    case .rectangle:    return "rectangle"
    case .circleArc:    return "circleArc"
    case .cubicBezier:  return "cubicBezier"
    case .text:         return "text"
    }
}

private func stringToShapeType(_ string: String) -> ShapeType {
    switch string {
    case "freehand":     return .freehand
    case "straightLine": return .straightLine
    case "rectangle":    return .rectangle
    case "circleArc":    return .circleArc
    case "cubicBezier":  return .cubicBezier
    default:             return .freehand
    }
}
