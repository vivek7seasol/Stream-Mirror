//
//  FavMusicListView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI
internal import MediaPlayer

struct FavMusicListView: View {
    
    @ObservedObject var musicVM = MusicViewModel()
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.FavoritesMusic,isCastingShow: false)
                
                if musicVM.favorites.isEmpty {
                    
                    Spacer()
                    
                    placeholderView(
                        image: "FavMusicListPH",
                        title: str.YourFavoritesAreEmpty,
                        title2: "",
                        isTitle2: false,height: 110,width: 130
                    )
                    
                } else {
                    
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            
                            ForEach(musicVM.favorites) { song in
                                
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
                                    }
                                )
                                .onTapGesture {
                                    musicVM.setMusics(
                                            musicVM.favorites,
                                            startIndex: musicVM.favorites.firstIndex(of: song) ?? 0
                                        )

                                        musicVM.showMusiccasting2 = true
                                }
                                .padding(.horizontal,15)
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                }
                
                Spacer()
            }
        }
        .appScreen()
        .navigationDestination(isPresented: $musicVM.showMusiccasting2) {
            MusicCastingView(musicVM: musicVM)
        }
    }
}

#Preview {
    FavMusicListView()
}
