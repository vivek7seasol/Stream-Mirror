//
//  MirrorView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI
import Lottie

struct MirrorView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @State var broadcastManager: BroadCastPickerManager
    @State private var autoRotate = true
    @State private var soundEnabled = false
    @State private var selectedQuality: QualityType = .balanced
    @State private var showDeviceList = false
    @State private var showAirPlayAlert = false
    @State var startMirroring = false
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.MirrorScreen,onCast: {
                    
                })
                
                ZStack {
                    VStack(spacing:8) {
                        ZStack {
                            Image("lottieBG")
                                .resizable()
                                .frame(width: isIpad() ? 100 : 95,height:  isIpad() ? 100 : 95)
                            
                            LottieFile(animationFileName: MyLottieFiles.Cast, loopMode: .loop)
                                .frame(width: isIpad() ? 60 :  40, height: isIpad() ? 60 :  40)
                                .rotationEffect(.degrees(0))
                        }
                        
                        Text(str.MirrorYourDisplay)
                            .font(.system(size: 20,weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text(str.Instantlyconnectandcastyourdisplay)
                            .font(.system(size: 12))
                            .foregroundStyle(AppColor.textColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical,30)
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
                        isOn: $autoRotate
                    )

                    MirrorCard(
                        image: "sound",
                        title: str.Sound,
                        title2: str.StreamaudiotoTV,
                        isOn: $soundEnabled
                    )
                }
                
                ZStack {
                    VStack {
                        HStack {
                            Image("quality")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIpad() ? 60 : 50,height: isIpad() ? 60 : 50)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                
                                Text(str.StreamQuality)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text(str.Balancelatencyandclarity)
                                    .font(.system(size: 12))
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
                .padding(.vertical,15)
                .modifier(GlassCardModifier(cornerRadius: 28))
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                
                
                Spacer()
                
                commonButtonFile(text: str.StartMirroring) {
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
                    
                }
                .padding()
            }
        }
        .appScreen()
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

struct MirrorCard: View {

    let image: String
    let title: String
    let title2: String

    @Binding var isOn: Bool

    var body: some View {

        ZStack {
            
            HStack(spacing: 10) {
                
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isIpad() ? 60 : 50,height: isIpad() ? 60 : 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(title2)
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textColor)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }
            .padding(.horizontal, 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical,15)
        .modifier(GlassCardModifier(cornerRadius: 28))
        .padding(.horizontal, 15)
    }
}

enum QualityType: String, CaseIterable {
    case optimized = "Optimized"
    case balanced = "Balanced"
    case best = "Best"
}

struct QualityCard: View {

    @Binding var selectedQuality: QualityType

    var body: some View {

        HStack(spacing: 0) {

            ForEach(QualityType.allCases, id: \.self) { quality in

                Button {

                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedQuality = quality
                    }

                    if let userDefaults = UserDefaults(
                        suiteName: AppStrings.groupID
                    ) {

                        switch quality {

                        case .optimized:
                            userDefaults.set("Low", forKey: "selectedQuality")

                        case .balanced:
                            userDefaults.set("Medium", forKey: "selectedQuality")

                        case .best:
                            userDefaults.set("High", forKey: "selectedQuality")
                        }
                    }

                } label: {

                    Text(quality.rawValue)
                        .font(.system(size: isIpad() ? 20 : 16,
                                      weight: .medium))
                        .foregroundColor(
                            selectedQuality == quality
                            ? .black
                            : .white
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: isIpad() ? 70 : 55)
                        .background {

                            if selectedQuality == quality {

                                Capsule()
                                    .fill(.white)
                                    .padding(4)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth:.infinity)
        .frame(height: isIpad() ? 70 : 55)
        .background(.white.opacity(0.10))
        .modifier(
            GlassCardModifier(
                cornerRadius: isIpad() ? 35 : 28
            )
        )
//        .padding(.horizontal, 15)
    }
}

#Preview {
    MirrorView(broadcastManager: BroadCastPickerManager(commonVm: CommonConnectionViewModel()))
}
