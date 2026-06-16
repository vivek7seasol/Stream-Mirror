//
//  Stream_MirrorApp.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

@main
struct Stream_MirrorApp: App {
    
    let adCountViewModel = AdCountViewModel.sharedd
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
            .environmentObject(adCountViewModel)
        }
        .onChange(of: scenePhase) { newPhase in
            
            switch newPhase {
                
            case .background:
                print("📴 App went to background")
                wasInBackground = true
                
            case .active:
                print("🔄 App became active")
                
                guard wasInBackground else {
                    print("🚫 Not from background → skip AppOpen")
                    return
                }
                wasInBackground = false
                
                if isPro {
                    print("🚫 Pro user → skip AppOpen ad")
                    return
                }
                if AdState.shared.isShowingInterstitial {
                    print("⛔ Interstitial running → skip AppOpen")
                    return
                }
                
                if AppOpenAdManager.shared.isShowingAd {
                    return
                }
                
                AppOpenAdManager.shared.resetForForeground()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Task {
                        AppOpenBackAdManager.shared.resetForForeground()
                        
                        await AppOpenBackAdManager.shared.loadAd()
                        
                        AppOpenBackAdManager.shared.showAdIfAvailable()
                    }
                }
                
            default:
                break
            }
        }
    }
}
