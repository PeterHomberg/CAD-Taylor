// ============================================
// File: DrawingCanvasView.swift
// Main canvas view with drawing functionality
// ============================================

import SwiftUI

struct DrawingCanvasView: View {
    @State private var lines: [Line] = []
    @State private var currentLine = Line()
    @State private var currentCoordinates = CGPoint.zero
    @State private var canvasSize = CGSize(width: 600, height: 400)
    @State private var showCoordinates = true
    @State private var zoomLevel: CGFloat = 1.0
    @EnvironmentObject var windowManager: WindowManager
    
    var body: some View {
        VStack {
            // Drawing canvas
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .border(Color.gray, width: 1)
                
                DrawingView(lines: lines, currentLine: currentLine, canvasSize: $canvasSize)
                    .scaleEffect(zoomLevel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let adjustedLocation = CGPoint(
                            x: value.location.x / zoomLevel,
                            y: value.location.y / zoomLevel
                        )
                        currentLine.points.append(adjustedLocation)
                        currentCoordinates = adjustedLocation
                    }
                    .onEnded { _ in
                        lines.append(currentLine)
                        currentLine = Line()
                    }
            )
 
            CanvasToolbar(
                onClear: clearCanvas,
                onExport: exportPDF,
                onSave: saveDrawing,
                onOpen: openDrawing,
                showCoordinates: showCoordinates,
                currentCoordinates: currentCoordinates,
                zoomLevel: zoomLevel
            )
        }
        .padding()
        .frame(minWidth: 700, minHeight: 600)
        .setupNotificationHandlers(
            lines: $lines,
            currentLine: $currentLine,
            currentCoordinates: $currentCoordinates,
            zoomLevel: $zoomLevel,
            showCoordinates: $showCoordinates,
            canvasSize: canvasSize,
            onExport: exportPDF,
            onSave: saveDrawing,
            onOpen: openDrawing
        )
    }

    private func clearCanvas() {
        lines.removeAll()
        currentLine = Line()
        currentCoordinates = CGPoint.zero
    }
    
    private func exportPDF() {
        PDFExporter.savePDFWithDialog(lines: lines, canvasSize: canvasSize)
    }
    
    private func saveDrawing() {
        DrawingSerializer.saveDrawingWithDialog(lines: lines, canvasSize: canvasSize)
    }
    
    private func openDrawing() {
        DrawingSerializer.openDrawingWithDialog { result in
            switch result {
            case .success(let data):
                lines = data.lines
                canvasSize = data.canvasSize
                currentLine = Line()
                currentCoordinates = CGPoint.zero
            case .failure(let error):
                print("Failed to open drawing: \(error)")
            }
        }
    }
}
