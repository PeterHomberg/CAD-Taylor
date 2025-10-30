// ============================================
// File: NotificationNames.swift
// Notification name extensions for menu commands
// ============================================

import Foundation

extension Notification.Name {
    static let newDrawing = Notification.Name("newDrawing")

    static let savePDF = Notification.Name("savePDF")
    static let clearCanvas = Notification.Name("clearCanvas")
    static let undoDrawing = Notification.Name("undoDrawing")
    static let toggleCoordinates = Notification.Name("toggleCoordinates")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let resetZoom = Notification.Name("resetZoom")
}
