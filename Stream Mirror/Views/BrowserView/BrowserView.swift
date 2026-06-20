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
                                    adVm.registerTap()
                                    navigateToBrowser = true
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
                                adVm.registerTap()
                                selectedURL = "https://www.google.com/"
                                navigateToBrowser = true
                            }
                            Spacer()
                            webRow(title: str.Instagram, image: "Instagram") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                adVm.registerTap()
                                selectedURL = "https://www.instagram.com/"
                                navigateToBrowser = true
                            }
                            Spacer()
                            webRow(title: str.Vimeo, image: "Vimeo") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                adVm.registerTap()
                                selectedURL = "https://vimeo.com/"
                                navigateToBrowser = true
                            }
                            Spacer()
                        }
                        HStack(spacing: 5) {
                            Spacer()
                            webRow(title: str.Youtube, image: "Youtube") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                adVm.registerTap()
                                selectedURL = "https://www.youtube.com"
                                navigateToBrowser = true
                            }
                            Spacer()
                            webRow(title: str.Facebook, image: "Facebook") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                adVm.registerTap()
                                selectedURL = "https://www.facebook.com"
                                navigateToBrowser = true
                            }
                            Spacer()
                            webRow(title: str.Telegram, image: "Telegram") {
                                logAnalyticView(title: "Browser Preview", screen: "BrowserView")
                                adVm.registerTap()
                                selectedURL = "https://web.telegram.org"
                                navigateToBrowser = true
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
            YTView(initialURL: selectedURL)
        }
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
