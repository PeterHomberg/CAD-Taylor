// ============================================
// File: DrawingView.swift
// Custom drawing view for rendering lines
// ============================================

import SwiftUI

struct DrawingView: View {
    let lines: [Line]
    let currentLine: Line
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
                
                // Draw all completed lines
                for line in lines {
                    if line.points.count > 1 {
                        path.move(to: line.points[0])
                        for point in line.points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                
                // Draw current freehand line being drawn
                if currentLine.points.count > 1 {
                    path.move(to: currentLine.points[0])
                    for point in currentLine.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                
                // Draw temporary shape (straight line or circle arc preview)
                if let temp = temporaryShape {
                    if temp.points.count > 1 {
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
}
