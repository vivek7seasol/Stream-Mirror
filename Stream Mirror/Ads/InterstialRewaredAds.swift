//
//  InterstialRewaredAds.swift
//  AdDemo
//
//  Created by Arpit on 17/10/25.
//

import Foundation
import GoogleMobileAds

import SwiftUI
import GoogleMobileAds

//final class InterstitialRewardAdManager: NSObject, FullScreenContentDelegate {
////    @Published var coins = 0
//    private var rewardedInterstitialAd: RewardedInterstitialAd?
//    static var shared = InterstitialRewardAdManager()
//    
//    func loadAd() async {
//        do {
//            rewardedInterstitialAd = try await RewardedInterstitialAd.load(
//                with: "ca-app-pub-3940256099942544/6978759866",
//                request: Request()
//            )
//            rewardedInterstitialAd?.fullScreenContentDelegate = self
//        } catch {
//            print("Failed to load rewarded interstitial ad with error: \(error.localizedDescription)")
//        }
//    }
//
//    func showAd(completion: @escaping () -> () = {}) {
//      guard let rewardedInterstitialAd = rewardedInterstitialAd else {
//        return print("Ad wasn't ready.")
//      }
//
//      rewardedInterstitialAd.present(from: nil) {
//        let reward = rewardedInterstitialAd.adReward
//        print("Reward amount: \(reward.amount)")
//          completion()
////        self.addCoins(reward.amount.intValue)
//      }
//    }
//    
//    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
////        print(#function)
//        print("Ad Impression")
//    }
//
//    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
////        print(#function)
//        print("Ad Record Click")
//    }
//
//    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
////        print(#function)
//        print("addddddddddd")
//    }
//
//    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
////        print(#function)
//        print("Will Present Ad")
//    }
//
//    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
////        print(#function)
//        print("Will dismiss Ad")
//    }
//
//    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
////        print(#function)
//        print("Dismiss Ad")
//        rewardedInterstitialAd = nil
//    }
//}

final class InterstitialRewardAdManager: NSObject, FullScreenContentDelegate {
    //    @Published var coins = 0
    private var rewardedInterstitialAd: RewardedInterstitialAd?
    static var shared = InterstitialRewardAdManager()
    private var completionHandler: (() -> ())? // Added property to store completion
    
    func loadAd() async {
        do {
            rewardedInterstitialAd = try await RewardedInterstitialAd.load(
                with: "ca-app-pub-3940256099942544/6978759866",
                request: Request()
            )
            rewardedInterstitialAd?.fullScreenContentDelegate = self
        } catch {
            print("Failed to load rewarded interstitial ad with error: \(error.localizedDescription)")
        }
    }

    func showAd(completion: @escaping () -> () = {}) {
        guard let rewardedInterstitialAd = rewardedInterstitialAd else {
            return print("Ad wasn't ready.")
        }
        
        
        
        rewardedInterstitialAd.present(from: nil) {
            let reward = rewardedInterstitialAd.adReward
            self.completionHandler = completion
            print("Reward amount: \(reward.amount)")
            // Removed completion() from here
            // self.addCoins(reward.amount.intValue)
        }
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("Ad Impression")
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("Ad Record Click")
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("addddddddddd")
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Will Present Ad")
    }

    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Will dismiss Ad")
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Dismiss Ad")
        rewardedInterstitialAd = nil
        completionHandler?() // Call the completion handler here
        completionHandler = nil // Clear the completion handler
    }
}


import GoogleMobileAds

//final class InterstitialRewardAdManager: NSObject, GADFullScreenContentDelegate {
//    private var rewardedInterstitialAd: GADRewardedInterstitialAd?
//    static let shared = InterstitialRewardAdManager()
//    
//    func loadAd() async {
//        do {
//            rewardedInterstitialAd = try await GADRewardedInterstitialAd.load(
//                withAdUnitID: "ca-app-pub-3940256099942544/6978759866",
//                request: GADRequest()
//            )
//            rewardedInterstitialAd?.fullScreenContentDelegate = self
//        } catch {
//            print("Failed to load rewarded interstitial ad with error: \(error.localizedDescription)")
//        }
//    }
//
//    func showAd(completion: @escaping () -> Void = {}) {
//        guard let rewardedInterstitialAd = rewardedInterstitialAd else {
//            print("Ad wasn't ready.")
//            return
//        }
//
//        // Find the root view controller to present the ad
//        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
//            print("No root view controller available to present ad.")
//            return
//        }
//
//        rewardedInterstitialAd.present(fromRootViewController: rootViewController) {
//            let reward = rewardedInterstitialAd.adReward
//            print("Reward earned: \(reward.amount)")
//            completion() // Call completion only when the reward is earned
//        }
//    }
//    
//    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
//        print(#function)
//    }
//
//    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
//        print(#function)
//    }
//
//    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
//        print("Failed to present ad: \(error.localizedDescription)")
//        rewardedInterstitialAd = nil
//    }
//
//    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
//        print(#function)
//    }
//
//    func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
//        print(#function)
//    }
//
//    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
//        print(#function)
//        rewardedInterstitialAd = nil
//    }
//}
