//
//  RecordingView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

struct RecordingView: View {
    
    @EnvironmentObject var adVm : AdCountViewModel
    @StateObject private var recordingVM = ScreenRecordingViewModel()
    @State private var videoEnabled: Bool = true
    @State private var microphoneEnabled: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            VStack {
                Text(str.ScreenRecoding)
                    .font(.system(size: 24,weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .padding(.horizontal,15)
                
                ZStack {
                    VStack {
                        Image("Ready to Record")
                            .resizable()
                            .frame(width: isIpad() ? 150 : 110,height:  isIpad() ? 150 : 110)
                        
                        let timeText = recordingVM.recordingTime

                        Text(timeText)
                            .font(.system(size: isIpad() ? 36 : 30, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(recordingVM.recordingStatusText)
                            .font(.system(size: isIpad() ? 18 : 12))
                            .foregroundStyle(AppColor.textColor)
                            .padding(.vertical, 1)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical,30)
                .background(
                    recordingVM.isRecording
                    ? LinearGradient(
                        colors: [
                            Color("#EF4444"),
                            Color("#EF4444").opacity(0.60)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    : LinearGradient(
                        colors: [.clear, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .modifier(GlassCardModifier(cornerRadius: 30))
                .padding(.horizontal,15)
                
                ZStack {
                    VStack {
                        RecordingSettingCard(
                            image: "Video2",
                            title: str.Video,
                            isOn: $videoEnabled
                        )
                        
                        RecordingSettingCard(
                            image: "Microphone",
                            title: str.Microphone,
                            isOn: $microphoneEnabled
                        )
                        
                        RecordingSettingCard(
                            image: "My Recoding",
                            title: str.MyRecoding,
                            isToggle: false,
                            isOn: .constant(false)
                        ) {
                            adVm.registerTap()
                            recordingVM.showRecordingList = true
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical,10)
                .modifier(GlassCardModifier(cornerRadius: 30))
                .padding(.horizontal,15)
                .padding(.vertical,15)
                
                Spacer()
                
                Button {
                    if let defaults = UserDefaults(suiteName: AppStrings.groupID) {
                        defaults.set("recording", forKey: "broadcastMode")
                        defaults.set(true, forKey: "shouldSaveRecording")
                    }
                    
                    recordingVM.toggleRecording()

                } label: {
                    
                    ZStack {
                        Text(recordingVM.isRecording ? str.StopRecoding : str.StartRecoding)
                            .font(.system(size: isIpad() ? 22 : 16,weight: .medium))
                            .foregroundStyle(recordingVM.isRecording ?  .white : AppColor.textColor2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isIpad() ? 70 : 50)
                    .background(
                        Image(
                            isIpad()
                            ? (recordingVM.isRecording ? "IpadbtnBG2" : "IpadbtnBG")
                            : (recordingVM.isRecording ? "btnBG2" : "btnBG")
                        )
                        .resizable()
                        .scaledToFill()
                    )
                    .contentShape(Rectangle())
                    .cornerRadius(isIpad() ? 35 : 25)
                }
                .buttonStyle(.plain)
                .padding(.horizontal,15)
                .padding(.bottom,isIpad() ? 110 : 100)
            }
        }
        .appScreen(disableSwipeBack: true)
        .onAppear {
            recordingVM.checkBroadcastStatus()

            let defaults = UserDefaults(suiteName: AppStrings.groupID)

            videoEnabled = defaults?.object(forKey: "recordingVideoEnabled") as? Bool ?? true

            microphoneEnabled = defaults?.object(forKey: "recordingMicEnabled") as? Bool ?? true
            
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let nav = scene.windows.first(where: { $0.isKeyWindow })?
                    .rootViewController?
                    .findNavigationController() {
                    
                    nav.interactivePopGestureRecognizer?.delegate = SwipeBackDisabler.shared
                }
            }
        }
        .onDisappear {
            if let defaults = UserDefaults(suiteName: AppStrings.groupID) {
                defaults.set(false, forKey: "shouldSaveRecording")
            }
        }
        .onChange(of: scenePhase) { _ in
            if scenePhase == .active {
                recordingVM.checkBroadcastStatus()
            }
        }
        .onChange(of: videoEnabled) { value in
            UserDefaults(suiteName: AppStrings.groupID)?
                .set(value, forKey: "recordingVideoEnabled")
        }

        .onChange(of: microphoneEnabled) { value in
            UserDefaults(suiteName: AppStrings.groupID)?
                .set(value, forKey: "recordingMicEnabled")
        }
        .navigationDestination(isPresented: $recordingVM.showRecordingList) {
            RecordingListView(recordingVM: recordingVM) 
        }
    }
    
}


#Preview {
    RecordingView()
}
