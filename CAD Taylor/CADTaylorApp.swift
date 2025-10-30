// ============================================
// File: CADTaylorApp.swift
// Main app entry point and menu configuration
// ============================================

import SwiftUI

@main
struct CADTaylorApp: App {
    @StateObject private var windowManager = WindowManager()
    
    var body: some Scene {
        WindowGroup {
            DrawingCanvasView()
                .environmentObject(windowManager)
        }
        .commands {
            MenuCommands()
        }
    }
}
