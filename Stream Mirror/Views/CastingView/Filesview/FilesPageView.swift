//
//  FilesPageView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI

struct FilesPageView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var filesPageVM = FilesPageViewModel()
    var file: SelectedFile
    var openFrom: FileType
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: file.name,onCast: {
                    
                })
                
                if filesPageVM.isLoading {
                    
                    Spacer()
                    
                    ProgressView("Loading Pages...")
                        .tint(.white)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                } else if filesPageVM.pages.isEmpty {
                    
                    Spacer()
                    
                    placeholderView(
                        image: "PhotoListPH", title: str.noPhotosFound,
                        title2: "",isTitle2: false
                    )
                    
                    Spacer()
                } else {
                    
                    ScrollView(showsIndicators: false) {
                        
                        let columns = [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            
                            ForEach(Array(filesPageVM.pages.enumerated()), id: \.offset) { index, image in
                                
                                Button {
                                    filesPageVM.selectedIndex = index
                                        filesPageVM.showPreview = true
                                } label: {
                                    VStack(spacing: 10) {
                                        
                                        Image(uiImage: image)
                                            .resizable()
                                            .frame(height: 170)
                                            .clipped()
                                            .cornerRadius(24)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                            }
                        }
                        .padding()
                    }
                }
                
            }
        }
        .appScreen()
        .onAppear {
            
            guard filesPageVM.pages.isEmpty else { return }
            
            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!
            
            let url = documents.appendingPathComponent(file.url)
            
            filesPageVM.loadFile(url: url, type: openFrom)
        }
        .navigationDestination(
            isPresented: $filesPageVM.showPreview
        ) {

            PhotoCastingView(
                images: filesPageVM.pages,
                selectedIndex: filesPageVM.selectedIndex
            )
            .environmentObject(commonVM)
            .environmentObject(TVRemoteVM)
        }
    }
}

#Preview {
    FilesPageView(file: SelectedFile(
        url: "",
        name: "Sample.pdf",
        size: "1.2 MB"
    ),openFrom: .PDF)
}
