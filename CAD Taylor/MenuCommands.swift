// ============================================
// File: MenuCommands.swift
// Menu bar command definitions
// ============================================

import SwiftUI

struct MenuCommands: Commands {
    @ObservedObject var recentManager: RecentDocumentsManager
    var body: some Commands {
        // File Menu
        CommandGroup(replacing: .newItem) {
            Button("New Drawing") {
                NotificationCenter.default.post(name: .newDrawing, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        
        CommandGroup(after: .newItem) {
            Button("Open Drawing...") {
                NotificationCenter.default.post(name: .openDrawing, object: nil)
            }
            .keyboardShortcut("o", modifiers: .command)
            
            // Manual Open Recent Menu
            Menu("Open Recent") {
                ForEach(recentManager.recentURLs, id: \.self) { url in
                    Button(url.lastPathComponent) {
                        // openFile sends the URL via notification
                        NotificationCenter.default.post(name: .openRecentDrawing, object: url)
                    }
                }
                if !recentManager.recentURLs.isEmpty {
                    Divider()
                    Button("Clear Menu") {
                        recentManager.clear()
                    }
                }
            }
            .disabled(recentManager.recentURLs.isEmpty)
            
            Divider()
            
            Button("Save Drawing...") {
                NotificationCenter.default.post(name: .saveDrawing, object: nil)
            }
            .keyboardShortcut("s", modifiers: .command)
            
            Button("Export as PDF...") {
                NotificationCenter.default.post(name: .savePDF, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            
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
        CommandGroup(before: .sidebar) {
            Button("Show/Hide Coordinates") {
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
