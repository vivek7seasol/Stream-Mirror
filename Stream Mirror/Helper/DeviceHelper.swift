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
    
    static var width: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var height: CGFloat {
        UIScreen.main.bounds.height
    }
    
    static var topSafeArea: CGFloat {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .safeAreaInsets.top ?? 0
        }

        static var bottomSafeArea: CGFloat {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .safeAreaInsets.bottom ?? 0
        }
    
    static var iPadBottomPadding: CGFloat {
        height > width ? 640 : 1840
    }
    
    static func iPadPaddingBottom() -> CGFloat {
        let isLandscape = width > height
        return isLandscape ? 1840 : 640
    }
}
