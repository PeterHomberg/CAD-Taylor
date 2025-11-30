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
        guard !points.isEmpty else { return .zero }
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
