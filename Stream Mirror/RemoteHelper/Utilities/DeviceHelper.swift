//
//  DeviceHelper.swift
//  TV Remote
//
//  Created by iOS Developer on 28/08/2025.
//


import UIKit

class DeviceHelper {
    
    /// Returns `true` if the current device is an iPad
    static var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Returns `true` if the current device is an iPhone
    static var isIphone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Returns the device type as a string
    static var deviceType: String {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return "iPad"
        case .phone:
            return "iPhone"
        default:
            return "Unknown"
        }
    }
}
