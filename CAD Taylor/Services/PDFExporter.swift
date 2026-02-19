// ============================================
// File: PDFExporter.swift
// PDF export functionality
// ============================================

import AppKit
import CoreGraphics
import PDFKit

class PDFExporter {
    // Neue Methode die mit Shapes arbeitet
    private var context: CGContext
    private let pageHeight: CGFloat
    private let pdfData = NSMutableData()
    private let marginMM = CGFloat(5)
    let pdfMetaData = [
        kCGPDFContextCreator: "SwiftUI Canvas Drawing",
        kCGPDFContextAuthor: "Canvas App"
    ]

    
    init?(pageSize: CGSize) {
        var pageSizePts = pageSize
        pageSizePts.height = pageSize.height.pts
        pageSizePts.width = pageSize.width.pts
        var mediaBox = CGRect(origin: .zero, size: pageSizePts)
        self.pageHeight = pageSize.height.pts
        
        guard let dataConsumer = CGDataConsumer(data: pdfData),
              let ctx = CGContext(consumer: dataConsumer, mediaBox: &mediaBox, pdfMetaData as CFDictionary) else {
            return nil
        }
        self.context = ctx
        // Create PDF context
        // Set up drawing context
        self.context.setStrokeColor(NSColor.black.cgColor)
        self.context.setLineWidth(3.0)
        self.context.setLineCap(.round)
        self.context.setLineJoin(.round)
    }

    func beginPage() {
        context.beginPDFPage(nil)
        // WICHTIG: PDF-Koordinatensystem umkehren (Y-Achse spiegeln)
        // PDF hat Ursprung unten links, SwiftUI hat Ursprung oben links
        self.context.translateBy(x: 0, y: pageHeight)
        self.context.scaleBy(x: 1.0, y: -1.0)

    }
    
    func endPage() {
        context.endPDFPage()
    }
    func finish() -> Data {
        context.closePDF()
        return pdfData as Data
    }
    func exportToPDF(shapes: [Shape]) -> Data {
        beginPage()
        // Draw all shapes
        for shape in shapes {
            if shape.points.count > 1 {
                context.beginPath()
                context.move(to: shape.points[0])
                
                for point in shape.points.dropFirst() {
                    context.addLine(to: point)
                }
                
                // WICHTIG: Für Rechtecke muss der Pfad geschlossen werden
                // um die letzte Linie zurück zum Startpunkt zu zeichnen
                if shape.type == .rectangle {
                    context.closePath()
                }
                
                context.strokePath()
            }
        }
        endPage()
        return finish()
    }
    

    
    // Neue Methode mit Shapes
   func savePDFWithDialog( shapes: [Shape]) {
        let pdfData = exportToPDF(shapes: shapes)
        let savePanel = NSSavePanel()
        
        savePanel.title = "Save Canvas Drawing"
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "canvas_drawing_\(Date().timeIntervalSince1970).pdf"
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try pdfData.write(to: url)
                    print("PDF saved successfully: \(url.lastPathComponent)")
                    
                    // Show in Finder
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    print("Error saving PDF: \(error)")
                }
            }
        }
    }
    

    static func openPDFWithDialog(completion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        
        openPanel.title = "Open PDF File"
        openPanel.allowedContentTypes = [.pdf]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { response in
            if response == .OK {
                completion(openPanel.url)
            } else {
                completion(nil)
            }
        }
    }
}

