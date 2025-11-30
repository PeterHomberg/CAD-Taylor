// ============================================
// File: ViewModifiers.swift
// Custom view modifiers for notification handling
// Updated for shape-based system
// ============================================

import SwiftUI

struct NotificationHandlerModifier: ViewModifier {
    @Binding var shapes: [Shape]
    @Binding var currentShape: Shape?
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
                shapes.removeAll()
                currentShape = nil
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
                shapes.removeAll()
                currentShape = nil
                currentCoordinates = CGPoint.zero
            }
            .onReceive(NotificationCenter.default.publisher(for: .undoDrawing)) { _ in
                if !shapes.isEmpty {
                    shapes.removeLast()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleCoordinates)) { _ in
                showCoordinates.toggle()
            }
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
        shapes: Binding<[Shape]>,
        currentShape: Binding<Shape?>,
        currentCoordinates: Binding<CGPoint>,
        zoomLevel: Binding<CGFloat>,
        showCoordinates: Binding<Bool>,
        canvasSize: CGSize,
        onExport: @escaping () -> Void,
        onSave: @escaping () -> Void,
        onOpen: @escaping () -> Void
    ) -> some View {
        modifier(NotificationHandlerModifier(
            shapes: shapes,
            currentShape: currentShape,
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
