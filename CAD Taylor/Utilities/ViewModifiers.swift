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

// MARK: - Button Role

enum ToolbarButtonRole {
    case `default`
    case primary
    case confirm
    case destructive
}

// MARK: - ButtonStyle

struct ToolbarButtonStyle: ButtonStyle {
    let role: ToolbarButtonRole
    @State private var isHovered = false

    private var backgroundColor: Color {
        switch role {
        case .default:     return Color(NSColor.controlBackgroundColor)
        case .primary:     return Color(hex: "#378ADD")
        case .confirm:     return Color(hex: "#1D9E75")
        case .destructive: return Color(hex: "#E24B4A")
        }
    }

    private var hoveredBackgroundColor: Color {
        switch role {
        case .default:     return Color(NSColor.selectedControlColor)
        case .primary:     return Color(hex: "#185FA5")
        case .confirm:     return Color(hex: "#0F6E56")
        case .destructive: return Color(hex: "#A32D2D")
        }
    }

    private var foregroundColor: Color {
        switch role {
        case .default: return Color(NSColor.labelColor)
        default:       return .white
        }
    }

    private var borderColor: Color {
        switch role {
        case .default:     return Color(NSColor.separatorColor)
        case .primary:     return Color(hex: "#0C447C")
        case .confirm:     return Color(hex: "#0F6E56")
        case .destructive: return Color(hex: "#A32D2D")
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .medium))
            .foregroundColor(foregroundColor)
            .lineLimit(1)
            // .fixedSize(horizontal: true, vertical: false)  ← REMOVE THIS
            .frame(minWidth: 0, maxWidth: .infinity)          // ← adapt to available space
            .padding(.horizontal, 8)                          // ← reduced from 11
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isHovered ? hoveredBackgroundColor : backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(borderColor, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .onHover { isHovered = $0 }
    }
    
}
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}
// MARK: - View Extension

extension View {
    func toolbarButton(role: ToolbarButtonRole = .default) -> some View {
        self.buttonStyle(ToolbarButtonStyle(role: role))
    }
}
