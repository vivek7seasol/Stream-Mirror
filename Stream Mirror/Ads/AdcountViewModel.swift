//
//  AdcountViewModel.swift
//  Screen Mirroring Casting
//
//  Created by Ronik Hirpara on 18/10/25.
//

import Foundation
import SwiftUI
import Combine
import GoogleMobileAds

//final class AdCountViewModel: BaseVM {
//    @AppStorage(SessionKeys.isPro) var isPro = false
//    @Published var tapCount: Int = 0
//    @AppStorage(SessionKeys.afterClick) var afterClick = 0
//    let interstitialManager = InterstitialAdManager()
////    let threshold = Int(SessionManager.shared.getSplashData()?.afterClick ?? "1") ?? 1
//    var cancellables = Set<AnyCancellable>()
//    static var sharedd = AdCountViewModel()
//    
//    
//    func registerTap() {
//        tapCount += 1
//        print("🔹 Total Tap Count: \(tapCount)")
//        if tapCount == afterClick {
//            if !isPro {
//                showInterstitial()
//            }
//            tapCount = 0
//        } else if tapCount > afterClick {
//            if !isPro {
//                showInterstitial()
//            }
//            tapCount = 0
//        }
//    }
//    
//    private func showInterstitial() {
//        print("🟢 Showing interstitial ad at tap count threshold")
//            self.interstitialManager.present()
//            self.reloadAd()
//    }
//    
//    func reloadAd() {
//        interstitialManager.load()
//    }
//}
//

import Foundation
import Combine
import SwiftUI

final class AdCountViewModel: NSObject {
    @AppStorage(SessionKeys.isPro) var isPro = false
    @Published var tapCount: Int = 0
    @Published var afterClick: Int = 1

    let interstitialManager = InterstitialAdManager()
    var cancellables = Set<AnyCancellable>()
    static let sharedd = AdCountViewModel()

    // MARK: - Init
    override init() {
        super.init()
        print("🚀 AdCountViewModel initialized — preloading interstitial ad...")
//        reloadAd()
        observeAfterClickChange()
    }

    // MARK: - Observe afterClick changes dynamically
    private func observeAfterClickChange() {
        NotificationCenter.default.publisher(
            for: Notification.Name(rawValue: "afterClickUpdated")
        )
            .sink { [weak self] _ in
                guard let self else { return }
                
                print("📡 Notification received")
                print("🔥 adsCount latest: \(adsCount)")
                
                self.afterClick = adsCount
                print("⚙️ Updated afterClick: \(self.afterClick)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Tap Logic
    func registerTap() {
        tapCount += 1
        print("🔹 Total Tap Count: \(tapCount)")

        guard !isPro else { return }

        if tapCount >= afterClick {
            print("🟢 Tap count reached threshold (\(afterClick)) — showing ad.")
            showInterstitial()
            tapCount = 0
        }
    }

    // MARK: - Show & Reload Ads
    private func showInterstitial() {
        interstitialManager.present()
        reloadAd()
    }

    func reloadAd() {
        print("🔄 Reloading interstitial ad...")
        interstitialManager.load()
    }
}
