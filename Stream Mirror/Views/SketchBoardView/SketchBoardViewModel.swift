//
//  DrawingVM.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 08/05/26.
//

import Foundation
import UIKit
import PencilKit
import SwiftUI
import Combine

struct SavedSketchBoard: Identifiable, Hashable {

    let id = UUID()
    let url: URL
    let fileName: String
    let fileSize: String
    let modifiedDate: Date
    let thumbnail: UIImage

    static func == (
        lhs: SavedSketchBoard,
        rhs: SavedSketchBoard
    ) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class SketchBoardViewModel: NSObject, ObservableObject, PKCanvasViewDelegate {
    
    var commonVM: CommonConnectionViewModel?
    private let folderName = AppStrings.appName
    @Published var hasDrawing = false
    @Published var showHistory = false
    @Published var showSketchboardView: Bool = false
    @Published var drawings: [SavedSketchBoard] = []
    @Published var isBroadcasting: Bool = false
    @Published var showCanvas = true
    @Published var showShareSheet = false
    @Published var shareURL: URL?
    @Published var selectedDrawing: SavedSketchBoard?
    @Published var showEditDrawing = false
    let canvasView = PKCanvasView()
    
    func setup(commonVm: CommonConnectionViewModel) {
        
        self.commonVM = commonVm
        
        canvasView.delegate = self
    }
    
    func fetchBroadcastStatus() {
        isBroadcasting = AppStrings.fetchBroadcastStatus()
    }
    
    
    func stopCasting() {
        
        guard let commonVM else { return }
        
        if commonVM.getConnectedTvType() == .ANDROID {
            
            commonVM.castViewModel.stopCastingSession()
            commonVM.StopCasting()
            
        } else if commonVM.getConnectedTvType() == .LG {
            
            commonVM.connectSDKDiscoveryModel.stopMediaCasting()
            
        } else {
            
            commonVM.stopMediaCasting()
        }
    }
    
    func deleteDrawing(_ drawing: SavedSketchBoard) {
        
        do {
            
            try FileManager.default.removeItem(
                at: drawing.url
            )
            
            drawings.removeAll {
                $0.id == drawing.id
            }
            
        } catch {
            
            print("Delete error:", error)
        }
    }
    
    func undo() {
        canvasView.undoManager?.undo()
    }
    
    func redo() {
        canvasView.undoManager?.redo()
    }
    
    func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }
    
    func showToolPicker(colorScheme: ColorScheme) {
        
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first,
           let toolPicker = PKToolPicker.shared(for: window) {
            
            toolPicker.overrideUserInterfaceStyle =
            colorScheme == .dark ? .dark : .light
            
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
    }
    
    private func folderURL() -> URL {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = doc.appendingPathComponent(folderName)
        
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }
    
    func saveSketchboard(existingURL: URL?) -> URL? {
        
        let data = canvasView.drawing.dataRepresentation()
        
        let url: URL
        
        if let existingURL {
            url = existingURL
        } else {
            let name = "drawing_\(Int(Date().timeIntervalSince1970)).pkdraw"
            url = folderURL().appendingPathComponent(name)
        }
        
        do {
            try data.write(to: url)
            
            try FileManager.default.setAttributes(
                [.modificationDate: Date()],
                ofItemAtPath: url.path
            )
            
            return url
        } catch {
            print("Save error:", error)
            return nil
        }
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        
        DispatchQueue.main.async {
            
            self.hasDrawing = !canvasView.drawing.strokes.isEmpty
        }
    }
    
    func loadSketchboard(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            canvasView.drawing = try PKDrawing(data: data)
        } catch {
            print("Load error:", error)
        }
    }
    
    func getAllSavedSketchboard() -> [SavedSketchBoard] {
        
        let folder = folderURL()
        
        do {
            
            let files = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [
                    .fileSizeKey,
                    .contentModificationDateKey
                ]
            )
            
            let drawings = files.compactMap { url -> SavedSketchBoard? in
                
                guard url.pathExtension == "pkdraw" else { return nil }
                
                do {
                    
                    let data = try Data(contentsOf: url)
                    let drawing = try PKDrawing(data: data)
                    
                    let resource = try? url.resourceValues(
                        forKeys: [
                            .fileSizeKey,
                            .contentModificationDateKey
                        ]
                    )
                    
                    let size = resource?.fileSize ?? 0
                    let date = resource?.contentModificationDate ?? Date()
                    
                    let formatter = ByteCountFormatter()
                    formatter.allowedUnits = [.useKB, .useMB]
                    formatter.countStyle = .file
                    
                    let thumbnail = generateThumbnail(from: drawing)
                    
                    return SavedSketchBoard(
                        url: url,
                        fileName: url.deletingPathExtension().lastPathComponent,
                        fileSize: formatter.string(fromByteCount: Int64(size)),
                        modifiedDate: date,
                        thumbnail: thumbnail
                    )
                    
                } catch {
                    
                    print("❌ Thumbnail error:", error)
                    return nil
                }
            }
            
            return drawings.sorted {
                $0.modifiedDate > $1.modifiedDate
            }
            
        } catch {
            
            print("❌ Load drawings error:", error)
            return []
        }
    }
    
    func generateThumbnail(from drawing: PKDrawing) -> UIImage {
        
        let bounds = drawing.bounds.isEmpty
        ? CGRect(x: 0, y: 0, width: 300, height: 200)
        : drawing.bounds.insetBy(dx: -20, dy: -20)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200))
        
        let image = renderer.image { ctx in
            // Clear/transparent background
            ctx.cgContext.clear(CGRect(x: 0, y: 0, width: 300, height: 200))
            
            let scale = min(300 / bounds.width, 200 / bounds.height)
            let scaledWidth = bounds.width * scale
            let scaledHeight = bounds.height * scale
            let offsetX = (300 - scaledWidth) / 2
            let offsetY = (200 - scaledHeight) / 2
            
            let drawingImage = drawing.image(from: bounds, scale: UIScreen.main.scale)
            drawingImage.draw(in: CGRect(x: offsetX, y: offsetY, width: scaledWidth, height: scaledHeight))
        }
        
        return image
    }
    
    func hideToolPicker() {

        if let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first,
           let toolPicker = PKToolPicker.shared(for: window) {

            toolPicker.setVisible(false, forFirstResponder: canvasView)
            canvasView.resignFirstResponder()
        }
    }
}

struct PencilView: UIViewRepresentable {
    
    @Binding var canvasView: PKCanvasView
    @Environment(\.colorScheme) var colorScheme
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first,
           let toolPicker = PKToolPicker.shared(for: window) {
            toolPicker.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
        
        //        let initialColor: UIColor = colorScheme == .dark ? .white : .black
        //        canvasView.tool = PKInkingTool(.pen, color: initialColor, width: 5.0)
        //        canvasView.backgroundColor = .systemBackground
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // No updates needed — VM owns the canvasView directly
    }
}
