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
    @State private var pdfURL: URL?
    @Environment(\.coord) var coord
    //let onExport: () -> Void
    //@EnvironmentObject var windowManager: WindowManager
    
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
            
        }
        .onReceive(notificationToggleMillimeters) {  notification in
            print("Toggle Millimeters notification received! \(notification) Toggle: \(coord)")
        }
        .onReceive(NotificationCenter.default.publisher(for: .newDrawing)) { _ in
            lines.removeAll()
            currentLine = Line()
            currentCoordinates = CGPoint.zero
            zoomLevel = 1.0
        }
        .onReceive(NotificationCenter.default.publisher(for: .savePDF)) { _ in
            //onExport()
        }
        .onReceive(NotificationCenter.default.publisher(for: .clearCanvas)) { _ in
            lines.removeAll()
            currentLine = Line()
            currentCoordinates = CGPoint.zero
        }
        .onReceive(NotificationCenter.default.publisher(for: .undoDrawing)) { _ in
            if !lines.isEmpty {
                lines.removeLast()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleCoordinates)) { _ in
            showCoordinates.toggle()
        }
    /*
        .onReceive(NotificationCenter.default.publisher(for: .toggleMillimeters)) {  notification in
            print("Toggle Millimeters notification received! \(notification) Toggle: \(coord)")
        }
     */
        .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
            zoomLevel = min(zoomLevel + 0.25, 3.0)
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
            zoomLevel = max(zoomLevel - 0.25, 0.25)
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetZoom)) { _ in
            zoomLevel = 1.0
        }

        .padding()
        .frame(minWidth: 700, minHeight: 600)
    }
    
    private func clearCanvas() {
        lines.removeAll()
        currentLine = Line()
        currentCoordinates = CGPoint.zero
    }
    
    private func exportPDF() {
        PDFExporter.savePDFWithDialog(lines: lines, canvasSize: canvasSize)
    }
    let notificationToggleMillimeters = NotificationCenter.default
        .publisher(for: .notificToggleMillName)
        .receive(on: RunLoop.main)
}

