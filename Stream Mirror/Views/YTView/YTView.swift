//
//  YTView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import SwiftUI
import Lottie
internal import WebKit

struct YTView: View {
    
    @AppStorage(SessionKeys.isPro) var isPro = false
    @EnvironmentObject var adVm : AdCountViewModel
    @State private var showPremium = false
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var YTVM = YoutubeViewModel()
    var isOpenFromYT = false
    let initialURL: String
    
    var body: some View {
        ZStack {
            
            VStack {
                if isOpenFromYT {
                    CommonStatusView(
                        title: str.Youtube,
                        onCast: {
                            YTVM.showDeviceList = true
                        }
                    )
                } else {
                    CommonStatusView(title: str.Browser,isCastingShow: false)
                }
                
                ZStack(alignment:.bottomTrailing) {
                    YoutubePreview(
                        webView: $YTVM.webView,
                        isLoading: $YTVM.isLoading,
                        viewModel: YTVM,
                        onVideoDetected: { url in
                            guard let url else { return }
                            YTVM.processAndFetchVideoDetails(from: url)
                        }
                    )
                    
                    if isOpenFromYT {
                        Button {
                            if isPro {
                                TVRemoteVM.handleDeviceAction {
                                    
                                } onTV: {
                                    adVm.registerTap()
                                    YTVM.selectedVideo = YTVM.videoList.first
                                    
                                    YTVM.preparePlayer()
                                    
                                    YTVM.showPreview = true
                                } onNoDevice: {
                                    YTVM.showDeviceList = true
                                }
                            } else {
                                showPremium = true
                            }
                            
                        } label: {
                            ZStack {
                                LottieFile2(animationFileName: MyLottieFiles.WifiTv, loopMode: .loop)
                                    .frame(width: isIpad() ? 60 :  40, height: isIpad() ? 60 :  40)
                                    .rotationEffect(.degrees(0))
                            }
                            .frame(width: isIpad() ? 70 : 56,height: isIpad() ? 70 : 56)
                            .background(.black)
                            .cornerRadius( isIpad() ? 35 :28)
                            .frame(width: isIpad() ? 80 : 66,height: isIpad() ? 80 : 66)
                            .modifier(GlassCardModifier(cornerRadius: isIpad() ? 40 : 33))
                        }
                        .padding(.trailing, 3)
                        .padding(.bottom, 3)
                        .disabled(YTVM.videoList.isEmpty)
                        .opacity(YTVM.videoList.isEmpty ? 0.7 : 1)
                    }
                }
                
                ZStack {
                    HStack {
                        Spacer()
                        Button {
                            YTVM.webView.goBack()
                        } label: {
                            Image("back")
                                .resizable()
                                .frame(width: isIpad() ? 30 : 24,
                                       height: isIpad() ? 30 : 24)
                        }
                        .buttonStyle(.plain)
                        .disabled(!YTVM.canGoBack)
                        .opacity(YTVM.canGoBack ? 1 : 0.4)
                        
                        Spacer()
                        Button {
                            YTVM.webView.goForward()
                        } label: {
                            Image("next")
                                .resizable()
                                .frame(width: isIpad() ? 30 : 24,
                                       height: isIpad() ? 30 : 24)
                        }
                        .buttonStyle(.plain)
                        .disabled(!YTVM.canGoForward)
                        .opacity(YTVM.canGoForward ? 1 : 0.4)
                        
                        Spacer()
                        Button {
                            if let url = URL(string: initialURL) {
                                YTVM.webView.load(URLRequest(url: url))
                            }
                        } label: {
                            Image("home")
                                .resizable()
                                .frame(width: isIpad() ? 30 : 24,height: isIpad() ? 30 : 24)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        Button {
                            YTVM.webView.reload()
                        } label: {
                            Image("refresh")
                                .resizable()
                                .frame(width: isIpad() ? 30 : 24,height: isIpad() ? 30 : 24)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }

                }
                .frame(maxWidth: .infinity)
                .frame(height: isIpad() ? 80 : 60)
                .modifier(GlassCardModifier(cornerRadius: isIpad() ? 40 : 30))
                .padding(.horizontal, isIpad() ? 30 : 15)
                Spacer()
                if !isPro {
                    NativeAd6()
                        .padding(.top,15)
                        .padding(.bottom,5)
                        .padding(.horizontal,15)
                }
            }
        }
        .appScreen()
        .onAppear {
            YTVM.loadSearchOrURL(text: initialURL)
        }
        .navigationDestination(isPresented: $YTVM.showPreview) {

            if let video = YTVM.selectedVideo {

                YouTubePreviewView(
                    YTVM: YTVM,
                    video: video
                )
            }
        }
        .sheet(isPresented: $YTVM.showDeviceList) {
            DeviceListview(isPresented: $YTVM.showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
                .presentationDetents([.height(isIpad() ? 830 : 700)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(LinearGradient(colors: [Color("#222222"), Color("#1A1A1A"), Color("#111111")], startPoint: .topLeading, endPoint: .bottomTrailing))
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
    YTView(initialURL: "")
}
