// ============================================
// File: DrawingView.swift
// Custom drawing view for rendering shapes
// ============================================

import SwiftUI

struct DrawingView: View {
    let shapes: [Shape]
    let currentShape: Shape?
    let temporaryShape: TemporaryShape?
    @Binding var canvasSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Update canvas size
                DispatchQueue.main.async {
                    if canvasSize != geometry.size {
                        canvasSize = geometry.size
                    }
                }
                
                // Draw all completed shapes
                for shape in shapes {
                    drawShape(shape, into: &path)
                }
                
                // Draw current shape being drawn
                if let current = currentShape {
                    drawShape(current, into: &path)
                }
                
                // Draw temporary shape preview
                if let temp = temporaryShape {
                    if temp.mode == .square, let rect = temp.rect {
                        path.addRect(rect)
                    } else if temp.points.count > 1 {
                        path.move(to: temp.points[0])
                        for point in temp.points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    
                    // Draw points as circles
                    for point in temp.points {
                        let circleRect = CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)
                        path.addEllipse(in: circleRect)
                    }
                }
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
    
    private func drawShape(_ shape: Shape, into path: inout Path) {
        guard !shape.points.isEmpty else { return }
        
        switch shape.type {
        case .freehand, .circleArc:
            // Draw as polyline
            if shape.points.count > 1 {
                path.move(to: shape.points[0])
                for point in shape.points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            
        case .straightLine:
            // Draw straight line from first to last point
            if shape.points.count >= 2 {
                path.move(to: shape.points[0])
                path.addLine(to: shape.points[shape.points.count - 1])
            }
            
        case .rectangle:
            // Draw rectangle (4 points in order)
            if shape.points.count >= 4 {
                path.move(to: shape.points[0])
                for point in shape.points.dropFirst() {
                    path.addLine(to: point)
                }
                path.closeSubpath()
            }
        case .text:
            return // not yet implemented
        }
    }
}
