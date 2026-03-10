# Koordinateneingabe - Visueller Guide

## UI Layout

```
┌─────────────────────────────────────────────────────────────────────────┐
│  CAD Taylor App                                                          │
├──────────────────────────────────────────┬──────────────────────────────┤
│                                           │  Drawing Tools               │
│                                           ├──────────────────────────────┤
│                                           │  ○ Freehand                  │
│                                           │  ─────────────────           │
│                                           │  ○ Straight Line             │
│         Canvas Area                       │    Click start, then end     │
│      (White background)                   │  ─────────────────           │
│                                           │  ○ Circle Arc                │
│    [Gezeichnetes Rechteck]               │    Click three points        │
│                                           │  ─────────────────           │
│                                           │  ● Square  ← AKTIV           │
│                                           │    Click TL, drag to BR      │
│                                           ├──────────────────────────────┤
│                                           │  Rectangle Coordinates   mm  │
│                                           │  ┌──────────────────────┐   │
│                                           │  │Corner    X        Y  │   │
│                                           │  ├──────────────────────┤   │
│                                           │  │TL     [52.9]  [17.6]│   │
│                                           │  │TR     [211.7] [17.6]│   │
│                                           │  │BR     [211.7] [105.8]│   │
│                                           │  │BL     [52.9]  [105.8]│   │
│                                           │  └──────────────────────┘   │
│                                           │                              │
│                                           │  ┌──────────────────────┐   │
│                                           │  │ ✓ Apply Changes      │   │
│                                           │  └──────────────────────┘   │
│                                           │      ↑ Blau = Änderungen     │
├───────────────────────────────────────────┴──────────────────────────────┤
│ [Draw] [Select]  │  [Clear] [Export PDF] [Delete]    X: 150 px Y: 200 px│
└─────────────────────────────────────────────────────────────────────────┘
```

## Beispiel-Workflow

### 1. Rechteck zeichnen
```
User Action: Klickt auf Square-Button
Result:      Square-Button wird blau (aktiv)

User Action: Zieht Rechteck auf Canvas von (50, 20) bis (210, 110)
Result:      Rechteck wird gezeichnet
             Koordinatentabelle erscheint automatisch mit:
             TL: 50, 20
             TR: 210, 20
             BR: 210, 110
             BL: 50, 110
```

### 2. Koordinaten ändern
```
User Action: Klickt in TL X-Feld
Current:     "50"

User Action: Tippt "100"
Result:      X-Feld zeigt "100"
             Apply-Button wird blau (editierbar)
             Rechteck bleibt unverändert (noch nicht applied)

User Action: Klickt in TL Y-Feld
Current:     "20"

User Action: Tippt "30"
Result:      Y-Feld zeigt "30"
             Apply-Button bleibt blau
```

### 3. Änderungen übernehmen
```
User Action: Klickt "Apply Changes"
Result:      Rechteck wird neu gezeichnet mit:
             - Top-Left Ecke verschoben von (50, 20) zu (100, 30)
             - Andere Ecken bleiben relativ
             Apply-Button wird grau (keine Änderungen)
             Tabelle zeigt neue Werte
```

### 4. Einheiten umschalten
```
User Action: Menu → "Show in Millimeters" (⌘⇧M)
Result:      Alle Koordinaten werden umgerechnet:
             Vorher (px):  100, 30
             Nachher (mm): 35.3, 10.6
             
             Einheit-Label ändert sich: "px" → "mm"
```

## Interaktive Elemente

### TextField-Verhalten
```
┌──────────┐
│  [150]   │  ← Fokussiert (blauer Rand)
└──────────┘
   
Aktionen:
- Klick: Selektiert aktuellen Wert
- Tab: Springt zum nächsten Feld
- Enter: Behält Fokus (kein Apply)
- Tippen: Überschreibt Wert
```

### Apply-Button States
```
Grau (disabled):
┌────────────────────┐
│ ✓ Apply Changes    │  ← Keine Änderungen
└────────────────────┘

Blau (enabled):
┌────────────────────┐
│ ✓ Apply Changes    │  ← Hat Änderungen
└────────────────────┘     Klickbar!
```

### Eckpunkt-Namen
```
Canvas-Ansicht:         Tabelle:
    TL ─────── TR       TL = Top-Left
     │         │        TR = Top-Right
     │  Rect   │        BR = Bottom-Right
     │         │        BL = Bottom-Left
    BL ─────── BR
```

## Koordinaten-Konventionen

