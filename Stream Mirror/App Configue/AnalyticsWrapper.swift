//
//  AnalyticsWrapper.swift
//  CineBuzz
//
//  Created by Parthiv Akbari on 23/07/25.
//

import Foundation
import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics

enum AnalyticEvent: String {
    
    case Home
    case Settings
    case Language
    case Privacy
    case AboutUs
    case Terms
    case Eula
    case Premium
    case ScreenMirror
    case remote
    case browser
    case youtubeCasting
    case youtubePreview
    case IPTVCatCountry
    case IPTVChannel
    case PhotoListing
    case PhotoCasting
    case VideoListing
    case VideoCasting
    case MusicListing
    case MusicCasting
    case Files
    case FilesListing
    case FilesListingPreview
    case Record
    case saveRecording
    case DrawingListing
    case drawing
    case FindImageListing
    case Camera
    
}

//func logAnalyticView(title: String, Screen: String) {
//    Analytics.logEvent(AnalyticsEventScreenView, parameters: [AnalyticsParameterScreenName: title, AnalyticsParameterScreenClass: Screen])
//}
//
//func logAnalyticAction(title: String, status: AnalyticEvent) {
//    Analytics.logEvent(status.rawValue, parameters: ["name": title, "status": status])
//}
//
//func logAnalyticActionWithParams(_ name: AnalyticEvent, parameters: [String : Any]?)
//{
//    Analytics.logEvent(name.rawValue, parameters: parameters)
//}

// MARK: - Screen View
func logAnalyticView(title: String, screen: String) {
    Analytics.logEvent(AnalyticsEventScreenView, parameters: [
        AnalyticsParameterScreenName: title,
        AnalyticsParameterScreenClass: screen
    ])
    
    // 🔥 Crashlytics breadcrumb
    Crashlytics.crashlytics().log("Screen: \(title) (\(screen))")
    
    // Optional: track current screen
    Crashlytics.crashlytics().setCustomValue(title, forKey: "current_screen")
}

// MARK: - Simple Action
func logAnalyticAction(title: String, status: AnalyticEvent) {
    Analytics.logEvent(status.rawValue, parameters: [
        "name": title,
        "status": status.rawValue
    ])
    
    // 🔥 Crashlytics breadcrumb
    Crashlytics.crashlytics().log("Event: \(status.rawValue), Title: \(title)")
}

// MARK: - Action With Params
func logAnalyticActionWithParams(_ name: AnalyticEvent, parameters: [String: Any]?) {
    
    Analytics.logEvent(name.rawValue, parameters: parameters)
    
    // 🔥 Crashlytics breadcrumb
    if let params = parameters {
        Crashlytics.crashlytics().log("Event: \(name.rawValue), Params: \(params)")
    } else {
        Crashlytics.crashlytics().log("Event: \(name.rawValue), Params: nil")
    }
}
