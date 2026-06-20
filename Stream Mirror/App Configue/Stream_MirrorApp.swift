//
//  Stream_MirrorApp.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI
import FirebaseCore
import FirebaseCrashlytics
import FirebasePerformance

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
    
    init() {
        
        FirebaseApp.configure()
        FirebaseApp.debugDescription()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        Crashlytics.crashlytics().log("App Launched")
        // Enable performance monitoring
        Performance.sharedInstance().isInstrumentationEnabled = true
        Performance.sharedInstance().isDataCollectionEnabled = true
        FirebaseConfiguration.shared.setLoggerLevel(FirebaseLoggerLevel.min)
        
        let savedLang = UserDefaults.standard.string(forKey: SessionKeys.appLanguage) ?? "en"
        LocalizationHelper.shared.setLanguage(code: savedLang)
        
        print("🌍 App Language Applied (Init):", savedLang)
    }
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
                if AppOpenAdManager.shared.isShowingAd || AppOpenBackAdManager.shared.isShowingAd {
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Task {
                        let isHomeOpened = UserDefaults.standard.bool(forKey: SessionKeys.isHomeOpened)
                        if isHomeOpened {
                            print("Foreground: HomeScreen opened → load regular app open ad")
                            AppOpenBackAdManager.shared.resetForForeground()
                            await AppOpenBackAdManager.shared.loadAd()
                            AppOpenBackAdManager.shared.showAdIfAvailable { }
                        } else {
                            print("Foreground: HomeScreen NOT opened → load second app open ad")
                            AppOpenAdManager.shared.resetForForeground()
                            await AppOpenAdManager.shared.loadAd()
                            AppOpenAdManager.shared.showAdIfAvailable { }
                        }
                    }
                }
                
            default:
                break
            }
        }
    }
}
