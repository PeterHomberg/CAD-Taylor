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
        let box = shape.boundingBox
        return Rectangle()
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
            .frame(width: box.width, height: box.height)
            .position(x: box.midX, y: box.midY)
    }
    
    private var resizeHandlesView: some View {
        ForEach(Array(handlePositions.enumerated()), id: \.offset) { index, position in
            handleCircle(at: position, color: .blue)
        }
    }
    
    private var editPointsView: some View {
        ForEach(Array(shape.points.enumerated()), id: \.offset) { index, point in
            handleCircle(at: point, color: .orange)
        }
    }
    
    private func handleCircle(at position: CGPoint, color: Color) -> some View {
        Circle()
            .fill(Color.white)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
            )
            .frame(width: 10, height: 10)
            .position(position)
    }
    
    // MARK: - Handle Positions
    
    private var handlePositions: [CGPoint] {
        let box = shape.boundingBox
        
        switch shape.type {
        case .rectangle:
            // 4 Eckpunkte + 4 Mittenpunkte = 8 Handles
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
