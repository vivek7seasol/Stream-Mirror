//
//  AppOpenAd.swift
//  Screen Mirroring Casting
//
//  Created by Ronik Hirpara on 28/10/25.
//

//import SwiftUI
//import GoogleMobileAds
//import UIKit
//import Foundation
//
final class AdState {
    static let shared = AdState()
    
    var isShowingInterstitial = false
}
//
//class AppOpenAdManager: NSObject, FullScreenContentDelegate {
//    var appOpenAd: AppOpenAd?
//    var isLoadingAd = false
//    var isShowingAd = false
//    var loadTime: Date?
//    var hasLoadedOnce = false
//    static let shared = AppOpenAdManager()
//
//    // Keep a reference to the completion closure
//    private var adCompletion: (() -> Void)?
//
//    // MARK: - Load Ad
//    func loadAd() async {
//        if isLoadingAd {
//            print("⏳ Ad is already loading.")
//            return
//        }
//        if hasLoadedOnce {
//            print("✅ App open ad already loaded this session — skipping.")
//            return
//        }
//
//        isLoadingAd = true
//        do {
//            print("🚀 Loading App Open Ad...")
//            appOpenAd = try await AppOpenAd.load(
//                with: appopenId,
//                request: Request()
//            )
//            appOpenAd?.fullScreenContentDelegate = self
//            loadTime = Date()
//            hasLoadedOnce = true
//            print("✅ App Open Ad successfully loaded.")
//        } catch {
//            print("❌ Failed to load App Open Ad: \(error.localizedDescription)")
//            appOpenAd = nil
//            loadTime = nil
//        }
//        isLoadingAd = false
//    }
//
//    // MARK: - Show Ad with Completion
//    func showAdIfAvailable(completion: @escaping () -> Void) {
//        
//        if AdState.shared.isShowingInterstitial {
//                print("⛔ Skipping AppOpenAd because interstitial is showing")
//                completion()
//                return
//            }
//        
//        if isShowingAd {
//            print("⚠️ App open ad is already showing.")
//            completion()
//            return
//        }
//        guard let ad = appOpenAd else {
//            print("⚠️ App open ad not available.")
//            completion()
//            return
//        }
//        if let topVC = UIApplication.topViewController {
//            print("🎬 Presenting App Open Ad...")
//            ad.present(from: topVC)
//            isShowingAd = true
//            adCompletion = completion
//        } else {
//            completion()
//        }
//    }
//
//    // MARK: - Ad Delegate Callbacks
//    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("ℹ️ Ad will present full screen content.")
//    }
//
//    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
//        print("ℹ️ App open ad impression recorded.")
//    }
//
//    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
//        print("ℹ️ App open ad clicked.")
//    }
//
//    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("ℹ️ App open ad will dismiss.")
//    }
//
//    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("✅ App open ad dismissed.")
//        finishAdFlow()
//    }
//
//    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
//        print("❌ Ad failed to present: \(error.localizedDescription)")
//        finishAdFlow()
//    }
//
//    private func finishAdFlow() {
//        isShowingAd = false
//        appOpenAd = nil
//        hasLoadedOnce = true
//        adCompletion?()
//        adCompletion = nil
//    }
//
//    // MARK: - Reset for new session
//    func resetForForeground() {
//        print("🔄 Resetting AppOpenAdManager for foreground session.")
//        hasLoadedOnce = false
//        appOpenAd = nil
////        isShowingAd = false
//        loadTime = nil
//    }
//}
//
//
//class AppOpenBackAdManager: NSObject, FullScreenContentDelegate {
//    var appOpenAd: AppOpenAd?
//    weak var appOpenAdManagerDelegate: AppOpenAdManagerDelegate?
//    var isLoadingAd = false
//    var isShowingAd = false
//    var loadTime: Date?
//    var hasLoadedOnce = false
//
//    static let shared = AppOpenBackAdManager()
//
//    protocol AppOpenAdManagerDelegate: AnyObject {
//        func appOpenAdManagerAdDidComplete(_ appOpenAdManager: AppOpenBackAdManager)
//    }
//
//    // MARK: - Load Ad
//    func loadAd() async {
//        if isLoadingAd {
//            print("⏳ Ad is already loading.")
//            return
//        }
//        if hasLoadedOnce {
//            print("✅ App open ad already loaded this session — skipping.")
//            return
//        }
//
//        isLoadingAd = true
//        do {
//            print("🚀 Loading App Open Ad...")
//            appOpenAd = try await AppOpenAd.load(
//                with: appopenId,
//                request: Request()
//            )
//            appOpenAd?.fullScreenContentDelegate = self
//            loadTime = Date()
//            hasLoadedOnce = true
//            print("✅ App Open Ad successfully loaded.")
//        } catch {
//            print("❌ Failed to load App Open Ad: \(error.localizedDescription)")
//            appOpenAd = nil
//            loadTime = nil
//        }
//        isLoadingAd = false
//    }
//
//    // MARK: - Show Ad
//    func showAdIfAvailable() {
//        if isShowingAd {
//            print("⚠️ App open ad is already showing.")
//            return
//        }
//        guard let ad = appOpenAd else {
//            print("⚠️ App open ad not available.")
//            appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
//            return
//        }
//        if let topVC = UIApplication.topViewController {
//            print("🎬 Presenting App Open Ad...")
//            ad.present(from: topVC)
//            isShowingAd = true
//        }
//    }
//
//    // MARK: - Ad Delegate Callbacks
//    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("ℹ️ Ad will present full screen content.")
//    }
//
//    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
//        print("ℹ️ App open ad impression recorded.")
//    }
//
//    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
//        print("ℹ️ App open ad clicked.")
//    }
//
//    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("ℹ️ App open ad will dismiss.")
//    }
//
//    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
//        print("✅ App open ad dismissed.")
//        isShowingAd = false
//        appOpenAd = nil
//        appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
//    }
//
//    func ad(_ ad: FullScreenPresentingAd,
//            didFailToPresentFullScreenContentWithError error: Error) {
//        print("❌ Ad failed to present: \(error.localizedDescription)")
//        isShowingAd = false
//        appOpenAd = nil
//        appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
//    }
//
//    // MARK: - Reset for new session
//    func resetForForeground() {
//        print("🔄 Resetting AppOpenAdManager for foreground session.")
//        hasLoadedOnce = false
//        appOpenAd = nil
////        isShowingAd = false
//        loadTime = nil
//    }
//}
//
//// MARK: - Top View Controller helper
//extension UIApplication {
//    static var topViewController: UIViewController? {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
//            return nil
//        }
//        var top = root
//        while let presented = top.presentedViewController {
//            top = presented
//        }
//        return top
//    }
//}

