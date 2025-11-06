//
//  DrawingToolbar.swift
//  CAD Taylor
//
//  Created by Peter Homberg on 11/6/25.
//

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
            
            Spacer()
        }
        .padding()
        .frame(width: 220)
        .background(Color.gray.opacity(0.1))
    }
}

struct ToolButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
