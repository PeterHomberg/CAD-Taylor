// ============================================
// File: CADTaylorApp.swift
// Main app entry point and menu configuration
// ============================================

import SwiftUI

@main
struct CADTaylorApp: App {
    //@StateObject private var windowManager = WindowManager()
    @State private var showInMillimeters = false
    @Environment(\.coord) var coord

    var body: some Scene {
        WindowGroup {
            DrawingCanvasView(showInMillimeters: $showInMillimeters)
            //ContentView()
                //.environmentObject(windowManager)
                .environment(\.coord, showInMillimeters ? .mill : .pix)
            
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

enum Coord {
    case mill, pix
}
struct CoordKey: EnvironmentKey {
    static let defaultValue: Coord = .pix
}
extension EnvironmentValues {
    var coord: Coord {
        get {
            self[CoordKey.self]
        }
        set {
            self[CoordKey.self] = newValue
        }
    }
}


