//
//  MusicView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI
internal import MediaPlayer

struct MusicView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var musicVM = MusicViewModel()
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(
                    title: str.Music,
                    onBack: {
                        musicVM.stop()
                        dismiss()
                    },
                    onCast: {}
                ) {
                    singleButtonCard(image: "like") {
                        musicVM.showFavMusicList = true
                    }
                }
                
                if musicVM.isLoadings && !musicVM.showPlaceholder {
                    
                    Spacer()

                    ProgressView("Loading Music...")
                        .tint(.white)
                        .foregroundColor(.white)

                    Spacer()

                } else if musicVM.songs.isEmpty && musicVM.showPlaceholder {

                    Spacer()

                    placeholderView(
                        image: "MusicListPH",
                        title: str.NoMusicAvailable,
                        title2: "",
                        isTitle2: false
                    )
                    Spacer()

                } else {
                    
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            
                            ForEach(musicVM.songs) { song in
                                MusicRow(
                                    artwork: song.artwork,
                                    musicName: song.title,
                                    artistName: song.artist,
                                    totalDuration: song.durationString,
                                    imgLike: musicVM.isFavorite(song: song) ? "like" : "dislike",
                                    onLikeTap: {
                                        musicVM.toggleFavorite(song: song)
                                    }, imgPlayPause:
                                        musicVM.currentlyPlaying?.id == song.id
                                        ? (musicVM.isPlaying ? "pause" : "play")
                                        : "play",
                                    onPlayPauseTap: {

                                        if musicVM.currentlyPlaying?.id == song.id {

                                            if musicVM.isPlaying {
                                                musicVM.pause()
                                            } else {
                                                musicVM.resume()
                                            }

                                        } else {

                                            musicVM.play(song: song)
                                        }
                                    }, showPlayPause: true
                                )
                                .onTapGesture {
                                    musicVM.setMusics(
                                            musicVM.songs,
                                            startIndex: musicVM.songs.firstIndex(of: song) ?? 0
                                        )

                                        musicVM.showMusiccasting = true
                                }
                                .padding(.horizontal,15)
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                }
                
                if let song = musicVM.currentlyPlaying {

                    ZStack {

                        HStack(spacing: 15) {

                            Image(
                                uiImage: song.artwork?.image(
                                    at: CGSize(width: 80, height: 80)
                                ) ?? UIImage(named: "MusicPH")!
                            )
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 15))

                            VStack(alignment: .leading, spacing: 4) {

                                Text(song.title)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Text(song.artist)
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColor.textColor)
                                    .lineLimit(1)
                            }

                            Spacer()

                            CircleButton(icon: "previous2", size2: 40) {
                                musicVM.playPrevious()
                            }

                            CircleButton(
                                icon: musicVM.isPlaying ? "pause" : "play",
                                size: 22,
                                size2: 52
                            ) {

                                if musicVM.isPlaying {
                                    musicVM.pause()
                                } else {
                                    musicVM.resume()
                                }
                            }

                            CircleButton(icon: "next2", size2: 40) {
                                musicVM.playNext()
                            }
                        }
                        .padding(.horizontal, 20)

                        VStack {

                            ProgressView(
                                value: musicVM.playbackProgress
                            )
                            .tint(.white)

                            Spacer()
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
                    .modifier(
                        GlassCardModifier(
                            cornerRadius: 25
                        )
                    )
                    .padding(.horizontal, 15)
                }
            }
        }
        .appScreen()
        .onAppear {
            musicVM.requestMusicAccessAndFetch()
        }
        .navigationDestination(isPresented: $musicVM.showFavMusicList) {
            FavMusicListView(musicVM: musicVM)
        }
        .navigationDestination(isPresented: $musicVM.showMusiccasting) {
            MusicCastingView(musicVM: musicVM)
        }
    }
}

#Preview {
    MusicView()
        .environmentObject(CommonConnectionViewModel())
        .environmentObject(RemoteViewModel())
       
}
