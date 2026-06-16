//
//  MirrorView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI
import Lottie

struct MirrorView: View {
    
    @AppStorage(SessionKeys.isPro) var isPro = false
    @State private var showPremium = false
    @EnvironmentObject var adVm : AdCountViewModel
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage(AppStrings.rotateMirror) private var isRotateOn: Bool = true
    
    @State var broadcastManager: BroadCastPickerManager
    @State private var autoRotate = true
    @State private var soundEnabled = false
    @State private var selectedQuality: QualityType = .balanced
    @State private var showDeviceList = false
    @State private var showAirPlayAlert = false
    @State var startMirroring = false
    @State var stopMirroring = false
    @State private var isBroadcasting: Bool = false
    
    private var UD: UserDefaults? {
        UserDefaults(suiteName: AppStrings.groupID)
    }
    
    
    
    private func fetchBroadcastStatus() {
        isBroadcasting = AppStrings.fetchBroadcastStatus()
    }
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.MirrorScreen,onCast: {
                    showDeviceList = true
                })
                
                ZStack {
                    VStack(spacing:8) {
                        ZStack {
                            Image("lottieBG")
                                .resizable()
                                .frame(width: isIpad() ? 130 : 100,height:  isIpad() ? 130 : 100)
                            
                            LottieFile(animationFileName: MyLottieFiles.Cast, loopMode: .loop)
                                .frame(width: isIpad() ? 60 :  40, height: isIpad() ? 60 :  40)
                                .rotationEffect(.degrees(0))
                        }
                        
                        Text(str.MirrorYourDisplay)
                            .font(.system(size: isIpad() ? 26 : 20,weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text(str.Instantlyconnectandcastyourdisplay)
                            .font(.system(size: isIpad() ? 18 : 12))
                            .foregroundStyle(AppColor.textColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isIpad() ? 60 : 30)
                .background(
                    Image("mirrorBG")
                    .resizable()
                    .scaledToFill()
                )
                .cornerRadius(25)
                .padding(.horizontal,15)
                
                VStack(spacing: 20) {

                    MirrorCard(
                        image: "rotate",
                        title: str.AutoRotate,
                        title2: str.Matchdeviceorientation,
                        isOn: $isRotateOn
                    )

                    MirrorCard(
                        image: "sound",
                        title: str.Sound,
                        title2: str.StreamaudiotoTV,
                        isOn: $soundEnabled
                    )
                }
                
                ZStack {
                    VStack(spacing: isIpad() ? 30 : 15) {
                        HStack {
                            Image("quality")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIpad() ? 60 : 50,height: isIpad() ? 60 : 50)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                
                                Text(str.StreamQuality)
                                    .font(.system(size: isIpad() ? 24 : 18, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text(str.Balancelatencyandclarity)
                                    .font(.system(size: isIpad() ? 18 : 12))
                                    .foregroundColor(AppColor.textColor)
                            }
                        }
                        .frame(maxWidth: .infinity,alignment: .leading)
                        
                        QualityCard(
                            selectedQuality: $selectedQuality
                        )
                    }
                    .padding(.horizontal,15)
                    
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isIpad() ? 35 : 15)
                .modifier(GlassCardModifier(cornerRadius: 28))
                .padding(.horizontal, 15)
                .padding(.vertical, isIpad() ? 20 : 10)
                
                
                Spacer()
                
                commonButtonFile(text: isBroadcasting ? str.StopMirroring : str.StartMirroring) {
                    if isPro {
                        TVRemoteVM.handleDeviceAction(onAirPlay: {
                            
                        }, onTV: {
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
                            
                        }, onNoDevice: {
                            showDeviceList = true
                        })
                    } else {
                        showPremium = true
                    }
                }
                .padding()
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
        .appScreen(isPresented: $showDeviceList) {
            DeviceListview(isPresented: $showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .onAppear {

            autoRotate = UD?.object(forKey: AppStrings.rotateMirror) as? Bool ?? true

            if let quality = UserDefaults(
                suiteName: AppStrings.groupID
            )?.string(forKey: "selectedQuality") {

                switch quality {

                case "Low":
                    selectedQuality = .optimized

                case "Medium":
                    selectedQuality = .balanced

                case "High":
                    selectedQuality = .best

                default:
                    selectedQuality = .balanced
                }
            }
        }
        .onAppear {
            fetchBroadcastStatus()
        }
        .onChange(of: scenePhase) { _ in
            fetchBroadcastStatus()
        }
        .onChange(of: isRotateOn) { newValue in
            UD?.set(newValue, forKey: AppStrings.rotateMirror)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            fetchBroadcastStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            fetchBroadcastStatus()
        }
        .fullScreenCover(isPresented: $showPremium, onDismiss: {
            if pro_close_inter == "true" {
                adVm.registerTap()
            }
        }, content: {
            PremiumView()
        })
    }
    
    func startMirroringFlow() {
        
        guard commonVM.isDeviceConnected else {
            showDeviceList = true
            return
        }
        
        // ✅ SAFE CHECK (MOST IMPORTANT FIX)
        guard let type = TVRemoteVM.connectedTVType,
              TVRemoteVM.isConnectedSuccessfully else {
            showDeviceList = true
            return
        }
        
        switch type {
            
        case .AIRPLAY:
            if commonVM.isAirPlayConnected() {
                showAirPlayAlert = true
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
                showDeviceList = true
                return
            }
            
            commonVM.castViewModel.stopCastingSession()
            
            guard let url = TVMirrorServer.shared.serverURL else {
                print("❌ Mirroring URL is nil")
                
                showDeviceList = true
                
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

#Preview {
    MirrorView(broadcastManager: BroadCastPickerManager(commonVm: CommonConnectionViewModel()))
}
