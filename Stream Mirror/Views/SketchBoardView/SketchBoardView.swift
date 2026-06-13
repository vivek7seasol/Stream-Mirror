//
//  SketchBoardView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI

struct SketchBoardView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    
    @StateObject private var sketchVM = SketchBoardViewModel()
    @StateObject private var recordingVM = ScreenRecordingViewModel()
    
    var existingDrawingURL: URL? = nil
    
    init(existingDrawingURL: URL? = nil) {
        self.existingDrawingURL = existingDrawingURL
    }
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.Drawing,onCast: {
                    
                })
                
                PencilView(canvasView: .constant(sketchVM.canvasView))
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .opacity(sketchVM.showCanvas ? 1 : 0)
                    .allowsHitTesting(sketchVM.showCanvas)
                    .onAppear {

                        sketchVM.setup(commonVm: commonVM)
                        sketchVM.showToolPicker(colorScheme: colorScheme)
                    }
                
                Spacer()
                
                ZStack {
                    HStack {
                        Spacer()
                        sketcboardButtons(image: "redo", action: {
                            sketchVM.redo()
                        })
                        Spacer()
                        sketcboardButtons(image: "undo", action: {
                            sketchVM.undo()
                        })
                        Spacer()
                        sketcboardButtons(image: "save", action: {
                            if let savedURL = sketchVM.saveSketchboard(existingURL: existingDrawingURL) {
                                
                                if existingDrawingURL != nil {
                                    showToastAtCenter(message: "Drawing updated successfully")
                                    dismiss()
                                } else {
                                    showToastAtCenter(message: "Drawing saved successfully")
                                    dismiss()
                                }
                                
                                print("✅ Saved:", savedURL)
                                
                            } else {
                                
                                showToastAtCenter(message: "Failed to save drawing")
                            }
                        })
                        Spacer()
                        sketcboardButtons(image: sketchVM.isBroadcasting ? "stopDrawing" : "startDrawing", action: {
                            commonVM.castViewModel.stopCastingSession()
                            if commonVM.connectedTvType == .LG || commonVM.connectedTvType == .ROKU {
                                if let url = TVMirrorServer.shared.serverURL{
                                    commonVM.connectSDKDiscoveryModel.LGMirroring(mediaURL: url)
                                }
                            }
                            recordingVM.toggleRecording()
                        })
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: isIpad() ? 80 : 60)
                .modifier(GlassCardModifier(cornerRadius: isIpad() ? 40 : 30))
                .padding(.horizontal,15)
                .padding(.bottom,100 )
                
            }
            
        }
        .appScreen()
        .onAppear {
            sketchVM.fetchBroadcastStatus()
            sketchVM.setup(commonVm: commonVM)
            sketchVM.showToolPicker(colorScheme: colorScheme)
            
            // Thodi delay do taaki canvas setup ho jaye pehle
            if let existingDrawingURL {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    sketchVM.loadSketchboard(from: existingDrawingURL)
                }
            }
        }
        .onDisappear() {
            sketchVM.showCanvas = false
            print("🛑 Stop mirroring")
            
            UserDefaults(suiteName: AppStrings.groupID)?
                .set(false, forKey: "isBroadcasting")
            
            sketchVM.stopCasting()
            commonVM.setTVPlaceHolder(connectedTvType: commonVM.connectedTvType ?? .ANDROID)
        }
        .onChange(of: scenePhase) { _ in
            sketchVM.fetchBroadcastStatus()
        }
    }
}

struct sketcboardButtons: View {
    
    let image: String
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            Image(image)
                .resizable()
                .frame(width: isIpad() ? 30 : 24,height: 24)
        }
        .buttonStyle(.plain)

    }
}

#Preview {
    SketchBoardView()
}
