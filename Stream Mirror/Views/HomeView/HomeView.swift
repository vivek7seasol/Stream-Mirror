//
//  HomeView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    
    @State private var text: String = ""
    @Binding var showDeviceList: Bool
    @State private var showYoutube: Bool = false
    @State private var showPhotos: Bool = false
    @State private var showVideos: Bool = false
    @State private var showMusic: Bool = false
    @State private var showBrowser: Bool = false
    @State private var showFiles: Bool = false
    @State private var showFindImage: Bool = false
    @State private var showIPTV: Bool = false
    @State private var showMirror: Bool = false
    @State private var showDrawing: Bool = false
    @State private var showCamera: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text(AppStrings.appName)
                        .font(.system(size: 24,weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        
                    } label: {
                        Image("premium")
                            .resizable()
                            .frame(width: isIpad() ? 30 : 26, height: isIpad() ? 30 : 26)
                    }
                    .buttonStyle(.plain)
                    
                }
                .padding(.horizontal, isIpad() ? 30 : 15)
                
                ScrollView(.vertical,showsIndicators: false) {
                    connectDeviceCard {
                        showDeviceList = true
                    }
                    
                    firstCard {
                        showMirror = true
                    } YTAction: {
                        showYoutube = true
                    } FileAction: {
                        showFiles = true
                    }
                    
                    NativeAd7()
                        .padding(.top,15)
                    
                    VStack(spacing:15) {
                        ZStack {
                            VStack(spacing:20) {
                                HStack {
                                    Divider()
                                        .frame(width: isIpad() ? 7 : 4,height: isIpad() ? 26 : 22)
                                        .background(.white)
                                        .cornerRadius(15)
                                    
                                    Text(str.DisplayCasting)
                                        .font(.system(size: isIpad() ? 24 : 18,weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity,alignment: .leading)
                                .padding(.horizontal)
                                HStack {
                                    Spacer()
                                    castingCard(title: str.Camera, image: "Camera") {
                                        showCamera = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Photo, image: "Photo") {
                                        showPhotos = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Video, image: "Video") {
                                        showVideos = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Music, image: "Music") {
                                        showMusic = true
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isIpad() ? 40 : 20)
                        .modifier(GlassCardModifier(cornerRadius: 30))
                        .padding(.horizontal, isIpad() ? 30 : 15)
                        
                        ZStack {
                            VStack(spacing:20) {
                                HStack {
                                    Divider()
                                        .frame(width: isIpad() ? 7 :4,height: isIpad() ? 26 : 22)
                                        .background(.white)
                                        .cornerRadius(15)
                                    
                                    Text(str.SmartTools)
                                        .font(.system(size: isIpad() ? 24 : 18,weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity,alignment: .leading)
                                .padding(.horizontal)
                                HStack {
                                    Spacer()
                                    castingCard(title: str.Browser, image: "Browser") {
                                        showBrowser = true
                                    }
                                    Spacer()
                                    castingCard(title: str.OnlineImage, image: "Online Image") {
                                        showFindImage = true
                                    }
                                    Spacer()
                                    castingCard(title: str.IPTV, image: "IPTV") {
                                        showIPTV = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Drawing, image: "Drawing") {
                                        showDrawing = true
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isIpad() ? 40 : 20)
                        .modifier(GlassCardModifier(cornerRadius: 30))
                        .padding(.horizontal, isIpad() ? 30 : 15)
                        
                    }
                    .padding(.top,15)
                }
                .padding(.bottom,100)
            }
        }
        .appScreen()
        .navigationDestination(isPresented: $showYoutube) {
            YTView(isOpenFromYT: true, initialURL: "https://www.youtube.com/")
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .navigationDestination(isPresented: $showPhotos) {
            PhotosView()
        }
        .navigationDestination(isPresented: $showVideos) {
            VideosView()
        }
        .navigationDestination(isPresented: $showMusic) {
            MusicView()
        }
        .navigationDestination(isPresented: $showBrowser) {
            BrowserView(text: $text)
        }
        .navigationDestination(isPresented: $showFiles) {
            Filesview()
        }
        .navigationDestination(isPresented: $showFindImage) {
            FindImageView(text: $text)
        }
        .navigationDestination(isPresented: $showIPTV) {
            IPTVView()
        }
        .navigationDestination(isPresented: $showDrawing) {
            SketchBoardListView()
        }
        .navigationDestination(isPresented: $showCamera) {
            CameraView()
        }
        .navigationDestination(isPresented: $showMirror) {
            MirrorView(broadcastManager: BroadCastPickerManager(commonVm: commonVM))
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        
        
    }
}

#Preview {
    HomeView(showDeviceList: .constant(false))
        .environmentObject(RemoteViewModel())
        .environmentObject(CommonConnectionViewModel())
}