import SwiftUI
import GoogleMobileAds
import UIKit
import Foundation

class AppOpenAdManager: NSObject, FullScreenContentDelegate {
    var appOpenAd: AppOpenAd?
    var isLoadingAd = false
    var isShowingAd = false
    var loadTime: Date?
    var hasLoadedOnce = false
    static let shared = AppOpenAdManager()
    
    private var adCompletion: (() -> Void)?
    
    // MARK: - Load Ad
    func loadAd() async {
        if isLoadingAd {
            print("⏳ Ad is already loading.")
            return
        }
        if hasLoadedOnce {
            print("✅ App open ad already loaded this session — skipping.")
            return
        }
        
        isLoadingAd = true
        do {
            print("🚀 Loading App Open Ad...")
            appOpenAd = try await AppOpenAd.load(
                with: second_appopen,
                request: Request()
            )
            appOpenAd?.fullScreenContentDelegate = self
            loadTime = Date()
            hasLoadedOnce = true
            print("✅ App Open Ad successfully loaded.")
        } catch {
            print("❌ Failed to load App Open Ad: \(error.localizedDescription)")
            appOpenAd = nil
            loadTime = nil
        }
        isLoadingAd = false
    }
    
    // MARK: - Show Ad with Completion
    func showAdIfAvailable(completion: @escaping () -> Void) {
        if isShowingAd {
            print("⚠️ App open ad is already showing.")
            completion()
            return
        }
        guard let ad = appOpenAd else {
            print("⚠️ App open ad not available.")
            completion()
            return
        }
        if let topVC = UIApplication.topViewController {
            print("🎬 Presenting App Open Ad...")
            ad.present(from: topVC)
            isShowingAd = true
            adCompletion = completion
        } else {
            completion()
        }
    }
    
