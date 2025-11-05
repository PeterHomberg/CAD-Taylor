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
            
            HStack {
                Button("Clear Canvas") {
                    clearCanvas()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
                
                Button("Export PDF") {
                    exportPDF()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .foregroundColor(Color.white)
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                if showCoordinates {
                    /*---------------------------------------
                     to debug @State property use:
                     (lldb) po _showInMillimeters.wrappedValue
                     
                     Swift ist scheisse!
                    
                    let xFormatted = CoordinateConverter.formatCoordinate(currentCoordinates.x, inMillimeters: showInMillimeters)
                    let yFormatted = CoordinateConverter.formatCoordinate(currentCoordinates.y, inMillimeters: showInMillimeters)
                    let unit = CoordinateConverter.unitLabel(inMillimeters: showInMillimeters)
                                        Text("X: \(xFormatted) \(unit), Y: \(yFormatted) \(unit) | Zoom: \(Int(zoomLevel * 100))%")
                        .font(.system(size: 16, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                     --------------------------------------*/
                    
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleMillimeters)) {  notification in
            print("Toggle Millimeters notification received! \(notification) Toggle: \(coord)")
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
            onExport: exportPDF
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
    let notificationToggleMillimeters = NotificationCenter.default
        .publisher(for: .toggleMillimeters)
        .receive(on: RunLoop.main)
}

struct Previews_DrawingCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        DrawingCanvasView()
    }
}
