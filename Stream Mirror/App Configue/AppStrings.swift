//
//  AppStrings.swift
//  SmartRemote
//
//  Created by Sumit zalavadiya on 11/03/26.
//

import Foundation
import SwiftUI

struct AppStrings {
    static let appName             = "Screen Cast"
    
    static let groupID = "group.com.sumit.remote"
    static let appExtensionPackageName = "com.sumit.remote.SmartRemoteBroadcast"
    
//    static let groupID = "group.com.dhara.remote"
//    static let appExtensionPackageName = "com.dhara.remote.SmartRemoteBroadcast"
    
//    static let groupID = "group.com.remote.acces"
//    static let appExtensionPackageName = "com.remote.acces.SmartRemoteBroadcast"
    
    static let broadcastStartedNotification = "broadcastStartedNotification"
    
    static let deviceIPKey = "ConnectedDeviceIP"
    static let serverUrlKey = "serverURL"
    
    static let pexelWebKey = "EvP7eQQFXRRDKLyLVBv9M8DWrxhgYL7gc6V4FuE5xkfpGyVRgvQNwyns"
    
    static let channelNamespace = "urn:x-cast:com.big.screen.channel"
    static let kCustomReceiverAppID = "B6208013"
    
    static let rotateMirror = "rotateMirror"
   
    static func fetchBroadcastStatus() -> Bool {
        UserDefaults(suiteName: AppStrings.groupID)?.bool(forKey: "isBroadcasting") ?? false
    }
    
}
extension AppStrings {
    static let broadcastFinishedNotification = "com.sumit.remote"
}
extension Notification.Name {
    static let recordingFinished = Notification.Name("recordingFinished")
}
