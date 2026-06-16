//
//  InterstialAdManager.swift
//  Screen Mirroring Casting
//
//  Created by Ronik Hirpara on 17/10/25.
//

import Foundation
import GoogleMobileAds
import SwiftUI

final class InterstitialAdManager: NSObject, FullScreenContentDelegate {
//    @AppStorage(SessionKeys.interAdId) var interAdId = ""
    // MARK: - Published Properties
//    @Published var adUnitID: String = ""

    // MARK: - Private Properties
    private var interstitial: InterstitialAd?
    private var isLoadings: Bool = false

    // MARK: - Initialization
    override init() {
//        interAdId = interstialId
        super.init()
    }
    func update(){
//        interAdId = interstialId
        load()
    }

    func load() {
        guard !isLoadings else {
            print("⚙️ [AdManager] Already loading an interstitial, skipping duplicate request.")
            return
        }

        isLoadings = true

        let request = Request()
        print("📡 [AdManager] Loading interstitial ad for unit ID: \(interstialId)")

        InterstitialAd.load(with: interstialId, request: request) {  ad, error in
            self.isLoadings = false

            if let error {
                print("❌ [AdManager] Failed to load interstitial: \(error.localizedDescription)")
                return
            }

            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
            print("✅ [AdManager] Interstitial loaded successfully for ID: \(interstialId)")
        }
    }

    /// Presents the interstitial ad if available; otherwise reloads.
    func present() {
        guard let root = UIApplication.shared.firstKeyWindowRootViewController() else {
            print("⚠️ [AdManager] No rootViewController found for presentation.")
            return
        }

        guard let interstitial else {
            print("⚠️ [AdManager] Ad not ready, attempting reload.")
            load()
            return
        }
        AdState.shared.isShowingInterstitial = true
        print("🎬 [AdManager] Presenting interstitial ad.")
        interstitial.present(from: root)
    }


    // MARK: - GADFullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("ℹ️ [AdManager] Interstitial dismissed. Preparing next ad.")
        AdState.shared.isShowingInterstitial = false
        interstitial = nil
        load()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ [AdManager] Failed to present interstitial: \(error.localizedDescription)")
        AdState.shared.isShowingInterstitial = false
        interstitial = nil
        load()
    }

    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("👁️ [AdManager] Interstitial impression recorded.")
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("🖱️ [AdManager] Interstitial clicked.")
    }
}

// Helper to locate a root view controller for presentation in multi-scene apps.
private extension UIApplication {
    func firstKeyWindowRootViewController() -> UIViewController? {
        connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow } // Iterate active scenes and find the key window
            .first?
            .rootViewController
    }
}

// Convenience to fetch the key window for a scene
private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first(where: { $0.isKeyWindow }) }
}

