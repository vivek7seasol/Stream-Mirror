//
//  CameraView.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 11/05/26.
//

import SwiftUI
import AVFoundation
import Combine

struct CameraView: View {
    
    @Environment(\.dismiss) var dismiss
    @AppStorage(SessionKeys.isPro) var isPro = false
    @State private var showPremium = false
    
    @StateObject private var cameraManager = CameraPreviewManager()
    @StateObject private var recordingVM = ScreenRecordingViewModel()
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    
    @State private var showDeviceList = false
    @State private var permissionDenied = false
    @State private var showAirplayDisconnectAlert = false
    @State private var startBroadcast = false
    @State private var stopBroadcast = false
    
    var body: some View {
        
        ZStack {
            
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            VStack {
                
                CommonStatusView(title: str.Camera,isCastingShow: false) {
                    singleButtonCard(image: "startDrawing") {
//                        if isPro == true {
                            TVRemoteVM.handleDeviceAction(
                                onAirPlay: {
                                    showAirplayDisconnectAlert = true
                                },
                                onTV: {
                                    commonVM.castViewModel.stopCastingSession()
                                    if commonVM.connectedTvType == .LG || commonVM.connectedTvType == .ROKU {
                                        if let url = TVMirrorServer.shared.serverURL{
                                            commonVM.connectSDKDiscoveryModel.LGMirroring(mediaURL: url)
                                        }
                                    }
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

                                    recordingVM.toggleRecording()
                                },
                                onNoDevice: {
                                    showDeviceList = true
                                })
//                        } else {
//                            showPremium = true
//                        }
                    }
                }
                
                Spacer()
                
                // Bottom Controls
                HStack(spacing: 40) {
                    
                    // Flash
                    Button {
                        cameraManager.toggleFlash()
                    } label: {
                        
                        Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    // Capture
                    Button {
                        cameraManager.capturePhoto()
                    } label: {
                        
                        ZStack {
                            
                            Circle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 85, height: 85)
                            
                            Circle()
                                .fill(.white)
                                .frame(width: 70, height: 70)
                        }
                    }
                    
                    // Camera Flip
                    Button {
                        cameraManager.switchCamera()
                    } label: {
                        
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 35)
            }
            BroadcastPickerViewModel(
                preferredExtension: AppStrings.appExtensionPackageName,
                startBroadcast: $startBroadcast,
                stopBroadcast: $stopBroadcast
            )
            .frame(width: 0, height: 0)
            .frame(width: 1, height: 1)
            .opacity(0.01)
        }
        .background(EnableSwipeBack())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            checkCameraPermission()
        }
        .alert("Camera Access Denied".localized, isPresented: $permissionDenied) {
            
            Button("Settings".localized) {
                
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            
            Button("Cancel".localized, role: .cancel) {
                dismiss()
            }
            
        } message: {
            
            Text("Please allow camera access from Settings.".localized)
        }
        .alert("AirPlay Connected".localized, isPresented: $showAirplayDisconnectAlert) {
            
            Button("OK".localized, role: .cancel) {}
            
        } message: {
            Text("Please disconnect AirPlay device first.".localized)
        }
        .fullScreenCover(isPresented: $showDeviceList) {
            DeviceListview(isPresented: $showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
    }
    
    func checkCameraPermission() {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            cameraManager.setupCamera(position: .back)
            
        case .notDetermined:
            
            AVCaptureDevice.requestAccess(for: .video) { granted in
                
                DispatchQueue.main.async {
                    
                    if granted {
                        cameraManager.setupCamera(position: .back)
                    } else {
                        permissionDenied = true
                    }
                }
            }
            
        default:
            permissionDenied = true
        }
    }
}


#Preview {
    CameraView()
}
