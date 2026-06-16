//
//  SplashViewModel.swift
//  SmartRemote
//
//  Created by Sumit zalavadiya on 10/03/26.
//

import Foundation
import Combine
import AWSCore
import UIKit
import SwiftUI

class SplashViewModel: ObservableObject {
    
    @Published var navigateToLanguage = false
    @Published var navigateToHome = false
    @Published var navigateToIntro1 = false
    
    @AppStorage(SessionKeys.language) var language = false
    @AppStorage(SessionKeys.intro3) var intro3 = false
    
    
    func requestTrackingPermission() {
        
        let credentials = AWSStaticCredentialsProvider(accessKey: ACCESS, secretKey: SECRET)
        let configuration = AWSServiceConfiguration(region: .EUWest1, credentialsProvider: credentials)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        AdsManager.shared.requestForConsentForm { _ in
            DispatchQueue.main.async {
                self.handleStartupFlow()
            }
        }
    }
    
    private func handleStartupFlow() {
        
        fetchSplashData {
            DispatchQueue.main.async { [self] in
                navigateAfterSplash()
            }
        }
    }
    
    private func navigateAfterSplash() {
        
        if language {
            if intro3 {
                navigateToHome = true
            } else {
                navigateToIntro1 = true
            }
        } else {
            navigateToLanguage = true
        }
    }
    
    func fetchSplashData(completion: (() -> Void)? = nil) {

        guard let url = URL(string: getJSON) else {
            print("❌ Invalid URL")
            completion?()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil

        let session = URLSession(configuration: configuration)

        let task = session.dataTask(with: request) { data, response, error in

            if let error = error {

                print("❌ API Error:", error.localizedDescription)

                DispatchQueue.main.async {
                    completion?()
                }

                return
            }

            guard let data = data else {

                print("❌ No Data Found")

                DispatchQueue.main.async {
                    completion?()
                }

                return
            }

            do {

                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    appopenId = json["appopenId"] as? String ?? ""
                    bannerId = json["bannerId"] as? String ?? ""
                    nativeId = json["nativeId"] as? String ?? ""
                    interstialId = json["interstialId"] as? String ?? ""
                    rewardId = json["rewardId"] as? String ?? ""
                    addButtonColor = json["addButtonColor"] as? String ?? ""
                    
                    if let extraFields = json["extraFields"] as? [String: Any] {
//                        NewsAPI = extraFields["story"] as? String ?? ""
                        
                    } else {

                        print("❌ extraFields not found")
                    }

                    let customInterstial = json["customInterstial"] as? Int ?? 0

                    if let countString = json["afterClick"] as? String,
                       let count = Int(countString) {

                        adsCount = count

                    } else {

                        adsCount = 4
                    }

//                    DispatchQueue.main.async {
//
//                        AdCountViewModel.sharedd.afterClick = adsCount
//                    }

                    adsPlus = customInterstial == 0
                    ? adsCount - 1
                    : adsCount

                }

                DispatchQueue.main.async {
                    completion?()
                }

            } catch {

                print("❌ JSON Parse Error:", error.localizedDescription)

                DispatchQueue.main.async {
                    completion?()
                }
            }
        }

        task.resume()
    }
}
