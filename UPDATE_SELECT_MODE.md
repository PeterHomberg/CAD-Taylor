# Update: Koordinateneingabe im Select-Modus

## Neue Features

Die Koordinateneingabe ist jetzt auch im **Select-Modus** verfügbar! 🎉

### Was ist neu?

✅ **Koordinatentabelle in EditToolbar**
- Erscheint automatisch wenn ein Rechteck ausgewählt ist
- Gleiche Funktionalität wie im Draw-Modus
- Echtzeit-Updates beim Editieren

✅ **Intelligente Anzeige**
- Zeigt nur bei Rectangle-Shapes die Koordinatentabelle
- Für andere Shapes (Lines, Arcs): Info-Box mit "Coming soon"
- Keine Auswahl: Standard "No Shape Selected" Nachricht

## Geänderte Dateien

### 1. EditToolbar.swift → EditToolbar_with_CoordinateInput.swift

**Neue Bindings:**
```swift
@Binding var shapes: [Shape]
@Binding var selectedShapeID: UUID?
@Binding var showInMillimeters: Bool
```

**Neue Features:**
- `selectedShape` computed property
- `CoordinateInputSection` für Rechtecke
- Info-Box für andere Shape-Typen
- `updateShape()` Methode

### 2. DrawingCanvasView.swift → DrawingCanvasView_Final.swift

**Geändert:**
```swift
// ALT:
EditToolbar(
    editMode: $editMode,
    hasSelection: selectedShapeID != nil
)

// NEU:
EditToolbar(
    editMode: $editMode,
    shapes: $shapes,
    selectedShapeID: $selectedShapeID,
    showInMillimeters: $showInMillimeters,
    hasSelection: selectedShapeID != nil
)
```

## Installation

### Schritt 1: EditToolbar.swift ersetzen

1. Öffnen Sie `Views/EditToolbar.swift` in Xcode
2. Ersetzen Sie den kompletten Inhalt mit `EditToolbar_with_CoordinateInput.swift`

### Schritt 2: DrawingCanvasView.swift aktualisieren

1. Öffnen Sie `Views/DrawingCanvasView.swift`
2. Finden Sie die EditToolbar Einbindung (ca. Zeile 213)
3. Ersetzen Sie:
   ```swift
   EditToolbar(
       editMode: $editMode,
       hasSelection: selectedShapeID != nil
   )
   ```
   
   Mit:
   ```swift
   EditToolbar(
       editMode: $editMode,
       shapes: $shapes,
       selectedShapeID: $selectedShapeID,
       showInMillimeters: $showInMillimeters,
       hasSelection: selectedShapeID != nil
   )
   ```

### Schritt 3: Build & Test

1. Build (⌘B)
2. Testen Sie:
   - Zeichnen Sie ein Rechteck
   - Wechseln Sie zu Select-Modus
   - Klicken Sie auf das Rechteck
   - Koordinatentabelle sollte erscheinen
   - Editieren Sie Koordinaten
   - Apply Changes → Rechteck wird aktualisiert

## Workflow: Koordinaten editieren im Select-Modus

### Szenario 1: Bestehendes Rechteck anpassen

```
1. Select-Modus aktivieren
   [Select] Button klicken (wird blau)

2. Rechteck auswählen
   Klick auf beliebiges Rechteck
   → Rechteck wird mit blauem Rand markiert
   → Koordinatentabelle erscheint rechts

3. Koordinaten ändern
   TL: 100, 50  →  120, 60  (z.B.)
   → Apply Changes wird blau

4. Übernehmen
   [Apply Changes] klicken
   → Rechteck springt zur neuen Position
```

### Szenario 2: Zwischen Shapes wechseln

```
1. Rechteck A ausgewählt
   → Koordinatentabelle zeigt Werte von A
   
2. Klick auf Rechteck B
   → Selektion wechselt zu B
   → Koordinatentabelle zeigt sofort Werte von B
   → Nicht-übernommene Änderungen von A gehen verloren
   
3. Editieren und Apply
   → Nur B wird aktualisiert
```

### Szenario 3: Shape-Type Info

```
1. Select-Modus
2. Klick auf Line (Straight Line)
   → Blaue Info-Box erscheint:
   ┌────────────────────────────┐
   │ ℹ️ Selected Shape          │
   │ Type: Straight Line        │
   │ Coordinate editing for     │
   │ lines coming soon          │
   └────────────────────────────┘
```

## UI Vergleich

### Draw-Modus (vorher):
```
┌─────────────────────────┐
│ Drawing Tools           │
├─────────────────────────┤
│ ○ Freehand              │
│ ○ Straight Line         │
│ ○ Circle Arc            │
│ ● Square                │
├─────────────────────────┤
│ Rectangle Coordinates   │
│ [Koordinatentabelle]    │ ← Letztes Rechteck
│ [Apply Changes]         │
└─────────────────────────┘
```

### Select-Modus (NEU!):
```
┌─────────────────────────┐
│ Edit Tools              │
├─────────────────────────┤
│ ● Move                  │
│ ○ Resize                │
│ ○ Edit Points           │
├─────────────────────────┤
│ Rectangle Coordinates   │
│ [Koordinatentabelle]    │ ← Ausgewähltes Rechteck
│ [Apply Changes]         │
├─────────────────────────┤
│ Shortcuts               │
│ Esc: Deselect          │
│ Delete: Remove shape    │
└─────────────────────────┘
```

## Wichtige Unterschiede

### Draw-Modus vs. Select-Modus

