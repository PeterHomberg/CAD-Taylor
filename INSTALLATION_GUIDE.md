# Koordinateneingabe für Rechtecke - Integration

## Übersicht

Diese Aktualisierung fügt eine **manuelle Koordinateneingabe-Tabelle** für Rectangle-Shapes hinzu. Die Tabelle erscheint automatisch in der DrawingToolbar wenn der Square-Modus aktiv ist und mindestens ein Rechteck gezeichnet wurde.

## Neue Features

### 📊 Koordinaten-Tabelle
- **4 editierbare Eckpunkte**: Top-Left (TL), Top-Right (TR), Bottom-Right (BR), Bottom-Left (BL)
- **X/Y Koordinaten** für jeden Eckpunkt einzeln editierbar
- **Automatische Einheiten-Umrechnung**: Zwischen Pixeln und Millimetern
- **Apply-Button**: Übernimmt Änderungen nur auf expliziten Klick
- **Smart State Management**: Button aktiviert sich nur bei tatsächlichen Änderungen

## Geänderte Dateien

### 1. **Shape.swift** → `Shape_Updated.swift`
**Neue Features:**
- `NamedPoint` Struktur für benannte Koordinatenpunkte
- `cornerPoints` Property: Gibt Array von NamedPoints für Rechtecke zurück
- `updateCornerPoints()` Methode: Aktualisiert alle 4 Eckpunkte auf einmal

**Änderungen:**
```swift
// NEU: Named Point Struktur
struct NamedPoint: Identifiable {
    let id = UUID()
    let name: String
    var point: CGPoint
}

// NEU: In Shape struct
var cornerPoints: [NamedPoint]? {
    guard type == .rectangle, points.count == 4 else { return nil }
    return [
        NamedPoint(name: "Top-Left", point: points[0]),
        NamedPoint(name: "Top-Right", point: points[1]),
        NamedPoint(name: "Bottom-Right", point: points[2]),
        NamedPoint(name: "Bottom-Left", point: points[3])
    ]
}

// NEU: Update Methode
mutating func updateCornerPoints(_ namedPoints: [NamedPoint]) {
    guard type == .rectangle, namedPoints.count == 4 else { return }
    self.points = namedPoints.map { $0.point }
}
```

### 2. **DrawingToolbar.swift** → `DrawingToolbar_with_CoordinateInput.swift`
**Komplett überarbeitet mit:**
- Neue Bindings: `shapes` und `showInMillimeters`
- `CoordinateInputSection`: Neue View für die Koordinatentabelle
- `CoordinateRow`: Einzelne Zeile mit X/Y Textfeldern
- Automatische Anzeige des letzten gezeichneten Rechtecks
- State Management für "Apply Changes"

### 3. **DrawingCanvasView.swift** → `DrawingCanvasView_Updated.swift`
**Minimale Änderung:**
```swift
// ALT:
DrawingToolbar(selectedMode: $selectedDrawingMode)

// NEU:
DrawingToolbar(
    selectedMode: $selectedDrawingMode,
    shapes: $shapes,
    showInMillimeters: $showInMillimeters
)
```

## Installation

### Schritt 1: Backup erstellen
Sichern Sie Ihre aktuellen Dateien:
- `Models/Shape.swift`
- `Views/DrawingToolbar.swift`
- `Views/DrawingCanvasView.swift`

### Schritt 2: Dateien ersetzen

In Xcode:

1. **Shape.swift ersetzen:**
   - Öffnen Sie `Models/Shape.swift`
   - Ersetzen Sie den kompletten Inhalt mit `Shape_Updated.swift`

2. **DrawingToolbar.swift ersetzen:**
   - Öffnen Sie `Views/DrawingToolbar.swift`
   - Ersetzen Sie den kompletten Inhalt mit `DrawingToolbar_with_CoordinateInput.swift`

3. **DrawingCanvasView.swift aktualisieren:**
   - Öffnen Sie `Views/DrawingCanvasView.swift`
   - Finden Sie Zeile ~207: `DrawingToolbar(selectedMode: $selectedDrawingMode)`
   - Ersetzen Sie mit:
     ```swift
     DrawingToolbar(
         selectedMode: $selectedDrawingMode,
         shapes: $shapes,
         showInMillimeters: $showInMillimeters
     )
     ```

### Schritt 3: Build & Test
1. Build das Projekt (⌘B)
2. Testen Sie:
   - Zeichnen Sie ein Rechteck im Square-Modus
   - Die Koordinatentabelle sollte automatisch erscheinen
   - Editieren Sie X oder Y Werte
   - Klicken Sie "Apply Changes"
   - Das Rechteck sollte sich aktualisieren

## Verwendung

### Koordinaten manuell eingeben:

1. **Rechteck zeichnen:**
   ```
   Draw-Modus → Square auswählen → Rechteck aufziehen
   ```

