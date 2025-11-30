// ============================================
// File: SelectionOverlay.swift
// Visual feedback for selected shapes
// ============================================

import SwiftUI

struct SelectionOverlay: View {
    let shape: Shape
    
    var body: some View {
        ZStack {
            // Bounding Box mit gestrichelter Linie
            boundingBoxView
            
            // Handles basierend auf Shape-Typ
            if shape.type == .rectangle || shape.type == .straightLine {
                resizeHandlesView
            }
            
            if shape.type == .circleArc {
                editPointsView
            }
        }
    }
    
    // MARK: - Subviews
    
    private var boundingBoxView: some View {
        Rectangle()
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
            .frame(
                width: shape.boundingBox.width,
                height: shape.boundingBox.height
            )
            .position(
                x: shape.boundingBox.midX,
                y: shape.boundingBox.midY
            )
    }
    
    private var resizeHandlesView: some View {
        ForEach(Array(handlePositions.enumerated()), id: \.offset) { index, position in
            Circle()
                .fill(Color.white)
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 10, height: 10)
                .position(position)
        }
    }
    
    private var editPointsView: some View {
        ForEach(Array(shape.points.enumerated()), id: \.offset) { index, point in
            Circle()
                .fill(Color.orange)
                .stroke(Color.white, lineWidth: 1)
                .frame(width: 8, height: 8)
                .position(point)
        }
    }
    
    // MARK: - Handle Positions
    
    private var handlePositions: [CGPoint] {
        let box = shape.boundingBox
        
        switch shape.type {
        case .rectangle:
            // 4 Eckpunkte + 4 Mittelpunkte = 8 Handles
            return [
                CGPoint(x: box.minX, y: box.minY),  // Top-left
                CGPoint(x: box.maxX, y: box.minY),  // Top-right
                CGPoint(x: box.maxX, y: box.maxY),  // Bottom-right
                CGPoint(x: box.minX, y: box.maxY),  // Bottom-left
                CGPoint(x: box.midX, y: box.minY),  // Top-middle
                CGPoint(x: box.maxX, y: box.midY),  // Right-middle
                CGPoint(x: box.midX, y: box.maxY),  // Bottom-middle
                CGPoint(x: box.minX, y: box.midY),  // Left-middle
            ]
            
        case .straightLine:
            // 2 Endpunkte
            if shape.points.count >= 2 {
                return [shape.points.first!, shape.points.last!]
            }
            return []
            
        default:
            return []
        }
    }
}
