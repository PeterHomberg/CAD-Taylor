// ============================================
// File: ViewModifiers.swift
// Custom view modifiers for notification handling
// ============================================

import SwiftUI

struct NotificationHandlerModifier: ViewModifier {
    @Binding var lines: [Line]
    @Binding var currentLine: Line
    @Binding var currentCoordinates: CGPoint
    @Binding var zoomLevel: CGFloat
    @Binding var showCoordinates: Bool
    let canvasSize: CGSize
    let onExport: () -> Void
    let onSave: () -> Void
    let onOpen: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .newDrawing)) { _ in
                lines.removeAll()
                currentLine = Line()
                currentCoordinates = CGPoint.zero
                zoomLevel = 1.0
            }
            .onReceive(NotificationCenter.default.publisher(for: .saveDrawing)) { _ in
                onSave()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openDrawing)) { _ in
                onOpen()
            }
            .onReceive(NotificationCenter.default.publisher(for: .savePDF)) { _ in
                onExport()
            }
            .onReceive(NotificationCenter.default.publisher(for: .clearCanvas)) { _ in
                lines.removeAll()
                currentLine = Line()
                currentCoordinates = CGPoint.zero
            }
            .onReceive(NotificationCenter.default.publisher(for: .undoDrawing)) { _ in
                if !lines.isEmpty {
                    lines.removeLast()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleCoordinates)) { _ in
                showCoordinates.toggle()
            }
        /*
            .onReceive(NotificationCenter.default.publisher(for: .toggleMillimeters)) {  notification in
                print("Toggle Millimeters notification received! \(notification) Toggle: \(coord)")
            }
         */
            .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
                zoomLevel = min(zoomLevel + 0.25, 3.0)
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
                zoomLevel = max(zoomLevel - 0.25, 0.25)
            }
            .onReceive(NotificationCenter.default.publisher(for: .resetZoom)) { _ in
                zoomLevel = 1.0
            }
    }
}

extension View {
    func setupNotificationHandlers(
        lines: Binding<[Line]>,
        currentLine: Binding<Line>,
        currentCoordinates: Binding<CGPoint>,
        zoomLevel: Binding<CGFloat>,
        showCoordinates: Binding<Bool>,
        canvasSize: CGSize,
        onExport: @escaping () -> Void,
        onSave: @escaping () -> Void,
        onOpen: @escaping () -> Void
    ) -> some View {
        modifier(NotificationHandlerModifier(
            lines: lines,
            currentLine: currentLine,
            currentCoordinates: currentCoordinates,
            zoomLevel: zoomLevel,
            showCoordinates: showCoordinates,
            canvasSize: canvasSize,
            onExport: onExport,
            onSave: onSave,
            onOpen: onOpen
        ))
    }
}

struct Previews_ViewModifiers_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
