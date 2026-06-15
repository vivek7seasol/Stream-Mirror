//
//  FilesPageViewModel.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import Foundation
import SwiftUI
import PDFKit
import Combine
import PDFNet
import Foundation

@MainActor
class FilesPageViewModel: ObservableObject {
    
    // MARK: - Properties
    @Published var pages: [UIImage] = []
    @Published var isLoading: Bool = false
    @Published var showConnectionView = false
    @Published var selectedIndex = 0
    @Published var showPreview = false
    @Published var showDeviceList = false
    
    // MARK: - Public Entry Point
    func loadFile(url: URL, type: FileType) {
        
        Task {
            
            isLoading = true
            pages = []
            
            do {
                
                // ✅ Check file exists
                guard FileManager.default.fileExists(atPath: url.path) else {
                    throw NSError(
                        domain: "FileError",
                        code: 404,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "File not found at path:\n\(url.path)"
                        ]
                    )
                }
                
                switch type {
                    
                case .PDF:
                    try await loadImagesFromPDF(from: url)
                    
                case .PPT:
                    let pdfURL = try await PPTConverter.convertPPTToPDF(pptURL: url)
                    try await loadImagesFromPDF(from: pdfURL)
                    
                case .DOC:
                    let pdfURL = try await DOCConverter.convertDOCToPDF(docURL: url)
                    try await loadImagesFromPDF(from: pdfURL)
                }
                
            } catch {
                print("File load error:", error.localizedDescription)
            }
            
            isLoading = false
        }
    }}

// MARK: - PDF Processing
extension FilesPageViewModel {
    
    private func loadImagesFromPDF(from url: URL) async throws {
        
        let isAccessing = url.startAccessingSecurityScopedResource()
        
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // ✅ Local temp copy
        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".pdf")
        
        try? FileManager.default.removeItem(at: localURL)
        
        try FileManager.default.copyItem(at: url, to: localURL)
        
        guard let pdf = PDFDocument(url: localURL) else {
            throw NSError(
                domain: "PDFError",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Unable to open PDF"
                ]
            )
        }
        
        var temp: [UIImage] = []
        
        for index in 0..<pdf.pageCount {
            
            guard let page = pdf.page(at: index) else { continue }
            
            let targetSize = CGSize(width: 500, height: 700)
            
            let pageRect = page.bounds(for: .mediaBox)
            
            let scale = min(
                targetSize.width / pageRect.width,
                targetSize.height / pageRect.height
            )
            
            let scaledSize = CGSize(
                width: pageRect.width * scale,
                height: pageRect.height * scale
            )
            
            let renderer = UIGraphicsImageRenderer(size: scaledSize)
            
            let image = renderer.image { ctx in
                
                UIColor.white.set()
                ctx.fill(CGRect(origin: .zero, size: scaledSize))
                
                ctx.cgContext.translateBy(x: 0, y: scaledSize.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            temp.append(image)
        }
        
        self.pages = temp
    }
}

actor PPTConverter {
    static func convertPPTToPDF(pptURL: URL) async throws -> URL {
        
        let isAccessing = pptURL.startAccessingSecurityScopedResource()
        
        defer {
            if isAccessing {
                pptURL.stopAccessingSecurityScopedResource()
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    
                    let localURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(pptURL.pathExtension)
                    
                    try? FileManager.default.removeItem(at: localURL)
                    
                    try FileManager.default.copyItem(at: pptURL, to: localURL)
                    
                    let outputURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString + ".pdf")
                    
                    try? FileManager.default.removeItem(at: outputURL)
                    
                    let pdfDoc = PTPDFDoc()
                    let options = PTOfficeToPDFOptions()
                    
                    try PTConvert.office(toPDF: pdfDoc, in_filename: localURL.path, options: options)
                    pdfDoc?.save(toFile: outputURL.path, flags: e_ptlinearized.rawValue)
                    pdfDoc?.close()
                    
                    try? FileManager.default.removeItem(at: localURL)
                    
                    continuation.resume(returning: outputURL)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

actor DOCConverter {
    
    static func convertDOCToPDF(docURL: URL) async throws -> URL {
        
        let isAccessing = docURL.startAccessingSecurityScopedResource()
        defer { if isAccessing { docURL.stopAccessingSecurityScopedResource() } }
        
        return try await withCheckedThrowingContinuation { continuation in
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                do {
                    // ✅ Validate file
                    let ext = docURL.pathExtension.lowercased()
                    guard ["doc", "docx"].contains(ext) else {
                        throw NSError(domain: "PDF", code: -10, userInfo: [
                            NSLocalizedDescriptionKey: "Unsupported file format"
                        ])
                    }
                    
                    // ✅ Copy locally
                    let localURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(ext)
                    
                    try? FileManager.default.removeItem(at: localURL)
                    try FileManager.default.copyItem(at: docURL, to: localURL)
                    
                    // ✅ Check file size (very important)
                    let fileSize = (try? Data(contentsOf: localURL).count) ?? 0
                    guard fileSize > 0 else {
                        throw NSError(domain: "PDF", code: -11, userInfo: [
                            NSLocalizedDescriptionKey: "File is empty or corrupted"
                        ])
                    }
                    
                    let outputURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString + ".pdf")
                    
                    guard let pdfDoc = PTPDFDoc() else {
                        throw NSError(domain: "PDF", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Failed to create PDFDoc"
                        ])
                    }
                    
                    let options = PTOfficeToPDFOptions()
                    
                    try PTConvert.office(toPDF: pdfDoc,
                                         in_filename: localURL.path,
                                         options: options)
                    
                    // ✅ Prevent save crash
                    guard pdfDoc.getPageCount() > 0 else {
                        throw NSError(domain: "PDF", code: -2, userInfo: [
                            NSLocalizedDescriptionKey: "Conversion failed (empty PDF)"
                        ])
                    }
                    
                    try pdfDoc.save(toFile: outputURL.path, flags: e_ptlinearized.rawValue)
                    pdfDoc.close()
                    
                    try? FileManager.default.removeItem(at: localURL)
                    
                    continuation.resume(returning: outputURL)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
