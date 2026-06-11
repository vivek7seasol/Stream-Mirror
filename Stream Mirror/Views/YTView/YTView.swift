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
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var YTVM = YoutubeViewModel()
    let initialURL: String
    
    var body: some View {
        ZStack {
            
            VStack {
                CommonStatusView(
                    title: str.Youtube,
                    onCast: {
                        YTVM.showDeviceList = true
                    }
                )
                
                ZStack(alignment:.bottomTrailing) {
                    YoutubePreview(
                        webView: $YTVM.webView,
                        isLoading: $YTVM.isLoading,
                        onVideoDetected: { url in
                            guard let url else { return }
                            YTVM.processAndFetchVideoDetails(from: url)
                        }
                    )
                    //
                    Button {

                        TVRemoteVM.handleDeviceAction {
                            
                        } onTV: {
                            YTVM.selectedVideo = YTVM.videoList.first

                            YTVM.preparePlayer()

                            YTVM.showPreview = true
                        } onNoDevice: {
                            YTVM.showDeviceList = true
                        }

                    } label: {
                        ZStack {
                            LottieFile2(animationFileName: MyLottieFiles.WifiTv, loopMode: .loop)
                                .frame(width: isIpad() ? 130 :  40, height: isIpad() ? 130 :  40)
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
                
                ZStack {
                    HStack {
                        Spacer()
                        Button {
                            if YTVM.webView.canGoBack {
                                YTVM.webView.goBack()
                            }
                        } label: {
                            Image("back")
                                .resizable()
                                .frame(width: isIpad() ? 28 : 24,height: isIpad() ? 28 : 24)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        Button {
                            if YTVM.webView.canGoBack {
                                YTVM.webView.goForward()
                            }
                        } label: {
                            Image("next")
                                .resizable()
                                .frame(width: isIpad() ? 28 : 24,height: isIpad() ? 28 : 24)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        Button {
                            if let url = URL(string: initialURL) {
                                YTVM.webView.load(URLRequest(url: url))
                            }
                        } label: {
                            Image("home")
                                .resizable()
                                .frame(width: isIpad() ? 28 : 24,height: isIpad() ? 28 : 24)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        Button {
                            YTVM.webView.reload()
                        } label: {
                            Image("refresh")
                                .resizable()
                                .frame(width: isIpad() ? 28 : 24,height: isIpad() ? 28 : 24)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }

                }
                .frame(maxWidth: .infinity)
                .frame(height: isIpad() ? 70 : 60)
                .modifier(GlassCardModifier(cornerRadius: isIpad() ? 35 : 30))
                .padding(.horizontal,15)
                Spacer()
            }
        }
        .appScreen()
        .onAppear {
            YTVM.loadSearchOrURL(text: "https://www.youtube.com/")
        }
        .navigationDestination(isPresented: $YTVM.showPreview) {

            if let video = YTVM.selectedVideo {

                YouTubePreviewView(
                    YTVM: YTVM,
                    video: video
                )
            }
        }
        .fullScreenCover(isPresented: $YTVM.showDeviceList) {
            DeviceListview()
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
    }
}

#Preview {
    YTView(initialURL: "")
}
