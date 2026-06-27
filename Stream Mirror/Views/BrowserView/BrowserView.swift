//
//  BrowserView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI

struct BrowserView: View {
    
    @Binding var text: String
    @State private var navigateToBrowser = false
    @State private var selectedURL = ""
    @AppStorage(SessionKeys.isPro) var isPro = false
    @EnvironmentObject var adVm : AdCountViewModel
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @State private var showDeviceList: Bool = false
    @State private var showPremium: Bool = false
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.Browser, isCastingShow: false)
                
                ScrollView(.vertical,showsIndicators: false) {
                    Image("Online Browser")
                        .resizable()
                        .frame(width: isIpad() ? 170 : 150, height: isIpad() ? 140 : 120)
                    
                    VStack(alignment: .center, spacing: 8) {
                        Text(str.OnlineBrowser)
                            .font(.system(size: isIpad() ? 26 : 20, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text(str.Browsewebsitesquicklyandsecurely)
                            .font(.system(size: isIpad() ? 18 : 12))
                            .foregroundStyle(AppColor.textColor)
                    }
                    
                    ZStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .foregroundStyle(AppColor.textColor)
                                .frame(width: isIpad() ? 24 : 18, height: isIpad() ? 24 : 18)
                            
                            ZStack(alignment: .leading) {
                                if text.isEmpty {
                                    Text(str.Search)
                                        .font(.system(size:  isIpad() ? 20 : 14))
                                        .foregroundColor(AppColor.textColor)
                                        .padding(.leading, 2)
                                }
                                
                                TextField("", text: $text, onCommit: {
                                    selectedURL = text
                                    if isPro {
                                        TVRemoteVM.handleDeviceAction {
                                            
                                        } onTV: {
                                            adVm.registerTap()
                                            navigateToBrowser = true
                                        } onNoDevice: {
                                            showDeviceList = true
                                        }
                                    } else {
                                        showPremium = true
                                    }
                                })
                                .foregroundColor(AppColor.textColor)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isIpad() ? 70 : 50)
                    .modifier(GlassCardModifier(cornerRadius: isIpad() ? 35 : 25))
                    .padding()
                    
                    HStack {
                        Divider()
                            .frame(width: isIpad() ? 7 : 4, height: isIpad() ? 26 : 22)
                            .background(.white)
                            .cornerRadius(15)
                        
                        Text(str.PopularWebsites)
                            .font(.system(size: isIpad() ? 24 : 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 15)
                    
                    VStack(spacing: 15) {
                        HStack(spacing: 5) {
                            Spacer()
                            webRow(title: str.Google, image: "Google") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                if isPro {
                                    TVRemoteVM.handleDeviceAction {
                                        
                                    } onTV: {
                                        
                                        selectedURL = "https://www.google.com/"
                                        adVm.registerTap()
                                        navigateToBrowser = true
                                    } onNoDevice: {
                                        showDeviceList = true
                                    }
                                } else {
                                    showPremium = true
                                }

                            }
                            Spacer()
                            webRow(title: str.Instagram, image: "Instagram") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                if isPro {
                                    TVRemoteVM.handleDeviceAction {
                                        
                                    } onTV: {
                                        
                                        adVm.registerTap()
                                        selectedURL = "https://www.instagram.com/"
                                        navigateToBrowser = true
                                    } onNoDevice: {
                                        showDeviceList = true
                                    }
                                } else {
                                    showPremium = true
                                }
                            }
                            Spacer()
                            webRow(title: str.Vimeo, image: "Vimeo") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                if isPro {
                                    TVRemoteVM.handleDeviceAction {
                                        
                                    } onTV: {
                                        adVm.registerTap()
                                        selectedURL = "https://vimeo.com/"
                                        navigateToBrowser = true
                                    } onNoDevice: {
                                        showDeviceList = true
                                    }
                                } else {
                                    showPremium = true
                                }
                            }
                            Spacer()
                        }
                        HStack(spacing: 5) {
                            Spacer()
                            webRow(title: str.Youtube, image: "Youtube") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                if isPro {
                                    TVRemoteVM.handleDeviceAction {
                                        
                                    } onTV: {
                                        adVm.registerTap()
                                        selectedURL = "https://www.youtube.com"
                                        navigateToBrowser = true
                                    } onNoDevice: {
                                        showDeviceList = true
                                    }
                                } else {
                                    showPremium = true
                                }
                            }
                            Spacer()
                            webRow(title: str.Facebook, image: "Facebook") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                if isPro {
                                    TVRemoteVM.handleDeviceAction {
                                        
                                    } onTV: {
                                        adVm.registerTap()
                                        selectedURL = "https://www.facebook.com"
                                        navigateToBrowser = true
                                    } onNoDevice: {
                                        showDeviceList = true
                                    }
                                } else {
                                    showPremium = true
                                }
                            }
                            Spacer()
                            webRow(title: str.Telegram, image: "Telegram") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                if isPro {
                                    TVRemoteVM.handleDeviceAction {
                                        
                                    } onTV: {
                                        adVm.registerTap()
                                        selectedURL = "https://web.telegram.org"
                                        navigateToBrowser = true
                                    } onNoDevice: {
                                        showDeviceList = true
                                    }
                                } else {
                                    showPremium = true
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 10)
                }
                Spacer()
                if !isPro {
                    NativeAd7()
                        .padding(.bottom,5)
                        .padding(.horizontal,15)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .appScreen()
        .onTapGesture {
            hideKeyboard()
        }
        .navigationDestination(isPresented: $navigateToBrowser) {
            YTView(initialURL: selectedURL, baseURL: "")
        }
        .sheet(isPresented: $showDeviceList) {
            DeviceListview(isPresented: $showDeviceList)
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

struct webRow: View {
    
    let title: String
    let image: String
    let action: () -> Void
    
    var body: some View {
        
        Button {
            action()
        } label: {
            
            ZStack {
                VStack(spacing: isIpad() ? 10 : 5) {
                    Image(image)
                        .resizable()
                        .frame(width: isIpad() ? 60 : 40, height: isIpad() ? 60 : 40)
                    
                    Text(title)
                        .font(.system(size: isIpad() ? 20 : 14,weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 150 : 100)
            .modifier(GlassCardModifier(cornerRadius: 25))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BrowserView(text: .constant(""))
}
