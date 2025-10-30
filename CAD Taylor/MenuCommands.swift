// ============================================
// File: MenuCommands.swift
// Menu bar command definitions
// ============================================

import SwiftUI

struct MenuCommands: Commands {
    var body: some Commands {
        // File Menu
        CommandGroup(replacing: .newItem) {
            Button("New Drawing") {
                NotificationCenter.default.post(name: .newDrawing, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        
        
        CommandGroup(after: .newItem) {
            Button("Save as PDF...") {
                NotificationCenter.default.post(name: .savePDF, object: nil)
            }
            .keyboardShortcut("s", modifiers: .command)
            
            Divider()
        }
        
        // Edit Menu
        CommandGroup(replacing: .undoRedo) {
            Button("Undo") {
                NotificationCenter.default.post(name: .undoDrawing, object: nil)
            }
            .keyboardShortcut("z", modifiers: .command)
            
            Button("Clear Canvas") {
                NotificationCenter.default.post(name: .clearCanvas, object: nil)
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])
        }
        
        // View Menu
        CommandMenu("View") {
            Button("Show Coordinates") {
                NotificationCenter.default.post(name: .toggleCoordinates, object: nil)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Zoom In") {
                NotificationCenter.default.post(name: .zoomIn, object: nil)
            }
            .keyboardShortcut("+", modifiers: .command)
            
            Button("Zoom Out") {
                NotificationCenter.default.post(name: .zoomOut, object: nil)
            }
            .keyboardShortcut("-", modifiers: .command)
            
            Button("Reset Zoom") {
                NotificationCenter.default.post(name: .resetZoom, object: nil)
            }
            .keyboardShortcut("0", modifiers: .command)
        }
    }
}
