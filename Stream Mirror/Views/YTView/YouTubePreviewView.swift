//
//  YouTubePreviewView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import SwiftUI
import AVFoundation
import AVKit

struct YouTubePreviewView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @ObservedObject var YTVM: YoutubeViewModel
    @StateObject private var playerVM = PlayerViewModel()
    var video: VideoResolution
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(
                    title: str.Preview,
                    onCast: {
                        YTVM.showDeviceList = true
                    }
                )
                
                // MARK: - Video Player (No default controls)
                if let player = playerVM.player {
                    CustomVideoPlayer(player: player)
                        .frame(maxHeight: .infinity)
                        .cornerRadius(20)
                        .padding()
                }
                
                Spacer()
                
                // MARK: - Controls Panel
                ZStack {
                    VStack(spacing: 25) {
                        
                        HStack(spacing: 35) {
                            
                            CircleButton(icon: "previous2") {
                                playerVM.seekBackward()
                            }

                            CircleButton(
                                icon: playerVM.isPlaying ? "pause" : "play",
                                size: 28,
                                size2: 50
                            ) {
                                playerVM.togglePlayPause()
                            }

                            CircleButton(icon: "next2") {
                                playerVM.seekForward()
                            }
                        }
                        
                        VStack(spacing: 8) {
                            
                            Slider(
                                value: $playerVM.sliderValue,
                                in: 0...playerVM.totalDuration,
                                onEditingChanged: { editing in

                                    playerVM.isDragging = editing

                                    if !editing {
                                        playerVM.seekTo(
                                            seconds: playerVM.sliderValue
                                        )
                                    }
                                }
                            )
                            .tint(.white)
                            
                            HStack {
                                Text(
                                    playerVM.formatTime(
                                        playerVM.isDragging
                                        ? playerVM.sliderValue
                                        : playerVM.currentTime
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
        .appScreen()
        .onAppear {
            if let player = YTVM.player {
                playerVM.setup(with: player)
            }
            castVideo()
        }
        .onDisappear {
            playerVM.cleanup()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                commonVM.setTVPlaceHolder(connectedTvType: commonVM.connectedTvType ?? .ANDROID)
            }
        }
        .fullScreenCover(isPresented: $YTVM.showDeviceList) {
            DeviceListview()
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
    }
    
    func castVideo() {

        guard let mediaURL = URL(string: video.videoURL) else {
            print("❌ Invalid video URL")
            return
        }

        TVRemoteVM.handleDeviceAction {

        } onTV: {

            print("✅ Casting Started")
            print("🎥 URL:", mediaURL)

            // ANDROID TV / Chromecast
            if commonVM.connectedTvType == .ANDROID || commonVM.connectedTvType == .SAMSUNG {

                commonVM.castViewModel.castMedia(mediaURL, mediaType: "video/mp4", title: AppStrings.appName, des: "")
            }

            // LG TV
            else if commonVM.connectedTvType == .LG || commonVM.connectedTvType == .ROKU {

                commonVM.connectSDKDiscoveryModel.sendMediaToLGTVYT(
                    mediaUrl: mediaURL,
                    mimeType: "text/html"
                )
            }

        } onNoDevice: {

            YTVM.showDeviceList = true
        }
    }
    
}

// MARK: - CircleButton
struct CircleButton: View {
    
    var icon: String
    var size: CGFloat = 18
    var size2: CGFloat = 34
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(icon)
                .resizable()
                .frame(
                    width: isIpad() ? size + 10 : size,
                    height: isIpad() ? size + 10 : size
                )
                .frame(
                    width: isIpad() ? size2 + 10 : size2,
                    height: isIpad() ? size2 + 10 : size2
                )
                .modifier(GlassCardModifier(cornerRadius: size2 / 2))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    YouTubePreviewView(YTVM: YoutubeViewModel(), video: VideoResolution(
        id: "1",
        videoName: "Demo Video",
        videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        videothumImage: "",
        videoAuthor: "YouTube",
        videoResolution: "360p"
    ))
}