| Aspekt | Draw-Modus | Select-Modus |
|--------|------------|--------------|
| Welches Shape | Letztes gezeichnete | Aktuell ausgewähltes |
| Selektion sichtbar | Nein | Ja (blauer Rand) |
| Wechsel zwischen Shapes | Neu zeichnen | Klick auf Shape |
| Shape verschieben | Nur via Koordinaten | Move-Modus oder Koordinaten |
| Shape resizen | Nur via Koordinaten | Resize-Handles oder Koordinaten |

## Vorteile der Select-Modus Integration

✅ **Präzision**: Exakte Koordinaten für bereits gezeichnete Shapes
✅ **Flexibilität**: Wahl zwischen Maus-Drag oder Koordinaten-Eingabe
✅ **Workflow**: Zeichnen → Grob positionieren → Fein-Justierung per Koordinaten
✅ **Konsistenz**: Gleiche UI in beiden Modi

## Beispiel-Workflows

### Workflow 1: Schnelles Layout mit Feinabstimmung
```
1. Draw-Modus: Mehrere Rechtecke grob zeichnen
2. Select-Modus: Jedes Rechteck einzeln auswählen
3. Für jedes: Exakte Koordinaten eingeben
4. Resultat: Präzise ausgerichtetes Layout
```

### Workflow 2: Symmetrische Platzierung
```
1. Ein Rechteck zeichnen bei TL: 100,100
2. Select-Modus: Rechteck auswählen
3. Koordinaten notieren
4. Zweites Rechteck zeichnen
5. Select-Modus: Koordinaten spiegeln
   Wenn Rechteck 1 bei X=100: Rechteck 2 bei X=300
6. Resultat: Perfekt symmetrisch
```

### Workflow 3: Raster-Ausrichtung
```
1. Rechtecke beliebig zeichnen
2. Select-Modus durchgehen
3. Jedes auf Raster ausrichten:
   X: auf 50er-Schritte (50, 100, 150, ...)
   Y: auf 50er-Schritte
4. Resultat: Sauberes Grid-Layout
```

## Edge Cases

### Case 1: Selektion verlieren während Edit
```
Problem: User editiert Koordinaten, klickt dann woanders
Verhalten: 
- Nicht-übernommene Änderungen gehen verloren
- Neue Selektion zeigt eigene Koordinaten
Lösung: Immer "Apply Changes" klicken vor Wechsel!
```

### Case 2: Shape löschen während in Tabelle
```
Problem: Shape ist selektiert, User löscht es
Verhalten:
- Shape verschwindet
- selectedShapeID wird nil
- Koordinatentabelle verschwindet
- "No Shape Selected" erscheint
```

### Case 3: Mehrere Rechtecke übereinander
```
Problem: Zwei Rechtecke an gleicher Stelle
Lösung:
- Click selektiert oberstes (neuestes)
- Für unteres: Oberes verschieben oder löschen
```

## Keyboard Shortcuts (erweitert)

```
Im Select-Modus:

Esc          Deselektieren
Delete       Shape löschen
Tab          Nächstes Feld in Koordinatentabelle
⇧Tab         Vorheriges Feld
Enter        Bleibt in Feld (kein Auto-Apply)

Springen zwischen Modi:
(keine Shortcuts definiert - über Buttons)
```

## Troubleshooting

### Problem: Tabelle erscheint nicht im Select-Modus
**Checkliste:**
- [ ] Ist ein Shape ausgewählt? (blauer Rand sichtbar?)
- [ ] Ist es ein Rechteck? (andere Shapes zeigen Info-Box)
- [ ] Build erfolgreich? (keine Compiler-Fehler)

**Debug:**
```swift
// In EditToolbar, füge hinzu für Testing:
.onAppear {
    print("EditToolbar: hasSelection = \(hasSelection)")
    print("EditToolbar: selectedShape = \(selectedShape?.type ?? .none)")
}
```

### Problem: Koordinaten werden nicht übernommen
**Lösung:**
1. Apply Changes geklickt?
2. Console prüfen für `updateShape` Aufrufe
3. Prüfen ob Shape-ID matches:
   ```swift
   print("Updating shape ID: \(updatedShape.id)")
   print("Shapes array contains: \(shapes.map { $0.id })")
   ```

### Problem: Falsche Koordinaten nach Mode-Wechsel
**Ursache:** Draw-Modus zeigt letztes, Select-Modus zeigt ausgewähltes
**Lösung:** Das ist korrektes Verhalten - unterschiedliche Kontexte

## Zukünftige Erweiterungen

Mögliche Features:
- [ ] Koordinaten für Lines (2 Punkte: Start, End)
- [ ] Koordinaten für Circles (Center, Radius)
- [ ] Multi-Select: Mehrere Shapes gleichzeitig verschieben
- [ ] Relative Koordinaten (Delta-Werte)
- [ ] History: Letzte 5 Koordinaten-Werte
- [ ] Copy/Paste Koordinaten zwischen Shapes

## Zusammenfassung

Die Koordinateneingabe funktioniert jetzt in **beiden Modi**:

| Feature | Draw-Modus | Select-Modus |
|---------|------------|--------------|
| Verfügbar für | Rectangle | Rectangle |
| Zeigt Shape | Letztes gezeichnete | Aktuell ausgewähltes |
| Shape sichtbar markiert | ❌ | ✅ (blauer Rand) |
| Andere Shapes | Keine Info | "Coming soon" Info |
| Koordinaten editieren | ✅ | ✅ |
| Apply Changes | ✅ | ✅ |
| Einheiten-Umschaltung | ✅ | ✅ |

**Jetzt installieren und testen!** 🚀
