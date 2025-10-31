// ============================================
// File: DrawingSerializer.swift
// Save and load drawing files
// ============================================

import AppKit
import Foundation
import CoreGraphics

class DrawingSerializer {
    
    // Save drawing to file with dialog
    static func saveDrawingWithDialog(lines: [Line], canvasSize: CGSize) {
        let document = DrawingDocument(lines: lines, canvasSize: canvasSize)
        
        guard let jsonData = try? JSONEncoder().encode(document) else {
            print("Error encoding drawing data")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save Drawing"
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "drawing_\(Date().timeIntervalSince1970).json"
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try jsonData.write(to: url)
                    print("Drawing saved successfully: \(url.lastPathComponent)")
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    print("Error saving drawing: \(error)")
                }
            }
        }
    }
    
    // Open drawing from file with dialog
    static func openDrawingWithDialog(completion: @escaping (Result<(lines: [Line], canvasSize: CGSize), Error>) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Open Drawing"
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                loadDrawing(from: url, completion: completion)
            }
        }
    }
    
    // Load drawing from URL
    static func loadDrawing(from url: URL, completion: @escaping (Result<(lines: [Line], canvasSize: CGSize), Error>) -> Void) {
        do {
            let jsonData = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(DrawingDocument.self, from: jsonData)
            let lines = document.toLines()
            let canvasSize = document.toCanvasSize()
            completion(.success((lines: lines, canvasSize: canvasSize)))
            print("Drawing loaded successfully from: \(url.lastPathComponent)")
        } catch {
            completion(.failure(error))
            print("Error loading drawing: \(error)")
        }
    }
    
    // Export to JSON string (for debugging or other uses)
    static func exportToJSON(lines: [Line], canvasSize: CGSize) -> String? {
        let document = DrawingDocument(lines: lines, canvasSize: canvasSize)
        guard let jsonData = try? JSONEncoder().encode(document),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}