2. **Koordinaten editieren:**
   - Die Tabelle erscheint automatisch in der rechten Sidebar
   - Zeigt 4 Zeilen: TL, TR, BR, BL (Top-Left, Top-Right, etc.)
   - Jede Zeile hat X und Y Felder
   - Tippen Sie neue Werte ein

3. **Änderungen übernehmen:**
   - "Apply Changes" Button wird blau wenn Änderungen vorliegen
   - Klicken um die neuen Koordinaten zu übernehmen
   - Das Rechteck wird sofort aktualisiert

### Koordinaten-Format:

**Pixel-Modus (px):**
- Ganze Zahlen
- Beispiel: `150` oder `200`

**Millimeter-Modus (mm):**
- Eine Dezimalstelle
- Beispiel: `52.9` oder `70.6`
- Umschalten: Menu → "Show in Millimeters" (⌘⇧M)

## Technische Details

### State Management Flow
```
User editiert TextField
    ↓
CoordinateRow.updateCoordinate()
    ↓
onUpdate(newPoint) → editedPoints aktualisiert
    ↓
isEditing = true (Apply-Button aktiviert)
    ↓
User klickt "Apply Changes"
    ↓
applyChanges() → updatedShape.updateCornerPoints()
    ↓
onUpdate(updatedShape) → Toolbar callback
    ↓
DrawingCanvasView.updateShape()
    ↓
shapes[index] = updatedShape
    ↓
Canvas neu gerendert ✓
```

### Koordinaten-Transformation
```swift
// Pixel → Millimeter
let mm = CoordinateConverter.pointsToMillimeters(pixels)

// Millimeter → Pixel
let px = CoordinateConverter.millimetersToPoints(mm)

// Format für Display
xText = String(format: showInMillimeters ? "%.1f" : "%.0f", value)
```

### Wichtige Design-Entscheidungen

1. **Letztes Rechteck:** Die Tabelle zeigt immer das zuletzt gezeichnete Rechteck
   - Grund: Einfachheit, keine zusätzliche UI für Shape-Auswahl nötig
   - Alternative für später: Dropdown zur Auswahl verschiedener Rechtecke

2. **Apply-Button statt Auto-Update:** Änderungen werden nicht sofort übernommen
   - Grund: User kann mehrere Koordinaten ändern bevor Apply
   - Verhindert "Flackern" während der Eingabe

3. **Abgekürzte Namen (TL, TR, BR, BL):** Statt "Top-Left" nur "TL"
   - Grund: Platzeinsparung in der schmalen Sidebar (280px)
   - Immer noch klar verständlich

4. **Monospace Font für Zahlen:** Bessere Ausrichtung und Lesbarkeit

## Bekannte Einschränkungen

1. **Nur das letzte Rechteck editierbar**
   - Lösung für später: Dropdown oder Liste aller Rechtecke

2. **Keine Validierung**
   - Negative Werte möglich
   - Überlappende Punkte möglich
   - Punkte außerhalb Canvas möglich

3. **Keine Constraints**
   - Kein "Lock Width" oder "Lock Height"
   - Kein Snap-to-Grid

## Zukünftige Erweiterungen

Mögliche Verbesserungen:
- [ ] Dropdown zur Auswahl welches Rechteck editiert wird
- [ ] Koordinaten für andere Shape-Types (Lines, Circles)
- [ ] Input-Validierung (min/max Werte)
- [ ] Constraint-System (feste Breite/Höhe)
- [ ] Relative Koordinaten (Delta-Eingabe)
- [ ] Undo/Redo für Koordinatenänderungen
- [ ] Breite/Höhe direkt editieren statt Eckpunkte

## Troubleshooting

### Problem: Tabelle erscheint nicht
**Lösung:**
1. Prüfen Sie ob Square-Modus aktiv ist (Button blau?)
2. Zeichnen Sie ein Rechteck
3. Prüfen Sie Console für Fehler

### Problem: Apply-Button bleibt grau
**Lösung:**
1. Ändern Sie tatsächlich einen Wert (nicht nur selektieren)
2. `isEditing` State sollte auf `true` gesetzt werden
3. Console prüfen: `print("isEditing: \(isEditing)")`

### Problem: Koordinaten werden nicht übernommen
**Lösung:**
1. Prüfen ob "Apply Changes" geklickt wurde
2. Console prüfen für `updateShape()` Aufrufe
3. Prüfen ob `shapes.firstIndex(where:)` das richtige Shape findet

### Problem: Einheiten-Umrechnung falsch
**Lösung:**
1. Prüfen `CoordinateConverter.swift`:
   - 72 points/inch
   - 25.4 mm/inch
2. Prüfen ob `showInMillimeters` korrekt übergeben wird

## Support

Bei Problemen:
1. Console-Output prüfen
2. Breakpoints in `updateCoordinate()` und `applyChanges()` setzen
3. Prüfen ob alle Bindings korrekt sind

## Änderungshistorie

**Version 1.0** (2025-12-23)
- Initiale Implementation der Koordinateneingabe
- Support für Rectangle-Shapes
- Automatische Einheiten-Umrechnung
- Apply-Button mit State Management
