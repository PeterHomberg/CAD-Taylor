// ============================================
// File: DrawingView.swift
// Custom drawing view for rendering lines
// ============================================

import SwiftUI

struct DrawingView: View {
    let lines: [Line]
    let currentLine: Line
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
                
                // Draw current line being drawn
                if currentLine.points.count > 1 {
                    path.move(to: currentLine.points[0])
                    for point in currentLine.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
    }
}

