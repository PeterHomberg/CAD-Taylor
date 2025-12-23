// ============================================
// File: EditToolbar.swift
// Sidebar for editing selected shapes
// NOW WITH: Coordinate input for selected rectangles
// ============================================

import SwiftUI

struct EditToolbar: View {
    @Binding var editMode: EditMode
    @Binding var shapes: [Shape]
    @Binding var selectedShapeID: UUID?
    @Binding var showInMillimeters: Bool
    
    let hasSelection: Bool
    
    // Computed: aktuell ausgewähltes Shape
    private var selectedShape: Shape? {
        guard let id = selectedShapeID else { return nil }
        return shapes.first(where: { $0.id == id })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Tools")
                .font(.headline)
                .padding(.bottom, 10)
            
            if hasSelection {
                Group {
                    // Move
                    ToolButton(
                        title: "Move",
                        icon: "arrow.up.and.down.and.arrow.left.and.right",
                        isSelected: editMode == .move
                    ) {
                        editMode = .move
                    }
                    
                    Text("Drag to move the shape")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                    
                    Divider()
                    
                    // Resize
                    ToolButton(
                        title: "Resize",
                        icon: "arrow.up.left.and.arrow.down.right",
                        isSelected: editMode == .resize
                    ) {
                        editMode = .resize
                    }
                    
                    Text("Drag handles to resize")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                    
                    Divider()
                    
                    // Edit Points (coming in Phase 5)
                    ToolButton(
                        title: "Edit Points",
                        icon: "circle.grid.cross",
                        isSelected: editMode == .editPoints
                    ) {
                        editMode = .editPoints
                    }
                    .opacity(0.5) // Disabled for now
                    
                    Text("Coming in Phase 5")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Coordinate input for selected rectangle (NEW!)
                if let shape = selectedShape, shape.type == .rectangle {
                    CoordinateInputSection(
                        shape: shape,
                        showInMillimeters: showInMillimeters,
                        onUpdate: { updatedShape in
                            updateShape(updatedShape)
                        }
                    )
                } else if let shape = selectedShape {
                    // Info für andere Shape-Types
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Selected Shape")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Type: \(shape.type.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if shape.type == .straightLine {
                            Text("Coordinate editing for lines coming soon")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        } else if shape.type == .circleArc {
                            Text("Coordinate editing for arcs coming soon")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "hand.point.up.left")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                    
                    Text("No Shape Selected")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                    
                    Text("Click on a shape to select it")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 5)
                }
                .padding(.vertical, 30)
            }
            
            Spacer()
            
            // Keyboard shortcuts info
            VStack(alignment: .leading, spacing: 8) {
                Text("Shortcuts")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("Esc")
                        .font(.caption)
                        .padding(4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    Text("Deselect")
                        .font(.caption)
                }
                
                HStack {
                    Text("Delete")
                        .font(.caption)
                        .padding(4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    Text("Remove shape")
                        .font(.caption)
                }
            }
            .padding(.top, 20)
        }
        .padding()
        .frame(width: 280)
        .background(Color.gray.opacity(0.1))
    }
    
    private func updateShape(_ updatedShape: Shape) {
        if let index = shapes.firstIndex(where: { $0.id == updatedShape.id }) {
            shapes[index] = updatedShape
        }
    }
}

// ToolButton wurde nach SharedComponents.swift verschoben
// um Duplikation zu vermeiden
