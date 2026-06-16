//
//  VideoCastingView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI
internal import Photos

struct VideoCastingView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var playerVM = PlayerViewModel()
    
    var assets: [PHAsset]
    var selectedIndex: Int
    
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            VStack {
                
                CommonStatusView(
                    title: str.Preview,
                    onCast: {
                        playerVM.showDeviceList = true
                    }
                )
                
                if let player = playerVM.player {
                    
                    CustomVideoPlayer(
                        player: player
                    )
                    .frame(maxHeight: .infinity)
                    .cornerRadius(20)
                    .padding()
                }
                
                ZStack {
                    VStack(spacing: 25) {
                        
                        HStack(spacing: 35) {
                            
                            CircleButton(icon: "previous2") {

                                guard !assets.isEmpty else {
                                    return
                                }

                                currentIndex =
                                currentIndex == 0
                                ? assets.count - 1
                                : currentIndex - 1

                                loadVideo()
                            }

                            CircleButton(
                                icon: playerVM.isPlaying
                                    ? "pause"
                                    : "play",
                                size: 28,
                                size2: 50
                            ) {

                                playerVM.togglePlayPause()
                            }

                            CircleButton(icon: "next2") {

                                guard !assets.isEmpty else {
                                    return
                                }

                                currentIndex =
                                (currentIndex + 1) % assets.count

                                loadVideo()
                            }
                        }
                        
                        VStack(spacing: 8) {
                            
                            Slider(
                                value: $playerVM.sliderValue,
                                in: 0...playerVM.totalDuration
                            ) { editing in

                                playerVM.isDragging = editing

                                if !editing {

                                    playerVM.seekTo(
                                        seconds: playerVM.sliderValue
                                    )
                                }
                            }
                            .tint(.white)
                            
                            HStack {

                                Text(
                                    playerVM.formatTime(
                                        playerVM.currentTime
                                    )
                                )

                                Spacer()

                                Text(
                                    playerVM.formatTime(
                                        playerVM.totalDuration
                                    )
                                )
                            }
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                }
                .frame(maxWidth: .infinity)
                .modifier(GlassCardModifier(cornerRadius: 35))
                .padding(.horizontal, 15)
            }
        }
        .appScreen(isPresented: $playerVM.showDeviceList) {
            DeviceListview(isPresented: $playerVM.showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .onAppear {

            currentIndex = selectedIndex

            loadVideo()
        }
        .onDisappear {
            commonVM.setTVPlaceHolder(connectedTvType: commonVM.connectedTvType ?? .ANDROID)
            playerVM.cleanup()
        }
    }
    
    func castVideo(url: URL) {
        
        print("✅ Casting Video:", url)
        
        commonVM.compressAndUploadVideo(url)
    }
    
    private func loadVideo() {

        guard assets.indices.contains(currentIndex) else {
            return
        }

        let asset = assets[currentIndex]

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true

        PHImageManager.default()
            .requestAVAsset(
                forVideo: asset,
                options: options
            ) { avAsset, _, _ in

                guard let urlAsset = avAsset as? AVURLAsset else {
                    return
                }

                DispatchQueue.main.async {

                    let player = AVPlayer(
                        url: urlAsset.url
                    )

                    playerVM.setup(
                        with: player
                    )
                    castVideo(url: urlAsset.url)
                }
            }
    }
}

#Preview {
    VideoCastingView(assets: [], selectedIndex: 0)
}
