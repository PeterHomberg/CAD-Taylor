// ============================================
// File: DrawingToolbar.swift
// Sidebar for selecting drawing tools
// NOW WITH: Coordinate input table for rectangles
// ============================================

import SwiftUI

struct DrawingToolbar: View {
    @Binding var shapes: [Shape]
    @Binding var showInMillimeters: Bool
    @ObservedObject var model: DrawingModel
    var onCommitBezier: () -> Void
    
    // Computed: letztes gezeichnetes Rechteck für Koordinaten-Eingabe
    private var lastRectangle: Shape? {
        shapes.last(where: { $0.type == .rectangle })
    }
    
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
                    isSelected: model.selectedDrawingMode == .freehand
                ) {
                    model.selectedDrawingMode = .freehand
                }
                
                Divider()
                
                // Straight Line
                ToolButton(
                    title: "Straight Line",
                    icon: "line.diagonal",
                    isSelected: model.selectedDrawingMode == .straightLine
                ) {
                    model.selectedDrawingMode = .straightLine
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
                    isSelected: model.selectedDrawingMode == .circleArc
                ) {
                    model.selectedDrawingMode = .circleArc
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
                    isSelected: model.selectedDrawingMode == .square
                ) {
                    model.selectedDrawingMode = .square
                }
                
                Text("Click top-left, then drag to bottom-right")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
            
            Divider()
                .padding(.vertical, 8)
            VStack {
                // Kubische Bézierkurve (NEU)
                ToolButton(title: "Cubic Bézier", icon: "scribble.variable",
                           isSelected: model.selectedDrawingMode == .cubicBezier) {
                    model.selectedDrawingMode = .cubicBezier
                }
                Text("Click to place points · Drag to pull handles · Double-click to finish")
                    .font(.caption).foregroundColor(.gray).padding(.leading, 8)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil.tip")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Toggle("", isOn: $model.penMode)
                            .toggleStyle(.checkbox)
                            .fixedSize()
                    }
                    .help("Toggles the control points editing")
                    Divider()
                        .frame(height: 20)
                    Button { model.clear() } label: {
                        Label("", systemImage: "circle.dashed.inset.filled") // Edit
                    }
                    .help("Edit")
                    .toolbarButton(role: .default)
                    .frame(maxWidth: .infinity)         // ← each button takes equal share


                    Button { model.clear() } label: {
                        Label("", systemImage: "trash") //Clear
                    }
                    .help("Clear the current Bezier curve")
                    .toolbarButton(role: .destructive)
                    .frame(maxWidth: .infinity)         // ← each button takes equal share

                    Button { onCommitBezier() } label: {
                        Label("", systemImage: "checkmark") //Commit
                    }
                    .help("Commit")
                    .toolbarButton(role: .confirm)
                    .frame(maxWidth: .infinity)         // ← each button takes equal share
                }
                
            }

            
            // Coordinate input for rectangle (NEW!)
            if model.selectedDrawingMode == .square {
                if let rectangle = lastRectangle {
                    CoordinateInputSection(
                        shape: rectangle,
                        showInMillimeters: showInMillimeters,
                        onUpdate: { updatedShape in
                            updateShape(updatedShape)
                        }
                    )
                } else {
                    Text("Draw a rectangle to edit coordinates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: 240)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(minWidth: 280, maxWidth: 340)
        .clipped()
        .background(Color.gray.opacity(0.1))
    }
    
    private func updateShape(_ updatedShape: Shape) {
        if let index = shapes.firstIndex(where: { $0.id == updatedShape.id }) {
            shapes[index] = updatedShape
        }
    }
}

// MARK: - Coordinate Input Section
struct CoordinateInputSection: View {
    let shape: Shape
    let showInMillimeters: Bool
    let onUpdate: (Shape) -> Void
    
    @State private var editedPoints: [NamedPoint] = []
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rectangle Coordinates")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(showInMillimeters ? "mm" : "px")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            if let cornerPoints = shape.cornerPoints {
                VStack(spacing: 8) {
                    // Header
                    HStack(spacing: 8) {
                        Text("Corner")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 70, alignment: .leading)
                        
                        Text("X")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 65, alignment: .center)
                        
                        Text("Y")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 65, alignment: .center)
                    }
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Coordinate rows
                    ForEach(Array(cornerPoints.enumerated()), id: \.element.id) { index, namedPoint in
                        CoordinateRow(
                            namedPoint: namedPoint,
                            index: index,
                            showInMillimeters: showInMillimeters,
                            onUpdate: { updatedPoint in
                                updatePoint(at: index, with: updatedPoint)
                            }
                        )
                    }
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Apply button
            Button(action: applyChanges) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Apply Changes")
                }
                .frame(maxWidth: 240)
                .padding(.vertical, 8)
                .background(isEditing ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isEditing)
        }
        .onAppear {
            if let corners = shape.cornerPoints {
                editedPoints = corners
            }
        }
        .onChange(of: shape.points) { _ in
            if let corners = shape.cornerPoints {
                editedPoints = corners
                isEditing = false
            }
        }
    }
    
    private func updatePoint(at index: Int, with point: CGPoint) {
        guard index < editedPoints.count else { return }
        editedPoints[index].point = point
        isEditing = true
    }
    
    private func applyChanges() {
        var updatedShape = shape
        updatedShape.updateCornerPoints(editedPoints)
        onUpdate(updatedShape)
        isEditing = false
    }
}

