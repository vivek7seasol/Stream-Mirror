//
//  NativeAd.swift
//  Screen Mirroring Casting
//
//  Created by Ronik Hirpara on 17/10/25.
//

import Foundation
import SwiftUI
import GoogleMobileAds
import UIKit
import Combine

final class NativeAdViewModel: NSObject, ObservableObject {
    @Published var nativeAd: NativeAd?
    @Published var smallNativeAd: NativeAd?
    @Published var secondNativeAd: NativeAd?
    @Published var didFailToLoad: Bool = false
    @Published var didFailToSmallLoad: Bool = false
    @Published var didFailToSecondLoad: Bool = false

    private var adLoader: AdLoader?
    private var smallAdLoader: AdLoader?
    private var secondAdLoader: AdLoader?

    func refreshAd() {
        didFailToLoad = false
        nativeAd = nil

        guard !nativeId.isEmpty else {
            print("⚠️ Missing Native Ad Unit ID")
            didFailToLoad = true
            return
        }

        let request = Request()
        adLoader = AdLoader(adUnitID: nativeId,
                            rootViewController: nil,
                            adTypes: [.native],
                            options: nil)
        adLoader?.delegate = self
        adLoader?.load(request)
    }
    
    func refreshSecondNative() {
        didFailToSecondLoad = false
        secondNativeAd = nil

        guard !second_native.isEmpty else {
            print("⚠️ Missing Native Ad Unit ID")
            didFailToSecondLoad = true
            return
        }

        let request = Request()
        secondAdLoader = AdLoader(adUnitID: second_native,
                            rootViewController: nil,
                            adTypes: [.native],
                            options: nil)
        secondAdLoader?.delegate = self
        secondAdLoader?.load(request)
    }
    
    func refreshSmallNative() {
        didFailToSmallLoad = false
        smallNativeAd = nil

        guard !small_native.isEmpty else {
            print("⚠️ Missing Native Ad Unit ID")
            didFailToSmallLoad = true
            return
        }

        let request = Request()
        smallAdLoader = AdLoader(adUnitID: second_small_native,
                            rootViewController: nil,
                            adTypes: [.native],
                            options: nil)
        smallAdLoader?.delegate = self
        smallAdLoader?.load(request)
    }
}

// MARK: - Delegates
extension NativeAdViewModel: NativeAdLoaderDelegate, NativeAdDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DispatchQueue.main.async {
            if adLoader == self.smallAdLoader {
                self.smallNativeAd = nativeAd
                self.didFailToSmallLoad = false
                nativeAd.delegate = self
                print("Small Native ad loaded successfully.")
            }else if adLoader == self.secondAdLoader {
                self.secondNativeAd = nativeAd
                self.didFailToSecondLoad = false
                nativeAd.delegate = self
                print("second Native ad loaded successfully.")
            } else {
                self.nativeAd = nativeAd
                self.didFailToLoad = false
                nativeAd.delegate = self
                print("Native ad loaded successfully.")
            }
        }
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            
            if adLoader == self.smallAdLoader {
                self.didFailToSmallLoad = true
                print("❌ Small Native ad failed: \(error.localizedDescription)")
            } else if adLoader == self.secondAdLoader {
                self.didFailToSecondLoad = true
                print("❌ Second Native ad failed: \(error.localizedDescription)")
            } else {
                self.didFailToLoad = true
                print("❌ Native ad failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - NativeAdDelegate
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) { print("🖱️ Click recorded") }
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) { print("👀 Impression recorded") }
    func nativeAdWillPresentScreen(_ nativeAd: NativeAd) { print("📱 Will present screen") }
    func nativeAdWillDismissScreen(_ nativeAd: NativeAd) { print("📴 Will dismiss screen") }
    func nativeAdDidDismissScreen(_ nativeAd: NativeAd) { print("✅ Screen dismissed") }
}

//class NativeAdViewModel: NSObject, ObservableObject, NativeAdLoaderDelegate {
//    @Published var nativeAd: NativeAd?
//    private var adLoader: AdLoader!
//    
//    func refreshAd() {
//        adLoader = AdLoader(
//            adUnitID: SessionManager.shared.getSplashData()?.nativeID ?? "",
//            rootViewController: nil,
//            adTypes: [.native], options: nil)
//        adLoader.delegate = self
//        adLoader.load(Request())
//    }
//    
//    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
//        self.nativeAd = nativeAd
//        nativeAd.delegate = self
//    }
//    
//    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
//        print("\(adLoader) failed with error: \(error.localizedDescription)")
//    }
//}
//
//extension NativeAdViewModel: NativeAdDelegate {
//  func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
//    print("\(#function) called")
//  }
//
//  func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
//    print("\(#function) called")
//  }
//
//  func nativeAdWillPresentScreen(_ nativeAd: NativeAd) {
//    print("\(#function) called")
//  }
//
//  func nativeAdWillDismissScreen(_ nativeAd: NativeAd) {
//    print("\(#function) called")
//  }
//
//  func nativeAdDidDismissScreen(_ nativeAd: NativeAd) {
//    print("\(#function) called")
//  }
//}



