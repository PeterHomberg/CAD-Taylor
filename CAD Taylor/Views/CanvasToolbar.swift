// ============================================
// File: CanvasToolbar.swift
// Bottom toolbar with controls
// ============================================

import SwiftUI

struct CanvasToolbar: View {
    let onClear: () -> Void
    let onExport: () -> Void
    let showCoordinates: Bool
    let currentCoordinates: CGPoint
    let zoomLevel: CGFloat

    
    var body: some View {
        HStack {

                Button("Clear Canvas") {
                    onClear()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
                
                Button("Export PDF") {
                    onExport()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                if showCoordinates {
                    Text("X: \(Int(currentCoordinates.x)), Y: \(Int(currentCoordinates.y)) | Zoom: \(Int(zoomLevel * 100))%")
                        .font(.system(size: 16, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }

}
