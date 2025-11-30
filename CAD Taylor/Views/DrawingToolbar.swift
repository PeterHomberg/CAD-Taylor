// ============================================
// File: DrawingToolbar.swift
// Sidebar for selecting drawing tools
// ============================================

import SwiftUI

struct DrawingToolbar: View {
    @Binding var selectedMode: DrawingMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Drawing Tools")
                .font(.headline)
                .padding(.bottom, 10)
            
            Group {
                // Freehand Drawing
                ToolButton(
                    title: "Freehand",
                    icon: "pencil.tip",
                    isSelected: selectedMode == .freehand
                ) {
                    selectedMode = .freehand
                }
                
                Divider()
                
                // Straight Line
                ToolButton(
                    title: "Straight Line",
                    icon: "line.diagonal",
                    isSelected: selectedMode == .straightLine
                ) {
                    selectedMode = .straightLine
                }
                
                Text("Click start point, then end point")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                
                Divider()
            }
            
            Group {
                // Circle Arc
                ToolButton(
                    title: "Circle Arc",
                    icon: "circle.lefthalf.filled",
                    isSelected: selectedMode == .circleArc
                ) {
                    selectedMode = .circleArc
                }
                
                Text("Click three points to define arc")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                
                Divider()
                
                // Square
                ToolButton(
                    title: "Square",
                    icon: "square",
                    isSelected: selectedMode == .square
                ) {
                    selectedMode = .square
                }
                
                Text("Click top-left, then drag to bottom-right")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 220)
        .background(Color.gray.opacity(0.1))
    }
}

// ToolButton wurde nach SharedComponents.swift verschoben
// um Duplikation zu vermeiden
