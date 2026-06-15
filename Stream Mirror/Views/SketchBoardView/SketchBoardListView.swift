//
//  SketchBoardView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI

struct SketchBoardListView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var sketchVM = SketchBoardViewModel()
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.Drawing,isCastingShow: false)
                
                if sketchVM.drawings.isEmpty {
                    
                    Spacer()
                    placeholderView(image: "drawing", title: str.StartNewDrawing,title2: str.addnewDrawing,isTitle2: true,height: 110,width: 130)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {

                        LazyVGrid(
                            columns: columns,
                            spacing: 12
                        ) {

                            ForEach(sketchVM.drawings) { drawing in

                                DrawingListRow(
                                    thumbnail: drawing.thumbnail,
                                    fileName: drawing.fileName,
                                    fileSize: drawing.fileSize,
                                    shareAction: {
                                        sketchVM.shareURL = drawing.url
                                        sketchVM.showShareSheet = true
                                    },
                                    deleteAction: {
                                        sketchVM.deleteDrawing(drawing)
                                    },
                                    buttonAction: {
                                        sketchVM.selectedDrawing = drawing
                                        sketchVM.showEditDrawing = true
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
        .appScreen()
        .onAppear {
            sketchVM.drawings = sketchVM.getAllSavedSketchboard()
        }
        .overlay(alignment: .bottomTrailing) {
            
            Button {
                sketchVM.showSketchboardView = true
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
        .sheet(isPresented: $sketchVM.showShareSheet) {

            if let url = sketchVM.shareURL {
                DrawingShareSheet(
                    activityItems: [url]
                )
            }
        }
        .navigationDestination(isPresented: $sketchVM.showSketchboardView) {
            SketchBoardView()
        }
        .navigationDestination(
            isPresented: $sketchVM.showEditDrawing
        ) {
            if let drawing = sketchVM.selectedDrawing {
                SketchBoardView(
                    existingDrawingURL: drawing.url
                )
            }
        }
    }
}


#Preview {
    SketchBoardListView()
}