    // MARK: - Ad Delegate Callbacks
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("ℹ️ Ad will present full screen content.")
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("ℹ️ App open ad impression recorded.")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("ℹ️ App open ad clicked.")
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("ℹ️ App open ad will dismiss.")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("✅ App open ad dismissed.")
        finishAdFlow()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad failed to present: \(error.localizedDescription)")
        finishAdFlow()
    }
    
    private func finishAdFlow() {
        isShowingAd = false
        appOpenAd = nil
        hasLoadedOnce = true
        adCompletion?()
        adCompletion = nil
    }
    
    // MARK: - Reset for new session
    func resetForForeground() {
        print("🔄 Resetting AppOpenAdManager for foreground session.")
        hasLoadedOnce = false
        appOpenAd = nil
        isShowingAd = false
        loadTime = nil
    }
}


class AppOpenBackAdManager: NSObject, FullScreenContentDelegate {
    var appOpenAd: AppOpenAd?
    weak var appOpenAdManagerDelegate: AppOpenAdManagerDelegate?
    var isLoadingAd = false
    var isShowingAd = false
    var loadTime: Date?
    var hasLoadedOnce = false
    
    static let shared = AppOpenBackAdManager()
    
    protocol AppOpenAdManagerDelegate: AnyObject {
        func appOpenAdManagerAdDidComplete(_ appOpenAdManager: AppOpenBackAdManager)
    }
    
    // MARK: - Load Ad
    func loadAd() async {
        if isLoadingAd {
            print("⏳ Ad is already loading.")
            return
        }
        if hasLoadedOnce {
            print("✅ App open ad already loaded this session — skipping.")
            return
        }
        
        isLoadingAd = true
        do {
            print("🚀 Loading App Open Ad...")
            appOpenAd = try await AppOpenAd.load(
                with: appopenId,
                request: Request()
            )
            appOpenAd?.fullScreenContentDelegate = self
            loadTime = Date()
            hasLoadedOnce = true
            print("✅ App Open Ad successfully loaded.")
        } catch {
            print("❌ Failed to load App Open Ad: \(error.localizedDescription)")
            appOpenAd = nil
            loadTime = nil
        }
        isLoadingAd = false
    }
    
    // MARK: - Show Ad
    func showAdIfAvailable() {
        if isShowingAd {
            print("⚠️ App open ad is already showing.")
            return
        }
        guard let ad = appOpenAd else {
            print("⚠️ App open ad not available.")
            appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
            return
        }
        if let topVC = UIApplication.topViewController {
            print("🎬 Presenting App Open Ad...")
            ad.present(from: topVC)
            isShowingAd = true
        }
    }
    
    // MARK: - Ad Delegate Callbacks
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("ℹ️ Ad will present full screen content.")
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("ℹ️ App open ad impression recorded.")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("ℹ️ App open ad clicked.")
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("ℹ️ App open ad will dismiss.")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("✅ App open ad dismissed.")
        isShowingAd = false
        appOpenAd = nil
        appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
    }
    
    func ad(_ ad: FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad failed to present: \(error.localizedDescription)")
        isShowingAd = false
        appOpenAd = nil
        appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
    }
    
    // MARK: - Reset for new session
    func resetForForeground() {
        print("🔄 Resetting AppOpenAdManager for foreground session.")
        hasLoadedOnce = false
        appOpenAd = nil
        isShowingAd = false
        loadTime = nil
    }
}

// MARK: - Top View Controller helper
extension UIApplication {
    static var topViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
