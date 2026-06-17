//
//  SettingView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

struct SettingView: View {
    
    @AppStorage(SessionKeys.isPro) var isPro = false
    @State private var showPremium = false
    @State private var navigateToLanguage: Bool = false
    @State private var refreshID = UUID()
    
    var body: some View {
        ZStack {
            VStack {
                Text(str.Settings)
                    .font(.system(size: 24,weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .padding(.horizontal,15)
                
                ScrollView(.vertical,showsIndicators: false) {
                    VStack(spacing:15) {
                        settingRow(title: str.Language, image: "Language") {
                            navigateToLanguage = true
                        }
                        settingRow(title: str.ShareApp, image: "Share App") {
                            let url = URL(string: "https://apps.apple.com/app/\(AppId)")!
                            
                            let activityVC = UIActivityViewController(
                                activityItems: [url],
                                applicationActivities: nil
                            )
                            
                            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                                
                                root.present(activityVC, animated: true)
                            }
                        }
                        settingRow(title: str.RateUs, image: "Rate Us") {
                            openUrlInSafari(strUrl: REVIEW_LINK)
                        }
                        settingRow(title: str.PrivacyPolicy, image: "Privacy Policy") {
                            openUrlInSafari(strUrl: PRIVACYPOLICY)
                        }
                        settingRow(title: str.TermsofUse, image: "Terms of Use") {
                            openUrlInSafari(strUrl: TEARMS)
                        }
                        settingRow(title: str.EULA, image: "EULA") {
                            openUrlInSafari(strUrl: EULA)
                        }
                    }
                }
                
                Spacer()
                if !isPro {
                    NativeAd7()
                        .padding(.bottom,100)
                }
            }
        }
        .appScreen()
        .id(refreshID)
        .onAppear {
            refreshID = UUID()
        }
        .navigationDestination(isPresented: $navigateToLanguage) {
            LanguageView(isOpenFromSplash: false)
        }
    }
    
    func openUrlInSafari(strUrl: String) {
        guard let url = URL(string: strUrl) else {
            debugPrint("❌ URL invalid")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            debugPrint("❌ System can't open this URL!")
        }
    }
}

struct settingRow: View {
    
    let title: String
    let image: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            
            ZStack {
                HStack {
                    Image(image)
                        .resizable()
                        .frame(width: isIpad() ? 60 : 50,height: isIpad() ? 60 : 50)
                    
                    Text(title)
                        .font(.system(size: 16,weight: .medium))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image("next")
                        .resizable()
                        .frame(width: isIpad() ? 30 : 20,height: isIpad() ? 30 : 20)
                }
                .padding(.horizontal,15)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 90 : 70)
            .modifier(GlassCardModifier(cornerRadius: 20))
            .padding(.horizontal,15)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingView()
}
