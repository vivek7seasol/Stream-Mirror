//
//  AppsViewModel.swift
//  TV Remote
//
//  Created by iOS Developer on 25/08/2025.
//

import Foundation
import Combine

class AppsViewModel: ObservableObject {
    @Published var ASApps: [AndroidSamsungTVApps] = []
    @Published var RFApps: [RokuFireTVApps] = []
    @Published var LgApps: [LGApps] = []

    @Published var isLoadingApps = false
    @Published var appFetchError: String?
        
    var tvRemoteViewModel: RemoteViewModel
    
    init(tvRemoteViewModel: RemoteViewModel) {
        self.tvRemoteViewModel = tvRemoteViewModel
    }
    
    // MARK: - App Management
    func fetchApps() {
        guard let tvType = tvRemoteViewModel.connectedTVType else {
            appFetchError = "No TV connected"
            return
        }
        
        isLoadingApps = true
        appFetchError = nil
        
        switch tvType {
        case .ANDROID:
            fetchAndroidApps()
        case .SAMSUNG:
            fetchSamsungApps()
        case .FIRE:
            fetchFireTVApps()
        case .ROKU:
            fetchRokuApps()
        case .LG:
            fetchLGApps()
        case .AIRPLAY:
            break
        case .NONETV:
            break
        }
    }
    
    private func fetchAndroidApps() {
        let androidApps = [
            AndroidSamsungTVApps(name: "Netflix", imageName: "netflix", url: "https://www.netflix.com/title", tvApp: .netflix()),
            AndroidSamsungTVApps(name: "Prime Video", imageName: "prime_video", url: "https://www.primevideo.com", tvApp: .primeVideo()),
            AndroidSamsungTVApps(name: "YouTube", imageName: "youtube", url: "https://www.youtube.com", tvApp: .youtube()),
            AndroidSamsungTVApps(name: "Disney+", imageName: "disney_plus", url: "https://www.disneyplus.com", tvApp: .disnep()),
            AndroidSamsungTVApps(name: "Tubi", imageName: "tubi", url: "https://www.tubi.tv", tvApp: .tubi()),
            AndroidSamsungTVApps(name: "Peacock", imageName: "peacock", url: "https://www.peacocktv.com", tvApp: .peacock()),
            AndroidSamsungTVApps(name: "Pluto TV", imageName: "pluto", url: "https://pluto.tv", tvApp: .plutoTV()),
            AndroidSamsungTVApps(name: "Spotify", imageName: "spotify", url: "https://www.spotify.com", tvApp: .spotify()),
            AndroidSamsungTVApps(name: "YouTube Kids", imageName: "youtube_kids", url: "https://www.youtubekids.com", tvApp: .youtubeKids())
        ]
        
        self.ASApps = androidApps
        self.isLoadingApps = false
    }
    
    private func fetchSamsungApps() {
        let samsungApps = [
            AndroidSamsungTVApps(name: "Netflix", imageName: "netflix", url: "", tvApp: .netflix()),
            AndroidSamsungTVApps(name: "Prime Video", imageName: "prime_video", url: "", tvApp: .primeVideo()),
            AndroidSamsungTVApps(name: "YouTube", imageName: "youtube", url: "", tvApp: .youtube()),
            AndroidSamsungTVApps(name: "Disney+", imageName: "disney_plus", url: "", tvApp: .disnep()),
            AndroidSamsungTVApps(name: "Tubi", imageName: "tubi", url: "", tvApp: .tubi()),
            AndroidSamsungTVApps(name: "Peacock", imageName: "peacock", url: "", tvApp: .peacock()),
            AndroidSamsungTVApps(name: "Pluto TV", imageName: "pluto", url: "", tvApp: .plutoTV()),
            AndroidSamsungTVApps(name: "Spotify", imageName: "spotify", url: "", tvApp: .spotify()),
            AndroidSamsungTVApps(name: "YouTube Kids", imageName: "youtube_kids", url: "", tvApp: .youtubeKids())
        ]
        
        self.ASApps = samsungApps
        self.isLoadingApps = false
    }
    
    private func fetchFireTVApps() {
        isLoadingApps = true
        
        guard let FireRemoteManager = tvRemoteViewModel.currentTVManager as? FireRemoteManager else {
            isLoadingApps = false
            appFetchError = "Fire TV manager not available"
            return
        }
        
        let fireApps = FireRemoteManager.availableApps.map { app in
            RokuFireTVApps(
                appID: app.identifier, name: app.title, imageName: app.iconURL
            )
        }
        
        self.RFApps = fireApps
        self.isLoadingApps = false
    }
    
    private func fetchRokuApps() {
        isLoadingApps = true
        
        guard let RokuRemoteManager = tvRemoteViewModel.currentTVManager as? RokuRemoteManager else {
            isLoadingApps = false
            appFetchError = "Roku TV manager not available"
            return
        }
        
        let rokuApps = RokuRemoteManager.availableApps.map { appId in
            RokuFireTVApps(
                appID: appId,
                name: appId,
                imageName: RokuRemoteManager.getAppImageUrl(id: appId)
            )
        }
        
        self.RFApps = rokuApps
        self.isLoadingApps = false
    }
    
    private func fetchLGApps() {
        let lgApps = [
            LGApps(name: "Netflix", imageName: "netflix", url: "netflix"),
            LGApps(name: "Prime Video", imageName: "prime_video", url: "amazon"),
            LGApps(name: "YouTube", imageName: "youtube", url: "youtube.leanback.v4"),
            LGApps(name: "Spotify", imageName: "spotify", url: "spotify-beehive")
        ]
        
        self.LgApps = lgApps
        self.isLoadingApps = false
    }
    
    // MARK: - App Launch with Error Handling
    func launchApp(_ app: Any) {
        guard let tvType = tvRemoteViewModel.connectedTVType else {
            print("No TV connected")
            return
        }
        
        guard let manager = tvRemoteViewModel.currentTVManager else {
            print("No TV manager available")
            return
        }
        
        var success = false
        
        switch tvType {
        case .ANDROID:
            if let androidManager = manager as? AndroidRemoteManager,
               let androidApp = app as? AndroidSamsungTVApps {
                androidManager.launchChannel(with: androidApp.url)
                success = true
            }
            
        case .ROKU:
            if let rokuManager = manager as? RokuRemoteManager,
               let rokuApp = app as? RokuFireTVApps {
                rokuManager.launchApp(rokuApp.appID)
                success = true
            }
            
        case .LG:
            if let lgManager = manager as? LGRemoteManager,
               let lgApp = app as? LGApps {
                lgManager.LaunchApp(url: lgApp.url)
                success = true
            }
            
        case .FIRE:
            if let fireManager = manager as? FireRemoteManager,
               let fireApp = app as? RokuFireTVApps {
                fireManager.launchApplication(appId: fireApp.appID) { response in
                    print(response)
                }
                success = true
            }
            
        case .SAMSUNG:
            if let samsungManager = manager as? SamsungRemoteManager,
               let samsungApp = app as? AndroidSamsungTVApps {
                samsungManager.UserTappedLaunchApp(tvapp: samsungApp.tvApp)
                success = true
            }
        case .AIRPLAY:
            break
        case .NONETV:
            break
        }
        
        if success {
            AppUtils.instance.hapticFeedback()
        } else {
            print("Failed to launch app: Type mismatch")
        }
    }
}
