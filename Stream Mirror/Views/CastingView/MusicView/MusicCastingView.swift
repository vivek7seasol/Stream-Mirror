//
//  MusicCastingView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI
internal import MediaPlayer

struct MusicCastingView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @ObservedObject var musicVM: MusicViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(
                    title: str.Music,
                    onBack: {
                        musicVM.stop()
                        dismiss()
                    }, onCast: {
                        
                    }
                )
                if let song = musicVM.currentlyPlaying {
                    
                    Image(
                        uiImage: song.artwork?.image(
                            at: CGSize(width: 500, height: 500)
                        ) ?? UIImage(named: "MusicPH")!
                    )
                    .resizable()
                    .scaledToFit()
                    .frame(minHeight: 300)
                    .frame(maxHeight: .infinity)
                    .padding()
                }
                
                HStack {
                    VStack(alignment:.leading,spacing: 5) {
                        Text(musicVM.currentlyPlaying?.title ?? "")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        Text(musicVM.currentlyPlaying?.artist ?? "")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColor.textColor)
                            .lineLimit(1)
                    }
                    Spacer()
                    singleButtonCard(image: "share") {

                        guard let url =
                                musicVM.currentlyPlaying?.assetURL
                        else { return }

                        let vc = UIActivityViewController(
                            activityItems: [url],
                            applicationActivities: nil
                        )

                        UIApplication.shared
                            .connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?
                            .windows
                            .first?
                            .rootViewController?
                            .present(vc, animated: true)
                    }
                    singleButtonCard(
                        image: musicVM.isFavorite(
                            song: musicVM.currentlyPlaying ?? musicVM.songs.first!
                        ) ? "like" : "dislike"
                    ) {

                        if let song = musicVM.currentlyPlaying {
                            musicVM.toggleFavorite(song: song)
                        }
                    }
                }
                .padding(.horizontal,15)
                .padding(.vertical,15)
                
                ZStack {
                    VStack(spacing: 25) {
                        
                        HStack(spacing: 35) {
                            
                            CircleButton(icon: "previous2") {
                                musicVM.playPrevious()
                                castMusic()
                            }

                            CircleButton(
                                icon: musicVM.isPlaying ? "pause" : "play",
                                size: 28,
                                size2: 50
                            ) {

                                if musicVM.isPlaying {
                                    musicVM.pause()
                                } else {
                                    musicVM.resume()
                                }
                            }

                            CircleButton(icon: "next2") {
                                musicVM.playNext()
                                castMusic()
                            }
                        }
                        
                        VStack(spacing: 8) {
                            
                            Slider(
                                value: Binding(
                                    get: {
                                        musicVM.playbackProgress
                                    },
                                    set: { value in
                                        musicVM.seek(to: value)
                                    }
                                ),
                                in: 0...1
                            )
                            .tint(.white)
                            
                            HStack {

                                Text(musicVM.currentTimeString)
                                Spacer()
                                Text(musicVM.currentlyPlaying?.durationString
                                    ?? "0:00")
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

            if !musicVM.isPlaying,
               let song = musicVM.currentlyPlaying {
                
                musicVM.play(song: song)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                castMusic()
            }
        }
    }
    
    func castMusic() {
        
        guard let mediaItem = musicVM.currentlyPlaying?.mediaItem else {
            return
        }
        
        // Audio session
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            options: [.mixWithOthers]
        )
        
        try? AVAudioSession.sharedInstance().setActive(true)
        
        // Cast to TV
        commonVM.exportAndUploadMusic(track: mediaItem)
    }
}

#Preview {
    MusicCastingView(musicVM: MusicViewModel())
}
