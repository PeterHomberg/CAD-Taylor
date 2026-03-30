// ============================================
// File: Shape.swift
// New shape-based data model for selectable elements
// ============================================

import Foundation
import CoreGraphics

// MARK: - ShapeType

enum ShapeType: Codable {
    case freehand
    case straightLine
    case rectangle
    case circleArc
    case cubicBezier
    case text
}

// MARK: - ShapeGeometry

enum ShapeGeometry: Codable {
    case points([CGPoint])
    case bezier([BezierSegment])

    enum CodingKeys: String, CodingKey { case type, points, bezier }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .points(let pts):
            try c.encode("points", forKey: .type)
            try c.encode(pts, forKey: .points)
        case .bezier(let segs):
            try c.encode("bezier", forKey: .type)
            try c.encode(segs, forKey: .bezier)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "bezier":
            self = .bezier(try c.decode([BezierSegment].self, forKey: .bezier))
        default:
            self = .points(try c.decode([CGPoint].self, forKey: .points))
        }
    }
}

// MARK: - Shape

struct Shape: Identifiable, Codable {
    var id = UUID()
    var type: ShapeType
    var geometry: ShapeGeometry
    var color: String = "black"
    var width: CGFloat = 3.0
    var isSelected: Bool = false

    // MARK: Compatibility shims — existing code keeps working unchanged

    /// Read/write access to the points array (all non-bezier shapes).
    var points: [CGPoint] {
        get {
            if case .points(let pts) = geometry { return pts }
            return []
        }
        set {
            guard case .points = geometry else {preconditionFailure("Shape error attempt to set bezier on points!!")}
            geometry = .points(newValue)
            
        }
    }

    /// Read/write access to the bezier segments (cubicBezier shapes).
    var bezierSegments: [BezierSegment] {
        get {
            if case .bezier(let segs) = geometry { return segs }
            return []
        }
        set {
            guard case .bezier = geometry else {preconditionFailure("Shape error attempt to set points on bezier!!")}
            geometry = .bezier(newValue)
            
        }
    }

    // MARK: - Bounding Box

    var boundingBox: CGRect {
        let pts: [CGPoint]
        switch geometry {
        case .points(let p):
            pts = p
        case .bezier(let segs):
            pts = segs.map { $0.curvePoint }
        }
        guard !pts.isEmpty else { return .zero }
        let xs = pts.map { $0.x }
        let ys = pts.map { $0.y }
        let padding: CGFloat = 10
        return CGRect(
            x: xs.min()! - padding,
            y: ys.min()! - padding,
            width: (xs.max()! - xs.min()!) + 2 * padding,
            height: (ys.max()! - ys.min()!) + 2 * padding
        )
    }

    // MARK: - Rectangle helpers

    var cornerPoints: [NamedPoint]? {
        guard type == .rectangle, points.count == 4 else { return nil }
        return [
            NamedPoint(name: "Top-Left",     point: points[0]),
            NamedPoint(name: "Top-Right",    point: points[1]),
            NamedPoint(name: "Bottom-Right", point: points[2]),
            NamedPoint(name: "Bottom-Left",  point: points[3])
        ]
    }

    mutating func updateCornerPoints(_ namedPoints: [NamedPoint]) {
        guard type == .rectangle, namedPoints.count == 4 else { return }
        self.points = namedPoints.map { $0.point }
    }

    // MARK: - Initialisers

    /// Standard init for point-based shapes.
    init(type: ShapeType, points: [CGPoint] = [], color: String = "black", width: CGFloat = 3.0) {
        self.type = type
        self.geometry = .points(points)
        self.color = color
        self.width = width
    }

    /// Init for bezier shapes.
    init(type: ShapeType = .cubicBezier, bezierSegments: [BezierSegment], color: String = "black", width: CGFloat = 3.0) {
        self.type = type
        self.geometry = .bezier(bezierSegments)
        self.color = color
        self.width = width
    }

    /// Migration init from Line.
    static func arcParameters(from points: [CGPoint]) -> (center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) {
        precondition(points.count >= 3, "Need at least 3 points")
        
        let center     = points[0]
        let startPoint = points[1]
        let endPoint   = points[2]
        
        // Radius = distance from center to points[1]
        let radius = hypot(startPoint.x - center.x, startPoint.y - center.y)
        
        // Angles are measured from the positive X axis (standard math convention)
        // atan2 returns radians in [-π, π]
        let startAngle = atan2((startPoint.y - center.y), startPoint.x - center.x)
        let endAngle   = atan2((endPoint.y   - center.y), endPoint.x   - center.x)
        
        return (center, radius, startAngle, endAngle)
    }

}

// MARK: - Named Point (für Koordinatentabelle)

struct NamedPoint: Identifiable {
    let id = UUID()
    let name: String
    var point: CGPoint
}

// MARK: - Codable extensions

extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey { case x, y }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(Double(x), forKey: .x)
        try c.encode(Double(y), forKey: .y)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let x = try c.decode(Double.self, forKey: .x)
        let y = try c.decode(Double.self, forKey: .y)
        self.init(x: x, y: y)
    }
}
