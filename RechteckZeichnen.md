# RechteckZeichnen

Ablauf des Zeichnen eines Rechtecks. Code von Claude 2026-03-09

## Overview

<!--@START_MENU_TOKEN@-->Text<!--@END_MENU_TOKEN@-->

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- Ablauf: Rechteck zeichnen

1. Maustaste drücken — DragGesture.onChanged (erster Aufruf)
In DrawingCanvasView.swift löst die DragGesture aus:
swift.onChanged { value in
    handleGesture(location: value.location, phase: .changed, ...)
}
handleGesture korrigiert die Koordinaten für den Zoom und ruft auf:
swiftcase .draw:
    handleDrawing(at: adjustedLocation)
In handleDrawing greift der .square-Fall:
swiftcase .square:
    if temporaryShape == nil {
        temporaryShape = TemporaryShape(mode: .square, points: [location])
    }
Da temporaryShape noch nil ist, wird ein neues TemporaryShape mit dem Startpunkt (Mausklick-Position) erzeugt. Noch kein Rechteck sichtbar.

2. Maus ziehen — DragGesture.onChanged (alle weiteren Aufrufe)
Bei jeder Mausbewegung kommt erneut .onChanged. Diesmal ist temporaryShape nicht mehr nil:
swiftcase .square:
    } else {
        temporaryShape?.points = [temporaryShape!.points[0], location]
    }
Der Startpunkt bleibt fest, der zweite Punkt wird auf die aktuelle Mausposition aktualisiert. TemporaryShape hat jetzt immer genau zwei Punkte: gegenüberliegende Ecken des Rechtecks.
Das rect-Property von TemporaryShape berechnet daraus live ein CGRect:
swiftvar rect: CGRect? {
    guard points.count == 2 else { return nil }
    return CGRect(
        x: min(points[0].x, points[1].x),
        y: min(points[0].y, points[1].y),
        width: abs(points[1].x - points[0].x),
        height: abs(points[1].y - points[0].y)
    )
}
In DrawingNSView.draw() wird das sofort gerendert:
swiftif let temp = temporaryShape {
    if temp.mode == .square, let rect = temp.rect {
        ctx.stroke(rect)   // gestricheltes Rechteck als Vorschau
    }
}
Der Benutzer sieht ein gestricheltes Vorschau-Rechteck, das mit der Maus wächst.

3. Maustaste loslassen — DragGesture.onEnded
swift.onEnded { value in
    handleGesture(location: value.location, phase: .ended, ...)
}
Das ruft handleDrawingEnd(at:) auf:
swiftcase .square:
    if let temp = temporaryShape, temp.points.count == 2, let rect = temp.rect {
        var shape = Shape(type: .rectangle)
        shape.points = [
            CGPoint(x: rect.minX, y: rect.minY),  // oben-links
            CGPoint(x: rect.maxX, y: rect.minY),  // oben-rechts
            CGPoint(x: rect.maxX, y: rect.maxY),  // unten-rechts
            CGPoint(x: rect.minX, y: rect.maxY)   // unten-links
        ]
        shapes.append(shape)
        temporaryShape = nil
    }
Drei Dinge passieren:

Aus dem CGRect werden vier explizite Eckpunkte berechnet und im Shape gespeichert
Das fertige Shape(type: .rectangle) wird in shapes eingetragen
temporaryShape = nil — die Vorschau verschwindet

DrawingNSView.draw() zeichnet das Rechteck jetzt über den normalen shapes-Loop mit durchgezogener Linie:
swiftcase .rectangle:
    ctx.move(to: shape.points[0])
    for point in shape.points.dropFirst() {
        ctx.addLine(to: point)
    }
    ctx.closePath()
    ctx.strokePath()
```

---

### Überblick
```
Maustaste drücken   →  TemporaryShape mit Startpunkt erstellt
Maus ziehen         →  TemporaryShape.points[1] aktualisiert → gestrichelte Vorschau
Maustaste loslassen →  Shape(rectangle) mit 4 Punkten → in shapes[] gespeichert
                       TemporaryShape = nil
Der Wechsel von TemporaryShape zu Shape ist auch der Wechsel von Vorschau (gestrichelt, flüchtig) zu fertigem Objekt (durchgezogen, selektierbar, speicherbar).
