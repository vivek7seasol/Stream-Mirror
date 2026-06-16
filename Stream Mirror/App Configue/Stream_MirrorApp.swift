//
//  Stream_MirrorApp.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

@main
struct Stream_MirrorApp: App {
    
    @StateObject var commonVM = CommonConnectionViewModel()
    @StateObject var TVRemoteVM = RemoteViewModel()
    @StateObject private var webServer = TVCastServer.shared
    @StateObject private var mirroringwebserver = TVMirrorServer.shared
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var wasInBackground = false
    @AppStorage(SessionKeys.isPro) var isPro = false
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SplashView()
            }
            .environmentObject(commonVM)
            .environmentObject(TVRemoteVM)
        }
        .onChange(of: scenePhase) { newPhase in
            
            switch newPhase {
                
            case .background:
                print("📴 App went to background")
                wasInBackground = true
                
            case .active:
                print("🔄 App became active")
                
                // ❗️ Sirf tab run kare jab actual background se aaye
                guard wasInBackground else {
                    print("🚫 Not from background → skip AppOpen")
                    return
                }
                
                wasInBackground = false
                
                // ✅ PRO USER → NO AD
                if isPro {
                    print("🚫 Pro user → skip AppOpen ad")
                    return
                }
                
                // ✅ अगर interstitial चल रही है → skip
                if AdState.shared.isShowingInterstitial {
                    print("⛔ Interstitial running → skip AppOpen")
                    return
                }
                
                // ✅ अगर already AppOpen चल रही है → skip
                if AppOpenAdManager.shared.isShowingAd {
                    return
                }
                
                AppOpenAdManager.shared.resetForForeground()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Task {
                        await AppOpenBackAdManager.shared.loadAd()
                        
                        AppOpenAdManager.shared.showAdIfAvailable {
                            print("✅ Foreground AppOpen finished")
                        }
                    }
                }
                
            default:
                break
            }
        }
    }
}
