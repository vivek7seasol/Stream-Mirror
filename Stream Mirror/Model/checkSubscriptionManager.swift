////
////  SubscriptionManager.swift
////  Screen Mirroring Casting
////
////  Created by Ronik Hirpara on 27/10/25.
////
//
//import Foundation
//import SwiftUI
//import StoreKit
//import Combine
//
//
//@MainActor
//class checkSubscriptionManager: ObservableObject {
//    
//    @AppStorage(SessionKeys.isPro) var isPro = false
//    static let shared = checkSubscriptionManager()
//    
//    @Published var isActive: Bool = false
//    @Published var activeProductID: String?
//    @Published var expirationDate: Date?
//    
//    private init() {}
//    
//    func checkSubscriptionAtLaunch() async {
//            await refreshSubscriptionStatus()
//            
//            let defaults = UserDefaults.standard
//            
//            if let expiry = expirationDate {
//                if expiry < Date() {
//                    print("⚠️ Subscription expired on \(expiry). Setting isPro = false")
//                    isPro = false
//                } else {
//                    print("✅ Active subscription valid until \(expiry)")
//                    isPro = true
//                }
//            } else if !isActive {
//                print("❌ No active subscription found. Setting isPro = false")
//                isPro = false
//            } else {
//                isPro = true
//            }
//            
//            // 🔄 Force synchronization for SwiftUI @AppStorage observers
//            defaults.synchronize()
//        }
//    
//    
//    // MARK: - Refresh Current Subscription Info
//    func refreshSubscriptionStatus() async {
//        do {
//            var foundActive = false
//            var latestExpirationDate: Date? = nil
//            var foundProductID: String? = nil
//
//            if #available(iOS 18.4, *) {
//                // Use the modern API for iOS 18.4+
//                for productID in Products.allCases.map({ $0.rawValue }) {
//                    for await result in StoreKit.Transaction.currentEntitlements(for: productID) {
//                        switch result {
//                        case .verified(let entitlement):
//                            foundActive = true
//                            if let expDate = entitlement.expirationDate {
//                                if latestExpirationDate == nil || expDate > latestExpirationDate! {
//                                    latestExpirationDate = expDate
//                                    foundProductID = productID
//                                }
//                            } else {
//                                latestExpirationDate = nil
//                                foundProductID = productID
//                            }
//                        case .unverified:
//                            continue
//                        }
//                    }
//                }
//            } else {
//                // For iOS 15–18.3, use Transaction.currentEntitlements (no for: argument)
//                for await result in StoreKit.Transaction.currentEntitlements {
//                    switch result {
//                    case .verified(let entitlement):
//                        let productID = entitlement.productID
//                        if Products.allCases.map({ $0.rawValue }).contains(productID) {
//                            foundActive = true
//                            if let expDate = entitlement.expirationDate {
//                                if latestExpirationDate == nil || expDate > latestExpirationDate! {
//                                    latestExpirationDate = expDate
//                                    foundProductID = productID
//                                }
//                            } else {
//                                latestExpirationDate = nil
//                                foundProductID = productID
//                            }
//                        }
//                    case .unverified:
//                        continue
//                    }
//                }
//            }
//
//            isActive = foundActive
//            activeProductID = foundProductID
//            expirationDate = latestExpirationDate
//            isPro = foundActive
////            UserDefaults.standard.set(foundActive, forKey: SessionKeys.isPro)
//        } catch {
//            print("⚠️ Failed to load subscription info: \(error.localizedDescription)")
//        }
//    }
//}
//
