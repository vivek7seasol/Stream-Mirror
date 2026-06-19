//
//  FilesListingView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI

struct FilesListingView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @ObservedObject var filesVM: FilesViewModel
    @AppStorage(SessionKeys.isPro) var isPro = false
    @EnvironmentObject var adVm : AdCountViewModel
    var body: some View {
        ZStack {
            VStack {
                if filesVM.selectedType == .PDF {
                    CommonStatusView(title: str.PDFFiles,onCast: {
                        filesVM.showDeviceList = true
                    })
                } else if filesVM.selectedType == .DOC {
                    CommonStatusView(title: str.WordDocuments,onCast: {
                        filesVM.showDeviceList = true
                    })
                } else {
                    CommonStatusView(title: str.PPTFiles,onCast: {
                        filesVM.showDeviceList = true
                    })
                }
                
                if filesVM.files.isEmpty {
                    Spacer()
                    filesVM.placeholderImage(openFrom: filesVM.selectedType)
                                        
                } else {
                    ScrollView(showsIndicators: false) {
                        if !isPro {
                            NativeAd7()
                                .padding(.top,15)
                                .padding(.horizontal,15)
                        }
                        LazyVStack(spacing: 12) {
                            
                            ForEach(filesVM.files) { file in
                                
                                FilesLisRow(
                                    image: filesVM.fileImage(openFrom: filesVM.selectedType),
                                    fileName: file.name,
                                    fileSize: file.size,
                                    deleteAction: {

                                        filesVM.selectedFileForDelete = file
                                        filesVM.showDeleteAlert = true
                                    },
                                    buttonAction: {
                                        adVm.registerTap()
                                        filesVM.selectedFile = file
                                        filesVM.showFilesPage = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                Spacer()
            }
        }
        .appScreen(isPresented: $filesVM.showDeviceList) {
            DeviceListview(isPresented: $filesVM.showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .onAppear {
            filesVM.loadSelectedFiles(openFrom: filesVM.selectedType)
        }
        .onChange(of: filesVM.selectedType) { _ in
            filesVM.loadSelectedFiles(openFrom: filesVM.selectedType)
        }
        .sheet(isPresented: $filesVM.showDocumentPicker) {
            
            DocumentPicker(
                openFrom: filesVM.selectedType
            ) { url in
                
                guard let savedURL = filesVM.saveFileToDocuments(from: url) else {
                    return
                }
                
                let file = SelectedFile(
                    url: savedURL.lastPathComponent,
                    name: savedURL.lastPathComponent,
                    size: filesVM.getFileSize(from: savedURL)
                )
                
                if !filesVM.files.contains(where: { $0.url == file.url }) {

                    filesVM.files.append(file)

                    filesVM.SaveSelectedFiles(openFrom: filesVM.selectedType)

                } else {

                    showToastAtCenter(message: str.Filealreadyexists)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            
            Button {
                filesVM.showDocumentPicker = true
            } label: {
                Image("Add")
                    .resizable()
                    .frame(width: isIpad() ? 65 : 55, height: isIpad() ? 65 : 55)
                    .frame(width: isIpad() ? 75 : 65, height: isIpad() ? 75 : 65)
                    .modifier(GlassCardModifier(cornerRadius: isIpad() ? 37.5 : 32.5))
                    .clipShape(RoundedRectangle(cornerRadius: isIpad() ? 37.5 : 32.5))
            }
            .buttonStyle(.plain)
            .padding(.trailing,15)
        }
        .navigationDestination(isPresented: $filesVM.showFilesPage) {
            if let file = filesVM.selectedFile {
                
                FilesPageView(
                    file: file,
                    openFrom: filesVM.selectedType
                )
            }
        }
        .alert(str.DeleteFile,
               isPresented: $filesVM.showDeleteAlert) {

            Button(str.Cancel, role: .cancel) { }

            Button(str.Delete, role: .destructive) {

                if let file = filesVM.selectedFileForDelete {

                    filesVM.DeleteSelectedFiles(
                        at: file,
                        openFrom: filesVM.selectedType
                    )
                }

                filesVM.selectedFileForDelete = nil
            }

        } message: {

            Text(str.DeleteFileMsg)
        }
    }
}

struct FilesLisRow: View {
    
    var image: String
    var fileName: String
    var fileSize: String
    var deleteAction: (() -> Void)
    var buttonAction: (() -> Void)
    
    var body: some View {
        Button {
            buttonAction()
        } label: {
            
            ZStack {
                
                HStack {
                    Image(image)
                        .resizable()
                        .frame(width: isIpad() ? 60 : 50,height: isIpad() ? 60 : 50)
                    
                    VStack(alignment:.leading,spacing: 5) {
                        Text(fileName)
                            .font(.system(size: isIpad() ? 22 : 16,weight: .medium))
                            .foregroundStyle(.white)
                        
                        Text(fileSize)
                            .font(.system(size: isIpad() ? 18 : 12))
                            .foregroundStyle(AppColor.textColor)
                    }
                    Spacer()
                    Button {
                        deleteAction()
                    } label: {
                        
                        Image("delete")
                            .resizable()
                            .frame(width: 20,height: 20)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 75 : 65)
            .modifier(GlassCardModifier(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilesListingView(filesVM: FilesViewModel())
}
