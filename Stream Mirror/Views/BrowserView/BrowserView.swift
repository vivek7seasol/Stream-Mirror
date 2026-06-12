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
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.Browser, isCastingShow: false)
                
                Image("Online Browser")
                    .resizable()
                    .frame(width: isIpad() ? 170 : 150, height: isIpad() ? 140 : 120)
                
                VStack(alignment: .center, spacing: 8) {
                    Text(str.OnlineBrowser)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(str.Browsewebsitesquicklyandsecurely)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.textColor)
                }
                
                ZStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .foregroundStyle(AppColor.textColor)
                            .frame(width: 18, height: 18)
                        
                        ZStack(alignment: .leading) {
                            if text.isEmpty {
                                Text(str.Search)
                                    .foregroundColor(AppColor.textColor)
                                    .padding(.leading, 2)
                            }
                            
                            TextField("", text: $text, onCommit: {
                                selectedURL = text
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
                            selectedURL = "https://www.google.com/"
                            navigateToBrowser = true
                        }
                        Spacer()
                        webRow(title: str.Google, image: "Instagram") {
                            selectedURL = "https://www.instagram.com/"
                            navigateToBrowser = true
                        }
                        Spacer()
                        webRow(title: str.Vimeo, image: "Vimeo") {
                            selectedURL = "https://vimeo.com/"
                            navigateToBrowser = true
                        }
                        Spacer()
                    }
                    HStack(spacing: 5) {
                        Spacer()
                        webRow(title: str.Youtube, image: "Youtube") {
                            selectedURL = "https://www.youtube.com"
                            navigateToBrowser = true
                        }
                        Spacer()
                        webRow(title: str.Facebook, image: "Facebook") {
                            selectedURL = "https://www.facebook.com"
                            navigateToBrowser = true
                        }
                        Spacer()
                        webRow(title: str.Telegram, image: "Telegram") {
                            selectedURL = "https://web.telegram.org"
                            navigateToBrowser = true
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 10)
                
                Spacer()
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
                VStack {
                    Image(image)
                        .resizable()
                        .frame(width: isIpad() ? 60 : 40, height: isIpad() ? 60 : 40)
                    
                    Text(title)
                        .font(.system(size: 14,weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 130 : 100)
            .modifier(GlassCardModifier(cornerRadius: 25))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BrowserView(text: .constant(""))
}