// MARK: - Coordinate Row
struct CoordinateRow: View {
    let namedPoint: NamedPoint
    let index: Int
    let showInMillimeters: Bool
    let onUpdate: (CGPoint) -> Void
    
    @State private var xText: String = ""
    @State private var yText: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case x, y
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Corner name (shortened)
            Text(shortName(namedPoint.name))
                .font(.caption)
                .frame(width: 70, alignment: .leading)
            
            // X coordinate
            TextField("X", text: $xText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 11, design: .monospaced))
                .multilineTextAlignment(.trailing)
                .frame(width: 65)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
                .focused($focusedField, equals: .x)
                .onChange(of: xText) { _ in
                    updateCoordinate()
                }
            
            // Y coordinate
            TextField("Y", text: $yText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 11, design: .monospaced))
                .multilineTextAlignment(.trailing)
                .frame(width: 65)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
                .focused($focusedField, equals: .y)
                .onChange(of: yText) { _ in
                    updateCoordinate()
                }
        }
        .onAppear {
            updateTextFields()
        }
        .onChange(of: namedPoint.point) { _ in
            updateTextFields()
        }
        .onChange(of: showInMillimeters) { _ in
            updateTextFields()
        }
    }
    
    private func shortName(_ name: String) -> String {
        switch name {
        case "Top-Left": return "TL"
        case "Top-Right": return "TR"
        case "Bottom-Right": return "BR"
        case "Bottom-Left": return "BL"
        default: return name
        }
    }
    
    private func updateTextFields() {
        let x = showInMillimeters ? 
            CoordinateConverter.pointsToMillimeters(namedPoint.point.x) : 
            namedPoint.point.x
        let y = showInMillimeters ? 
            CoordinateConverter.pointsToMillimeters(namedPoint.point.y) : 
            namedPoint.point.y
        
        xText = String(format: showInMillimeters ? "%.1f" : "%.0f", x)
        yText = String(format: showInMillimeters ? "%.1f" : "%.0f", y)
    }
    
    private func updateCoordinate() {
        guard let xValue = Double(xText),
              let yValue = Double(yText) else { return }
        
        let x = showInMillimeters ? 
            CoordinateConverter.millimetersToPoints(CGFloat(xValue)) : 
            CGFloat(xValue)
        let y = showInMillimeters ? 
            CoordinateConverter.millimetersToPoints(CGFloat(yValue)) : 
            CGFloat(yValue)
        
        onUpdate(CGPoint(x: x, y: y))
    }
}

// ToolButton wurde nach SharedComponents.swift verschoben
// um Duplikation zu vermeiden
