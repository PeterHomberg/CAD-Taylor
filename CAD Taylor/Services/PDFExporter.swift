// ============================================
// File: PDFExporter.swift
// PDF export functionality
// ============================================

import AppKit
import CoreGraphics
import PDFKit

class PDFExporter {
    static func exportToPDF(lines: [Line], canvasSize: CGSize) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "SwiftUI Canvas Drawing",
            kCGPDFContextAuthor: "Canvas App"
        ]
        
        // Create PDF context
        let mutableData = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: mutableData)!
        let pageRect = CGRect(origin: .zero, size: canvasSize)
        
        var mediaBox = pageRect
        let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, pdfMetaData as CFDictionary)!
        
        // Begin page
        pdfContext.beginPDFPage(nil)
        
        // WICHTIG: PDF-Koordinatensystem umkehren (Y-Achse spiegeln)
        // PDF hat Ursprung unten links, SwiftUI hat Ursprung oben links
        pdfContext.translateBy(x: 0, y: canvasSize.height)
        pdfContext.scaleBy(x: 1.0, y: -1.0)
 
        // Set up drawing context
        if #available(macOS 10.15, *) {
            pdfContext.setStrokeColor(NSColor.systemBlue.cgColor)
        } else {
            pdfContext.setStrokeColor(NSColor.blue.cgColor)
        }
        pdfContext.setLineWidth(3.0)
        pdfContext.setLineCap(.round)
        pdfContext.setLineJoin(.round)
        
        // Draw all lines
        for line in lines {
            if line.points.count > 1 {
                pdfContext.beginPath()
                pdfContext.move(to: line.points[0])
                for point in line.points.dropFirst() {
                    pdfContext.addLine(to: point)
                }
                pdfContext.strokePath()
            }
        }
        
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        return mutableData as Data
    }
    
    static func savePDFWithDialog(lines: [Line], canvasSize: CGSize) {
        let pdfData = exportToPDF(lines: lines, canvasSize: canvasSize)
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

