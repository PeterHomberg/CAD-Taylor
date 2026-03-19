// ============================================
// File: CADTaylorApp.swift
// Main app entry point and menu configuration
// ============================================

import SwiftUI

@main
struct CADTaylorApp: App {
    @State private var showInMillimeters = true
    
    var body: some Scene {
        WindowGroup {
            DrawingCanvasView(showInMillimeters: $showInMillimeters)
        }
        .commands {
            MenuCommands()
            // Toggle inline, because it needs State binding
            CommandGroup(before: .sidebar) {
                Toggle("Show in Millimeters", isOn: $showInMillimeters)
                    .keyboardShortcut("m", modifiers: [.command, .shift])
                    .disabled(true)
            }
        }
    }
}
