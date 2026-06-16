//
//  FavMusicListView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI
internal import MediaPlayer

struct FavMusicListView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @ObservedObject var musicVM = MusicViewModel()
    @AppStorage(SessionKeys.isPro) var isPro = false
    @EnvironmentObject var adVm : AdCountViewModel
    @State private var showPremium = false
    
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
                        if !isPro {
                            NativeAd7()
                                .padding(.top,15)
                        }
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
                                    if isPro {
                                        TVRemoteVM.handleDeviceAction {
                                            
                                        } onTV: {
                                            adVm.registerTap()
                                            musicVM.setMusics(
                                                musicVM.favorites,
                                                startIndex: musicVM.favorites.firstIndex(of: song) ?? 0
                                            )
                                            
                                            musicVM.showMusiccasting2 = true
                                        } onNoDevice: {
                                            musicVM.showDeviceList = true
                                        }
                                    } else {
                                        showPremium = true
                                    }
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
        .appScreen(isPresented: $musicVM.showDeviceList) {
            DeviceListview(isPresented: $musicVM.showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .navigationDestination(isPresented: $musicVM.showMusiccasting2) {
            MusicCastingView(musicVM: musicVM)
        }
        .fullScreenCover(isPresented: $showPremium, onDismiss: {
            if pro_close_inter == "true" {
                adVm.registerTap()
            }
        }, content: {
            PremiumView()
        })
    }
}

#Preview {
    FavMusicListView()
}
