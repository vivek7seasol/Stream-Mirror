//
//  HomeView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

struct HomeView: View {
    
    @AppStorage(SessionKeys.isPro) var isPro = false
    
    @EnvironmentObject var adVm : AdCountViewModel
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
    @State private var showPremium = false
    @State private var showPremium2 = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text(AppStrings.appName)
                        .font(.system(size: 24,weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        showPremium2 = true
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
                        adVm.registerTap()
                        showMirror = true
                    } YTAction: {
                        adVm.registerTap()
                        showYoutube = true
                    } FileAction: {
                        adVm.registerTap()
                        showFiles = true
                    }
                    
                    if !isPro {
                        NativeAd7()
                            .padding(.top,15)
                    }
                    
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
                                        adVm.registerTap()
                                        showCamera = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Photo, image: "Photo") {
                                        adVm.registerTap()
                                        showPhotos = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Video, image: "Video") {
                                        adVm.registerTap()
                                        showVideos = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Music, image: "Music") {
                                        adVm.registerTap()
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
                                        adVm.registerTap()
                                        showBrowser = true
                                    }
                                    Spacer()
                                    castingCard(title: str.OnlineImage, image: "Online Image") {
                                        adVm.registerTap()
                                        showFindImage = true
                                    }
                                    Spacer()
                                    castingCard(title: str.IPTV, image: "IPTV") {
                                        adVm.registerTap()
                                        showIPTV = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Drawing, image: "Drawing") {
                                        adVm.registerTap()
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
        .onAppear {
            if isPro == false {
                if isShowPremium == "true" {
                    if !AppSession.shared.hasShownPremium {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showPremium = true
                            AppSession.shared.hasShownPremium = true
                        }
                    }
                }
            }
        }
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
        .fullScreenCover(isPresented: $showPremium) {
            PremiumView()
        }
        .fullScreenCover(isPresented: $showPremium2) {
            PremiumView()
        }
        
    }
}

#Preview {
    HomeView(showDeviceList: .constant(false))
        .environmentObject(RemoteViewModel())
        .environmentObject(CommonConnectionViewModel())
}