### Standard (Pixel)
```
┌─────────────────→ X-Achse (steigend nach rechts)
│
│   (0,0)        (200,0)
│     ┌─────────────┐
│     │             │
│     │   Canvas    │
│     │             │
│     └─────────────┘
│   (0,300)      (200,300)
↓
Y-Achse (steigend nach unten)
```

### Rechteck-Punkte Reihenfolge
```
points[0] = Top-Left (TL)
points[1] = Top-Right (TR)
points[2] = Bottom-Right (BR)
points[3] = Bottom-Left (BL)

Im Uhrzeigersinn, startend oben links
```

## Farb-Schema

```
Aktiv/Ausgewählt:  Blau (#007AFF)
Inaktiv:           Grau (#999999)
Hintergrund:       Weiß (#FFFFFF)
Border:            Hellgrau (#CCCCCC)
Text:              Schwarz (#000000)
Sekundär-Text:     Grau (#666666)
```

## Responsive Verhalten

### Sidebar-Breite: 280px
```
Zu klein für:
- Volle Namen ("Top-Left" → "TL")
- Breite Eingabefelder
- Mehr als 2 Spalten

Optimal für:
- 4 Zeilen Koordinaten
- Apply-Button
- Tools-Liste
```

### TextField-Größen
```
Corner-Name: 70px  (passt "TL", "TR", etc.)
X-Feld:      65px  (passt "999.9")
Y-Feld:      65px  (passt "999.9")
Gesamt:      ~210px (mit Spacing)
```

## Edge Cases - Visuelle Darstellung

### Kein Rechteck gezeichnet
```
┌──────────────────────────────┐
│  Rectangle Coordinates       │
├──────────────────────────────┤
│                              │
│  Draw a rectangle to edit    │
│  coordinates                 │
│                              │
└──────────────────────────────┘
     ↑ Grauer Hinweis-Text
```

### Mehrere Rechtecke
```
Aktuelles Verhalten:
- Zeigt LETZTES gezeichnetes Rechteck
- Andere Rechtecke nicht editierbar

Rechteck 1 (alt)   Rechteck 2 (neu) ← Wird in Tabelle gezeigt
     ▢                   ▢
```

### Zoom aktiv
```
Canvas gezoomt (150%):
- Koordinaten-Tabelle zeigt REALE Werte
- Nicht gezoomte Werte
- Z.B. bei 150% Zoom:
  - Canvas zeigt: Rechteck größer
  - Tabelle zeigt: Original-Koordinaten
```

## Tastatur-Shortcuts

```
⌘N     New Drawing (löscht alle Shapes)
⌘S     Save Drawing
⌘O     Open Drawing
⌘E     Export PDF
⌘Z     Undo (letztes Shape löschen)
⌘⇧K    Clear Canvas
⌘⇧M    Toggle Millimeters
Tab    Nächstes Feld in Tabelle
⇧Tab   Vorheriges Feld
```

## Beispiel-Szenarien

### Szenario 1: Präzises Rechteck erstellen
```
1. Square-Modus wählen
2. Beliebiges Rechteck zeichnen (ungefähr)
3. In Tabelle exakte Werte eingeben:
   TL: 100, 100
   TR: 300, 100
   BR: 300, 200
   BL: 100, 200
4. Apply Changes
Result: Perfektes 200x100px Rechteck
```

### Szenario 2: Rechteck verschieben
```
1. Alle Eckpunkte um gleiches Delta ändern
   TL: 100,100 → 150,150  (+50, +50)
   TR: 300,100 → 350,150  (+50, +50)
   BR: 300,200 → 350,250  (+50, +50)
   BL: 100,200 → 150,250  (+50, +50)
2. Apply Changes
Result: Rechteck um 50px nach rechts-unten verschoben
```

### Szenario 3: Größe ändern
```
1. Nur BR ändern (Ecke ziehen-Effekt)
   TL: 100,100 → 100,100  (unverändert)
   TR: 300,100 → 400,100  (+100 X)
   BR: 300,200 → 400,300  (+100 X, +100 Y)
   BL: 100,200 → 100,300  (+100 Y)
2. Apply Changes
Result: Rechteck breiter und höher
```

## Error States (für zukünftige Implementation)

```
Ungültige Eingabe:
┌──────────┐
│  [abc]   │  ← Rot umrandet
└──────────┘
   ↓ "Invalid number"

Außerhalb Canvas:
┌──────────┐
│  [9999]  │  ← Orange Warnung
└──────────┘
   ↓ "Outside canvas bounds"

Überlappende Punkte:
┌──────────┐
│  [100]   │  ← Gelbe Warnung
└──────────┘
   ↓ "Points overlapping"
```
