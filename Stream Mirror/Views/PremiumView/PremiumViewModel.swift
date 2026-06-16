//
//  ProVM.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 12/05/26.
//

import Foundation
import SwiftUI
import StoreKit
import Combine

// MARK: - ViewModel
class PremiumViewModel: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    @AppStorage(SessionKeys.isPro) var isPro = false
    // MARK: - Published State
    @Published var products: [SKProduct] = []
    @Published var selectedProduct: SKProduct?
    @Published var isRestoring: Bool = false
    @Published var isPurchedNotFound: Bool = false
    @Published var isPurchedFailed: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    var isLoading = false
    var onPurchaseSuccess: (() -> Void)?
    var onRestoreSuccess: (() -> Void)?
    private var restoredPurchase = false
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - Fetch Products
    func fetchInAppProduct() {
        startLoading()
        let identifiers = Set(Products.allCases.map { $0.rawValue })
        let request = SKProductsRequest(productIdentifiers: identifiers)
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

        DispatchQueue.main.async {

            let sortedIDs = [
                Products.smart_view_lifeTime.rawValue,
                Products.smart_view_yearly.rawValue,
                Products.smart_view_monthly.rawValue
            ]

            let filteredProducts = response.products.filter { product in

                switch product.productIdentifier {

                case Products.smart_view_monthly.rawValue:
                    return iapMonthlyPlan == "true"

                case Products.smart_view_yearly.rawValue:
                    return iapYearlyPlan == "true"

                case Products.smart_view_lifeTime.rawValue:
                    return iapLifetime == "true"

                default:
                    return false
                }
            }

            self.products = filteredProducts.sorted { first, second in

                let firstIndex = sortedIDs.firstIndex(of: first.productIdentifier) ?? 0
                let secondIndex = sortedIDs.firstIndex(of: second.productIdentifier) ?? 0

                return firstIndex < secondIndex
            }

            self.selectedProduct = self.products.first

            self.stopLoading()
        }
    }
    
    // MARK: - Purchase
    func makePurchase() {
        guard let product = selectedProduct else {
            showAlertMsg(message: "Product not available.")
            return
        }
        guard SKPaymentQueue.canMakePayments() else {
            showAlertMsg(message: "In-App Purchases are disabled on this device.")
            return
        }
        
        startLoading()
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // MARK: - Restore Purchases
    func restore() {

        if isPro {
            showAlertMsg(message: "Premium is already active.")
            return
        }

        startLoading()
        isRestoring = true
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - Transaction Updates
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                print("Purchasing...")
                stopLoading()
                
            case .purchased:
                print("✅ Purchase completed: \(transaction.payment.productIdentifier)")
                SKPaymentQueue.default().finishTransaction(transaction)
                isPro = true
                stopLoading()
//                showAlertMsg(message: "Purchase successful!")
                onPurchaseSuccess?()
                
            case .restored:

                print("♻️ Restored: \(transaction.payment.productIdentifier)")

                isPro = true
                isRestoring = false

                SKPaymentQueue.default().finishTransaction(transaction)

                stopLoading()

                showAlertMsg(message: "Restore successful!")

                onRestoreSuccess?()
                
            case .failed:
                print("❌ Transaction failed: \(transaction.error?.localizedDescription ?? "unknown error")")
                SKPaymentQueue.default().finishTransaction(transaction)
                stopLoading()
                isPurchedFailed = true
                showAlertMsg(message: "Transaction failed. Please try again.")
                
            case .deferred:
                stopLoading()
                print("⏳ Purchase deferred")
                
            @unknown default:
                break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {

        stopLoading()
        isRestoring = false

        if restoredPurchase {

            isPro = true
            showAlertMsg(message: "Restore successful!")
            onRestoreSuccess?()

        } else {

            isPurchedNotFound = true
            showAlertMsg(message: "No previous purchase found to restore.")
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        stopLoading()
        isRestoring = false
        showAlertMsg(message: "Restore failed: \(error.localizedDescription)")
    }
    
    // MARK: - Helpers
    private func showAlertMsg(message: String) {
        DispatchQueue.main.async {
            self.alertMessage = message
            self.showAlert = true
            print("⚠️ ALERT: \(message)")
        }
    }
    func startLoading(){
        isLoading = true
    }
    
    func stopLoading(){
        isLoading = false
    }
}

// MARK: - Product Enum
enum Products: String, CaseIterable {
    case smart_view_monthly = "Month_plan"
    case smart_view_yearly = "Year_plan"
    case smart_view_lifeTime = "Life_time_plan"
}
