// ============================================
// File: EditToolbar.swift
// Sidebar for editing selected shapes
// ============================================

import SwiftUI

struct EditToolbar: View {
    @Binding var editMode: EditMode
    let hasSelection: Bool
    
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
                    
                    // Resize (coming in Phase 4)
                    ToolButton(
                        title: "Resize",
                        icon: "arrow.up.left.and.arrow.down.right",
                        isSelected: editMode == .resize
                    ) {
                        editMode = .resize
                    }
                    .opacity(0.5) // Disabled for now
                    
                    Text("Coming in Phase 4")
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
        .frame(width: 220)
        .background(Color.gray.opacity(0.1))
    }
}

// ToolButton wurde nach SharedComponents.swift verschoben
// um Duplikation zu vermeiden
