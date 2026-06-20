//
//  HomeView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI
import StoreKit

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
    @State private var showRateAlert = false
    
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
                    connectDeviceCard(TVRemoteVM: TVRemoteVM) {
                        showDeviceList = true
                    }
                    
                    firstCard {
                        logAnalyticView(title: "Screen Mirror", screen: "Home")
                        adVm.registerTap()
                        showMirror = true
                    } YTAction: {
                        logAnalyticView(title: "Youtube", screen: "Home")
                        adVm.registerTap()
                        showYoutube = true
                    } FileAction: {
                        logAnalyticView(title: "Files Listing", screen: "Home")
                        adVm.registerTap()
                        showFiles = true
                    }
                    
                    if !isPro {
                        NativeAd7()
                            .padding(.top,15)
                            .padding(.horizontal, isIpad() ? 30 : 15)
                        
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
                                        logAnalyticView(title: "Camera", screen: "Home")
                                        adVm.registerTap()
                                        showCamera = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Photo, image: "Photo") {
                                        logAnalyticView(title: "Photo Listing", screen: "Home")
                                        adVm.registerTap()
                                        showPhotos = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Video, image: "Video") {
                                        logAnalyticView(title: "Video Listing", screen: "Home")
                                        adVm.registerTap()
                                        showVideos = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Music, image: "Music") {
                                        logAnalyticView(title: "Music Listing", screen: "Home")
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
                                        logAnalyticView(title: "Browser", screen: "Home")
                                        adVm.registerTap()
                                        showBrowser = true
                                    }
                                    Spacer()
                                    castingCard(title: str.OnlineImage, image: "Online Image") {
                                        logAnalyticView(title: "Online image", screen: "Home")
                                        adVm.registerTap()
                                        showFindImage = true
                                    }
                                    Spacer()
                                    castingCard(title: str.IPTV, image: "IPTV") {
                                        logAnalyticView(title: "IPTV", screen: "Home")
                                        adVm.registerTap()
                                        showIPTV = true
                                    }
                                    Spacer()
                                    castingCard(title: str.Drawing, image: "Drawing") {
                                        logAnalyticView(title: "drawing", screen: "Home")
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
                .padding(.bottom, isIpad() ? 120 : 100)
            }
        }
        .appScreen(disableSwipeBack: true)
        .task {
            logAnalyticView(title: "Home Screen", screen: "Home")
        }
        .onAppear {
            UserDefaults.standard.set(true, forKey: SessionKeys.isHomeOpened)
            let didAskForReview = UserDefaults.standard.bool(forKey: "didAskForReview")

            if !isPro {
                if isShowPremium == "true" {

                    if !AppSession.shared.hasShownPremium {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showPremium = true
                            AppSession.shared.hasShownPremium = true
                        }
                    }

                } else {

                    if !didAskForReview &&
                       !AppSession.shared.hasShownRateAlert {

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showRateAlert = true
                            AppSession.shared.hasShownRateAlert = true
                        }
                    }
                }

            } else {

                if !didAskForReview &&
                   !AppSession.shared.hasShownRateAlert {

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showRateAlert = true
                        AppSession.shared.hasShownRateAlert = true
                    }
                }
            }

            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let nav = scene.windows.first(where: { $0.isKeyWindow })?
                    .rootViewController?
                    .findNavigationController() {

                    nav.interactivePopGestureRecognizer?.delegate = SwipeBackDisabler.shared
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
        .fullScreenCover(isPresented: $showPremium,onDismiss: {
            if !UserDefaults.standard.bool(forKey: "didAskForReview") {
                showRateAlert = true
            }
        }) {
            PremiumView()
        }
        .fullScreenCover(isPresented: $showPremium2) {
            PremiumView()
        }
        .alert(str.DoyoulikeourApp, isPresented: $showRateAlert) {
            
            Button(str.No, role: .cancel) { }
            
            Button(str.Yes) {
                handlePostReviewLogic()
            }
            
        } message: {
            Text(str.rateMsg)
        }
        
    }
    
    func handlePostReviewLogic() {
        
        rateApp()
        
        UserDefaults.standard.set(true, forKey: "didAskForReview")
    }
    
    func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

#Preview {
    HomeView(showDeviceList: .constant(false))
        .environmentObject(RemoteViewModel())
        .environmentObject(CommonConnectionViewModel())
}
