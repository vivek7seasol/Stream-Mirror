//
//  FilesViewModel.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

struct SelectedFile: Identifiable, Hashable, Codable {
    
    let id: UUID
    let url: String
    let name: String
    let size: String
    
    init(
        id: UUID = UUID(),
        url: String,
        name: String,
        size: String
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.size = size
    }
}

class FilesViewModel: ObservableObject {
    
    @Published var showDeviceList = false
    @Published var showFileListView = false
    @Published var showFilesPage = false
    @Published var selectedType: FileType = .PDF
    @Published var showDocumentPicker = false
    @Published var files: [SelectedFile] = []
    @Published var selectedFile: SelectedFile?
    func SaveSelectedFiles(openFrom: FileType) {
        
        do {
            
            let data = try JSONEncoder().encode(files)
            
            UserDefaults.standard.set(
                data,
                forKey: UDKey(openFrom: openFrom)
            )
            
        } catch {
            print(error)
        }
    }
    
    func loadSelectedFiles(openFrom: FileType) {

        guard let data = UserDefaults.standard.data(
            forKey: UDKey(openFrom: openFrom)
        ) else {

            files = []   // <- IMPORTANT
            return
        }

        do {

            files = try JSONDecoder().decode(
                [SelectedFile].self,
                from: data
            )

        } catch {

            files = []   // <- safety
            print(error)
        }
    }
    
    func UDKey(openFrom: FileType) -> String {
        
        switch openFrom {
            
        case .PDF:
            return "selected_pdf_files"
            
        case .DOC:
            return "selected_doc_files"
            
        case .PPT:
            return "selected_ppt_files"
        }
    }
    
    func saveFileToDocuments(from url: URL) -> URL? {
        
        let access = url.startAccessingSecurityScopedResource()
        
        defer {
            if access {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let destinationURL = documents
            .appendingPathComponent(url.lastPathComponent)
        
        do {
            
            if FileManager.default.fileExists(
                atPath: destinationURL.path
            ) {
                return destinationURL
            }
            
            try FileManager.default.copyItem(
                at: url,
                to: destinationURL
            )
            
            return destinationURL
            
        } catch {
            print(error)
            return nil
        }
    }
    
    func DeleteSelectedFiles(
        at file: SelectedFile,
        openFrom: FileType
    ) {
        
        do {
            
            try FileManager.default.removeItem(
                atPath: file.url
            )
            
        } catch {
            print(error)
        }
        
        files.removeAll { $0.id == file.id }
        
        SaveSelectedFiles(openFrom: openFrom)
    }
    
    func getFileSize(from url: URL) -> String {
        
        do {
            
            let values = try url.resourceValues(
                forKeys: [.fileSizeKey]
            )
            
            if let size = values.fileSize {
                
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useKB, .useMB]
                formatter.countStyle = .file
                
                return formatter.string(
                    fromByteCount: Int64(size)
                )
            }
            
        } catch {
            print(error)
        }
        
        return "0 KB"
    }
    
    func fileImage(openFrom: FileType) -> String {
        
        switch openFrom {
            
        case .PDF:
            return "PDF2"
            
        case .DOC:
            return "DOC2"
            
        case .PPT:
            return "PPT2"
        }
    }
    
    @ViewBuilder
    func placeholderImage(openFrom: FileType) -> some View {
        
        switch openFrom {
            
        case .PDF:
            VStack(spacing:10) {
                Image("FilesListPH")
                    .resizable()
                    .frame(width: isIpad() ? 110 : 90, height: isIpad() ? 110 : 90)
                
                Text(str.NoPDFAvailable)
                    .font(.system(size: isIpad() ? 22 : 16))
                    .foregroundStyle(.white)
                
                Text(str.yourfirstPDFtogetstarted)
                    .foregroundStyle(AppColor.textColor)
                    .font(.system(size: isIpad() ? 18 : 12))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal,15)
            }
            
        case .DOC:
            VStack(spacing:10) {
                Image("FilesListPH")
                    .resizable()
                    .frame(width: isIpad() ? 110 : 90, height: isIpad() ? 110 : 90)
                
                Text(str.NoDocumentsAvailable)
                    .font(.system(size: isIpad() ? 22 : 16))
                    .foregroundStyle(.white)
                
                Text(str.Addyourfirstdocumenttogetstartedquickly)
                    .foregroundStyle(AppColor.textColor)
                    .font(.system(size: isIpad() ? 18 : 12))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal,15)
            }
            
        case .PPT:
            VStack(spacing:10) {
                Image("FilesListPH")
                    .resizable()
                    .frame(width: isIpad() ? 110 : 90, height: isIpad() ? 110 : 90)
                
                Text(str.NoPresentationsAvailable)
                    .font(.system(size: isIpad() ? 22 : 16))
                    .foregroundStyle(.white)
                
                Text(str.Addyourfirstpresentationtogetstarted)
                    .foregroundStyle(AppColor.textColor)
                    .font(.system(size: isIpad() ? 18 : 12))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal,15)
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    
    var openFrom: FileType
    var onPick: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        
        let types: [UTType]
        
        switch openFrom {
            
        case .PDF:
            types = [.pdf]
            
        case .PPT:
            types = [
                UTType(filenameExtension: "ppt")!,
                UTType(filenameExtension: "pptx")!
            ]
            
        case .DOC:
            types = [
                UTType(filenameExtension: "doc")!,
                UTType(filenameExtension: "docx")!
            ]
        }
        
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: types,
            asCopy: true
        )
        
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) {
        
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        
        var onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            
            guard let url = urls.first else { return }
            
            onPick(url)
        }
    }
}


