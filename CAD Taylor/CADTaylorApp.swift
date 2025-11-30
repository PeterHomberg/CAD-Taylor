// ============================================
// File: CADTaylorApp.swift
// Main app entry point and menu configuration
// ============================================

import SwiftUI

@main
struct CADTaylorApp: App {
    //@StateObject private var windowManager = WindowManager()
    @State private var showInMillimeters = false
    

    var body: some Scene {
        WindowGroup {
            DrawingCanvasView(showInMillimeters: $showInMillimeters)
            //ContentView()
                //.environmentObject(windowManager)
        }
        .onChange(of: showInMillimeters) {_ in
            NotificationCenter.default.post(name: .notificToggleMillName, object: nil)
            print(("onChange of showInMillimeters \(showInMillimeters)"))
            
        }
        .commands {
            MenuCommands()
            // Nur der Toggle inline, weil er State braucht
            CommandGroup(before: .sidebar) {
                Toggle("Show in Millimeters", isOn: $showInMillimeters)
                    .keyboardShortcut("m", modifiers: [.command, .shift])
            }
            
        }
    }
}



