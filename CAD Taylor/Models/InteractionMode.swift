// ============================================
// File: InteractionMode.swift
// Interaction modes for drawing and editing
// ============================================

import Foundation

enum InteractionMode {
    case draw      // Zeichnen neuer Shapes
    case select    // Auswählen und Bearbeiten von Shapes
}

enum EditMode {
    case move           // Ganzes Shape verschieben
    case resize         // Größe ändern (für rectangle, straightLine)
    case editPoints     // Einzelne Punkte bearbeiten
}
