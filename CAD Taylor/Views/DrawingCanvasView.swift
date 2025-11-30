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
    @State private var selectedMode: DrawingMode = .freehand
    @State private var temporaryShape: TemporaryShape?
    @Binding var showInMillimeters: Bool
    
    
    var body: some View {
        HStack(spacing: 0) {
            // Main canvas area
            VStack {
                // Drawing canvas
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .border(Color.gray, width: 1)
                    
                    // Mouse tracking overlay
                    MouseTrackingView { location in
                        let adjustedLocation = CGPoint(
                            x: location.x / zoomLevel,
                            y: location.y / zoomLevel
                        )
                        currentCoordinates = adjustedLocation
                    }
                    
                    DrawingView(
                        lines: lines,
                        currentLine: currentLine,
                        temporaryShape: temporaryShape,
                        canvasSize: $canvasSize
                    )
                    .scaleEffect(zoomLevel)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDrawing(at: value.location)
                        }
                        .onEnded { value in
                            handleDrawingEnd(at: value.location)
                        }
                )
                
                // Bottom toolbar
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
                        let xFormatted = CoordinateConverter.formatCoordinate(currentCoordinates.x, inMillimeters: showInMillimeters)
                        let yFormatted = CoordinateConverter.formatCoordinate(currentCoordinates.y, inMillimeters: showInMillimeters)
                        let unit = CoordinateConverter.unitLabel(inMillimeters: showInMillimeters)
                        Text("X: \(xFormatted) \(unit), Y: \(yFormatted) \(unit) | Zoom: \(Int(zoomLevel * 100))%")
                            .font(.system(size: 16, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            
            // Right sidebar with drawing tools
            DrawingToolbar(selectedMode: $selectedMode)
        }
        .frame(minWidth: 900, minHeight: 600)
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
    
    private func handleDrawing(at location: CGPoint) {
        let adjustedLocation = CGPoint(
            x: location.x / zoomLevel,
            y: location.y / zoomLevel
        )
        currentCoordinates = adjustedLocation
        
        switch selectedMode {
        case .freehand:
            currentLine.points.append(adjustedLocation)
            
        case .straightLine:
            if temporaryShape == nil {
                // Erster Punkt
                temporaryShape = TemporaryShape(mode: .straightLine, points: [adjustedLocation])
            } else {
                // Während des Ziehens: Endpunkt aktualisieren
                temporaryShape?.points = [temporaryShape!.points[0], adjustedLocation]
            }
            
        case .square:
            if temporaryShape == nil {
                // Erster Punkt (top-left)
                temporaryShape = TemporaryShape(mode: .square, points: [adjustedLocation])
            } else {
                // Während des Ziehens: bottom-right Punkt aktualisieren
                temporaryShape?.points = [temporaryShape!.points[0], adjustedLocation]
            }
            
        case .circleArc:
            // Wird bei Klicks behandelt, nicht bei Drag
            break
        }
    }
    
    private func handleDrawingEnd(at location: CGPoint) {
        let adjustedLocation = CGPoint(
            x: location.x / zoomLevel,
            y: location.y / zoomLevel
        )
        
        switch selectedMode {
        case .freehand:
            lines.append(currentLine)
            currentLine = Line()
            
        case .straightLine:
            if let shape = temporaryShape, shape.points.count == 2 {
                // Gerade Linie fertig
                var line = Line()
                line.points = shape.points
                lines.append(line)
                temporaryShape = nil
            }
            
        case .square:
            if let shape = temporaryShape, shape.points.count == 2, let rect = shape.rect {
                // Quadrat/Rechteck fertig - in 4 Linien umwandeln
                var line = Line()
                // Top edge
                line.points.append(CGPoint(x: rect.minX, y: rect.minY))
                line.points.append(CGPoint(x: rect.maxX, y: rect.minY))
                lines.append(line)
                
                // Right edge
                line = Line()
                line.points.append(CGPoint(x: rect.maxX, y: rect.minY))
                line.points.append(CGPoint(x: rect.maxX, y: rect.maxY))
                lines.append(line)
                
                // Bottom edge
                line = Line()
                line.points.append(CGPoint(x: rect.maxX, y: rect.maxY))
                line.points.append(CGPoint(x: rect.minX, y: rect.maxY))
                lines.append(line)
                
                // Left edge
                line = Line()
                line.points.append(CGPoint(x: rect.minX, y: rect.maxY))
                line.points.append(CGPoint(x: rect.minX, y: rect.minY))
                lines.append(line)
                
                temporaryShape = nil
            }
            
        case .circleArc:
            if temporaryShape == nil {
                temporaryShape = TemporaryShape(mode: .circleArc, points: [adjustedLocation])
            } else if temporaryShape!.points.count == 1 {
                temporaryShape?.points.append(adjustedLocation)
            } else if temporaryShape!.points.count == 2 {
                temporaryShape?.points.append(adjustedLocation)
                // Kreisbogen berechnen
                if let arc = calculateCircleArc(points: temporaryShape!.points) {
                    lines.append(arc)
                }
                temporaryShape = nil
            }
        }
    }
    
    private func calculateCircleArc(points: [CGPoint]) -> Line? {
        guard points.count == 3 else { return nil }
        
        let p1 = points[0]
        let p2 = points[1]
        let p3 = points[2]
        
        // Kreismittelpunkt berechnen
        let d = 2 * (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y))
        
        guard abs(d) > 0.001 else { return nil } // Punkte sind kollinear
        
        let ux = ((p1.x * p1.x + p1.y * p1.y) * (p2.y - p3.y) +
                  (p2.x * p2.x + p2.y * p2.y) * (p3.y - p1.y) +
                  (p3.x * p3.x + p3.y * p3.y) * (p1.y - p2.y)) / d
        
        let uy = ((p1.x * p1.x + p1.y * p1.y) * (p3.x - p2.x) +
                  (p2.x * p2.x + p2.y * p2.y) * (p1.x - p3.x) +
                  (p3.x * p3.x + p3.y * p3.y) * (p2.x - p1.x)) / d
        
        let center = CGPoint(x: ux, y: uy)
        let radius = sqrt(pow(p1.x - center.x, 2) + pow(p1.y - center.y, 2))
        
        // Winkel berechnen
        let angle1 = atan2(p1.y - center.y, p1.x - center.x)
        let angle2 = atan2(p2.y - center.y, p2.x - center.x)
        let angle3 = atan2(p3.y - center.y, p3.x - center.x)
        
        // Bogen in Punkte umwandeln
        var arcPoints: [CGPoint] = []
        let segments = 50
        
        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let angle = angle1 + (angle3 - angle1) * t
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            arcPoints.append(CGPoint(x: x, y: y))
        }
        
        var line = Line()
        line.points = arcPoints
        return line
    }
    
    private func clearCanvas() {
        lines.removeAll()
        currentLine = Line()
        temporaryShape = nil
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
    
    let notificationToggleMillimeters = NotificationCenter.default
        .publisher(for: .notificToggleMillName)
        .receive(on: RunLoop.main)
}

// MARK: - Mouse Tracking View
struct MouseTrackingView: NSViewRepresentable {
    let onMouseMoved: (CGPoint) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = MouseTrackingNSView()
        view.onMouseMoved = onMouseMoved
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let trackingView = nsView as? MouseTrackingNSView {
            trackingView.onMouseMoved = onMouseMoved
        }
    }
}

class MouseTrackingNSView: NSView {
    var onMouseMoved: ((CGPoint) -> Void)?
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [
            .mouseMoved,
            .activeInKeyWindow,
            .inVisibleRect
        ]
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: options,
            owner: self,
            userInfo: nil
        )
        
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        // NSView hat Ursprung unten links, SwiftUI hat Ursprung oben links
        // Daher Y-Koordinate umrechnen
        let flippedLocation = CGPoint(x: location.x, y: bounds.height - location.y)
        onMouseMoved?(flippedLocation)
    }
}
