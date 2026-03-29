// ============================================
// File: DrawingSerializer.swift
// Save and load drawing files
// ============================================

import AppKit
import Foundation
import CoreGraphics

class DrawingSerializer {
    
    // NEU: Save shapes with dialog
    static func saveDrawingWithDialog(shapes: [Shape], canvasSize: CGSize) {
        let document = DrawingDocument(shapes: shapes, canvasSize: canvasSize)
        
        guard let jsonData = try? JSONEncoder().encode(document) else {
            print("Error encoding drawing data")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save Drawing"
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "drawing_\(Date().timeIntervalSince1970).json"
        savePanel.canCreateDirectories = true
        savePanel.allowsOtherFileTypes = false
        savePanel.isExtensionHidden = false
        
        // Enable overwriting existing files
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    // Write with .atomic option to safely overwrite
                    try jsonData.write(to: url, options: .atomic)
                    print("Drawing saved successfully: \(url.lastPathComponent)")
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    print("Error saving drawing: \(error)")
                    // Show error alert
                    let alert = NSAlert()
                    alert.messageText = "Save Failed"
                    alert.informativeText = "Could not save the drawing: \(error.localizedDescription)"
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
    
    // NEU: Open drawing with shapes support
    static func openDrawingWithDialog(completion:
                                      @escaping (Result<(shapes: [Shape],
                                                         canvasSize: CGSize),
                                                 Error>,URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Open Drawing"
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        
        // MARK: - closure calling closure concept
        /*
        openPanel.begin { response in          // closure A — called by macOS when user picks file
            loadDrawing(from: url) { result in // closure B — called by loadDrawing when file is decoded
                completion(result, url)        // closure C — this IS the { result, url in } in your view
            }
        }
        ```

        **Step by step:**
        ```
        1. openPanel.begin { response in ... }
           │
           │  macOS shows the file picker to the user
           │  user picks a file and clicks "Open"
           │  macOS calls closure A with response = .OK
           │
           ▼
        2. if response == .OK, let url = openPanel.url
           │
           │  confirms user didn't cancel
           │  extracts the file URL the user chose
           │
           ▼
        3. loadDrawing(from: url) { result in ... }
           │
           │  reads the file from disk
           │  decodes the JSON into a DrawingDocument
           │  calls closure B with either:
           │      .success((shapes: [...], canvasSize: ...))
           │      .failure(someError)
           │
           ▼
        4. completion(result, url)
           │
           │  "completion" is the { result, url in ... } closure
           │  defined back in your view's openDrawing()
           │  calling completion() is like calling that closure directly
           │  passing it both result (from loadDrawing) and url (from openPanel)
           │
           ▼
        5. DrawingSerializer.openDrawingWithDialog { result, url in
               switch result {
               case .success(let data):
                   shapes = data.shapes        // update the view
                   canvasSize = data.canvasSize
                   ...
                   NSDocumentController.shared.noteNewRecentDocumentURL(url)
               case .failure(let error):
                   print("Failed: \(error)")
               }
           }
        ```

        **The closure ownership — who holds what:**
        ```
        openDrawingWithDialog(completion: { result, url in ... })
        │                     │
        │                     └── YOUR closure, passed in as "completion"
        │                         stored, not called yet
        │
        └── starts the panel, then RETURNS immediately
            (the user hasn't picked a file yet)

            ... user picks file ...

            macOS calls closure A
                loadDrawing calls closure B
                    closure B calls completion(result, url)
                        YOUR closure finally executes
                            shapes = data.shapes ← view updates here
         */
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                loadDrawing(from: url) { result in
                    completion(result, url)  // ← adapt: inject url as second parameter
                }
            }
        }
    }
         
    // MARK: - static func loadDrawing
    static func loadDrawing(from url: URL, completion: @escaping (Result<(shapes: [Shape], canvasSize: CGSize), Error>) -> Void) {

    /*----------------------------------------------------------------------
     static func loadDrawing(
         from url: URL,
         completion: @escaping (Result<(shapes: [Shape], canvasSize: CGSize), Error>) -> Void
     )
     ```

     **`completion`** — this is just a parameter name, like any other. It happens to be a function (closure) that you pass in, to be called when the async work is done.

     **`@escaping`** — means the closure will be called *after* `loadDrawing` returns. Without this, Swift assumes the closure is called immediately and then thrown away. Here it "escapes" the function's lifetime because it's called later inside `openPanel.begin { }`.

     **`(Result<...>) -> Void`** — describes the *type* of the closure. It's a function that:
     - takes one argument: a `Result`
     - returns nothing (`Void`)

     **`Result<(shapes: [Shape], canvasSize: CGSize), Error>`** — `Result` is a generic enum with two type parameters:
     ```
     Result < SuccessType                          , FailureType >
     Result < (shapes: [Shape], canvasSize: CGSize), Error       >
     ```

     - `SuccessType` = the named tuple `(shapes: [Shape], canvasSize: CGSize)` — what you get when loading succeeds
     - `FailureType` = `Error` — what you get when loading fails

     So the whole thing reads as:
     ```
     "completion is a closure that will be called later,
      receiving either a successfully loaded drawing (shapes + canvasSize)
      or an Error if something went wrong"
     ```

     Visually:
     ```
     completion: @escaping  (Result<(shapes:[Shape], canvasSize:CGSize), Error>)  ->  Void
     │            │          │       │                │                  │            │
     │            │          │       │                │                  │            └── returns nothing
     │            │          │       │                │                  └── on failure: an Error
     │            │          │       │                └── on success: a CGSize
     │            │          │       └── on success: an array of Shape
     │            │          └── either success or failure
     │            └── called after the function returns
     └── parameter name
     ---------------------------------------------------------------------------------------------*/
    
    
    
        do {
            let jsonData = try Data(contentsOf: url)
            let document = try JSONDecoder().decode(DrawingDocument.self, from: jsonData)
            let shapes = document.toShapes()  // NEU: Use toShapes instead of toLines
            let canvasSize = document.toCanvasSize()
            completion(.success((shapes: shapes, canvasSize: canvasSize)))
            print("Drawing loaded successfully from: \(url.lastPathComponent)")
        } catch {
            completion(.failure(error))
            print("Error loading drawing: \(error)")
            // Show error alert
            let alert = NSAlert()
            alert.messageText = "Open Failed"
            alert.informativeText = "Could not open the drawing: \(error.localizedDescription)"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
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
