//
//  IPTVCastingView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI
import AVFoundation

struct IPTVCastingView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var playerVM = PlayerViewModel()
    let channel: Channel
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.IPTV,onCast: {
                    playerVM.showDeviceList = true
                })
                
                ZStack(alignment:.topTrailing) {
                    if let player = playerVM.player {
                        
                        CustomVideoPlayer(
                            player: player
                        )
                        .frame(maxHeight: .infinity)
                        .cornerRadius(20)
                        .padding()
                    }
                    
                    ZStack(alignment:.topTrailing) {
                        HStack(spacing:8) {
                            Image("live")
                                .resizable()
                                .frame(width: isIpad() ? 20 : 16,height:  isIpad() ? 20 : 16)
                            
                            Text(str.Live)
                                .font(.system(size: 14,weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal,20)
                    .frame(height: isIpad() ? 40 : 32)
                    .background(Color("#EE2A2A"))
                    .cornerRadius(isIpad() ? 20 : 16)
                    .padding()
                }
                
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
                            
                            HStack {

                                Text(
                                    playerVM.formatTime(
                                        playerVM.currentTime
                                    )
                                )

                                Spacer()

                                Text(str.Live)
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

            guard let urlString = channel.url,
                  let url = URL(string: urlString) else {
                return
            }

            let player = AVPlayer(url: url)

            playerVM.setup(with: player)

            castIPTV()
        }
        .onDisappear {
            commonVM.setTVPlaceHolder(connectedTvType: commonVM.connectedTvType ?? .ANDROID)
            playerVM.cleanup()
        }
    }
    
    func castIPTV() {

        guard let urlString = channel.url,
              let url = URL(string: urlString) else {
            return
        }
        
        commonVM.CastMedia(
            url: url,
            mediaType: "video/mp4",
            title: channel.name ?? "",
            des: "",
            imgHei: 1024,
            imgWid: 1024
        )
    }
}

#Preview {
//    IPTVCastingView(, channel: <#Channel#>)
}
