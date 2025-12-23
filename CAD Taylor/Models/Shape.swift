// ============================================
// File: Shape.swift
// New shape-based data model for selectable elements
// ============================================

import Foundation
import CoreGraphics

enum ShapeType: Codable {
    case freehand
    case straightLine
    case rectangle
    case circleArc
}

struct Shape: Identifiable, Codable {
    var id = UUID()
    var type: ShapeType
    var points: [CGPoint]
    var color: String = "blue"
    var width: CGFloat = 3.0
    var isSelected: Bool = false
    
    // Bounding Box für Hit-Testing
    var boundingBox: CGRect {
        guard !points.isEmpty else { return CGRect.zero }
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        let minX = xs.min()!
        let maxX = xs.max()!
        let minY = ys.min()!
        let maxY = ys.max()!
        
        // Padding hinzufügen für besseres Hit-Testing
        let padding: CGFloat = 10
        return CGRect(
            x: minX - padding,
            y: minY - padding,
            width: (maxX - minX) + 2 * padding,
            height: (maxY - minY) + 2 * padding
        )
    }
    
    // Spezifische Eckpunkte für Rechteck (4 Punkte)
    var cornerPoints: [NamedPoint]? {
        guard type == .rectangle, points.count == 4 else { return nil }
        return [
            NamedPoint(name: "Top-Left", point: points[0]),
            NamedPoint(name: "Top-Right", point: points[1]),
            NamedPoint(name: "Bottom-Right", point: points[2]),
            NamedPoint(name: "Bottom-Left", point: points[3])
        ]
    }
    
    // Update Eckpunkte
    mutating func updateCornerPoints(_ namedPoints: [NamedPoint]) {
        guard type == .rectangle, namedPoints.count == 4 else { return }
        self.points = namedPoints.map { $0.point }
    }
    
    // Initialisierung von Line (für Migration)
    init(from line: Line, type: ShapeType) {
        self.type = type
        self.points = line.points
        self.color = line.color
        self.width = line.width
    }
    
    // Standard Initialisierung
    init(type: ShapeType, points: [CGPoint] = [], color: String = "blue", width: CGFloat = 3.0) {
        self.type = type
        self.points = points
        self.color = color
        self.width = width
    }
}

// MARK: - Named Point (für Koordinatentabelle)
struct NamedPoint: Identifiable {
    let id = UUID()
    let name: String
    var point: CGPoint
}

// Codable extensions für CGPoint
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Double(x), forKey: .x)
        try container.encode(Double(y), forKey: .y)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Double.self, forKey: .x)
        let y = try container.decode(Double.self, forKey: .y)
        self.init(x: x, y: y)
    }
}
