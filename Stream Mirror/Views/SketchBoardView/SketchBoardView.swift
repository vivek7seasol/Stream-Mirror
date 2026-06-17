//
//  SketchBoardView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI

struct SketchBoardView: View {
    
    @AppStorage(SessionKeys.isPro) var isPro = false
    @State private var showPremium = false
    @EnvironmentObject var adVm : AdCountViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @State var broadcastManager: BroadCastPickerManager
    @State var startMirroring = false
    @StateObject private var sketchVM = SketchBoardViewModel()
    @StateObject private var recordingVM = ScreenRecordingViewModel()
    @State var stopMirroring = false
    var existingDrawingURL: URL? = nil
    
    init(existingDrawingURL: URL? = nil) {
        self.existingDrawingURL = existingDrawingURL

        _broadcastManager = State(
            initialValue: BroadCastPickerManager(
                commonVm: CommonConnectionViewModel()
            )
        )
    }
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.Drawing,onCast: {
                    sketchVM.hideToolPicker()
                    recordingVM.showDeviceList = true
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
                        sketcboardButtons(image: "redo") {
                            sketchVM.redo()
                        }
                        .disabled(!sketchVM.canRedo)
                        .opacity(sketchVM.canRedo ? 1 : 0.4)
                        
                        Spacer()
                        sketcboardButtons(image: "undo") {
                            sketchVM.undo()
                        }
                        .disabled(!sketchVM.canUndo)
                        .opacity(sketchVM.canUndo ? 1 : 0.4)
                        
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
                        .disabled(!sketchVM.hasDrawing)
                        .opacity(sketchVM.hasDrawing ? 1 : 0.4)
                        
                        Spacer()
                        sketcboardButtons(image: sketchVM.isBroadcasting ? "stopDrawing" : "startDrawing", action: {
                            
                            if selectedTvType == .ANDROID || selectedTvType == .SAMSUNG {
                                if let userDefaults = UserDefaults(suiteName: AppStrings.groupID){
                                    if userDefaults.bool(forKey: "isBroadcasting") == false {
                                        if commonVM.castViewModel.isCastingSessionGoing() {
                                            commonVM.castViewModel.stopCastingSession()
                                            commonVM.StopCasting()
                                        }
                                    }
                                }
                            }
                            startMirroringFlow()
                        })
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: isIpad() ? 80 : 60)
                .modifier(GlassCardModifier(cornerRadius: isIpad() ? 40 : 30))
                .padding(.horizontal,15)
                .padding(.bottom, isIpad() ? 130 : 100)
                
            }
            if TVRemoteVM.connectedTVType != .AIRPLAY {
                BroadcastPickerViewModel(
                    preferredExtension: AppStrings.appExtensionPackageName,
                    startBroadcast: $startMirroring, stopBroadcast: $stopMirroring
                )
                .frame(width: 0, height: 0)
                .frame(width: 1, height: 1)
                .opacity(0.01)
            }
            
        }
        .appScreen(isPresented: $recordingVM.showDeviceList) {
            DeviceListview(isPresented: $recordingVM.showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .onAppear {
            startMirroringFlow()
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
            sketchVM.hideToolPicker()
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
        .onChange(of: recordingVM.showDeviceList) { isPresented in

            if !isPresented {

                sketchVM.showToolPicker(colorScheme: colorScheme)
            }
        }
        .fullScreenCover(
            isPresented: $showPremium,
            onDismiss: {

                sketchVM.showToolPicker(colorScheme: colorScheme)

                if pro_close_inter == "true" {
                    adVm.registerTap()
                }
            }
        ) {
            PremiumView()
        }
    }
    
    func startMirroringFlow() {
        
        guard commonVM.isDeviceConnected else {
            recordingVM.showDeviceList = true
            return
        }
        
        // ✅ SAFE CHECK (MOST IMPORTANT FIX)
        guard let type = TVRemoteVM.connectedTVType,
              TVRemoteVM.isConnectedSuccessfully else {
            recordingVM.showDeviceList = true
            return
        }
        
        switch type {
            
        case .AIRPLAY:
            if commonVM.isAirPlayConnected() {
//                showAirPlayAlert = true
            }
            
        case .ANDROID, .SAMSUNG:
            print("🔥 Android Mirroring Start")
            broadcastManager = BroadCastPickerManager(commonVm: commonVM)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                startMirroring = true
            }
            
        case .LG:
            
            let lgModel = commonVM.connectSDKDiscoveryModel
            
            guard lgModel.isConnectedToLG else {
                recordingVM.showDeviceList = true
                return
            }
            
            commonVM.castViewModel.stopCastingSession()
            
            guard let url = TVMirrorServer.shared.serverURL else {
                print("❌ Mirroring URL is nil")
                
                recordingVM.showDeviceList = true
                
                return
            }
            
            print("✅ Mirroring URL:", url)
            
            lgModel.LGMirroring(mediaURL: url)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                startMirroring = true
            }
        default:
            break
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
                .frame(width: isIpad() ? 30 : 24,height: isIpad() ? 30 : 24)
        }
        .buttonStyle(.plain)

    }
}

#Preview {
    SketchBoardView()
}
