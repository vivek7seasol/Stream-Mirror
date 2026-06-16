//
//  Filesview.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI

enum FileType {
    case PDF,PPT,DOC
}

struct Filesview: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var filesVM = FilesViewModel()
    @AppStorage(SessionKeys.isPro) var isPro = false
    @EnvironmentObject var adVm : AdCountViewModel
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.FileLibrary,onCast: {
                    filesVM.showDeviceList = true
                })
                
                VStack(spacing:15) {
                    FileLibraryRow(lbl1: str.PDFFiles, lbl2: str.AllyourPDFfilesinoneplace, lbl3: str.OpenPDF, image: "PDF") {
                        adVm.registerTap()
                        filesVM.selectedType = .PDF
                        filesVM.showFileListView = true
                    }
                    
                    FileLibraryRow(lbl1: str.WordDocuments, lbl2: str.Viewyourddocumentsanytime, lbl3: str.OpenDoc, image: "DOC") {
                        adVm.registerTap()
                        filesVM.selectedType = .DOC
                        filesVM.showFileListView = true
                    }
                    
                    FileLibraryRow(lbl1: str.PPTFiles, lbl2: str.Quicklyaccessyourfilesanytime, lbl3: str.OpenPresentation, image: "PPT") {
                        adVm.registerTap()
                        filesVM.selectedType = .PPT
                        filesVM.showFileListView = true
                    }
                }
                .padding(.horizontal,15)
                
                Spacer()
                if !isPro {
                    NativeAd7()
                        .padding(.bottom,5)
                }
            }
        }
        .appScreen(isPresented: $filesVM.showDeviceList) {
            DeviceListview(isPresented: $filesVM.showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .navigationDestination(isPresented: $filesVM.showFileListView) {
            FilesListingView(filesVM: filesVM)
        }
    }
}

struct FileLibraryRow: View {
    
    let lbl1 : String
    let lbl2 : String
    let lbl3 : String
    let image : String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            
            ZStack {
                HStack {
                    VStack(alignment:.leading) {
                        Text(lbl1)
                            .font(.system(size: isIpad() ? 22 : 16,weight: .medium))
                            .foregroundStyle(.white)
                        
                        Text(lbl2)
                            .font(.system(size: isIpad() ? 18 : 12))
                            .foregroundStyle(AppColor.textColor)
                        Spacer()
                        ZStack {
                            Text(lbl3)
                                .font(.system(size: isIpad() ? 18 : 12))
                                .foregroundStyle(AppColor.textColor2)
                        }
                        .padding(.horizontal,15)
                        .padding(.vertical,5)
                        .background(.white)
                        .cornerRadius(15)
                    }
                    .padding(.vertical,15)
                    .padding(.horizontal,5)
                    Spacer()
                    Image(image)
                        .resizable()
                        .frame(width: isIpad() ? 100 : 80,height: isIpad() ? 100 : 80)
                }
                .padding(.horizontal,20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 120 : 100)
            .modifier(GlassCardModifier(cornerRadius: 30))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    Filesview()
}
