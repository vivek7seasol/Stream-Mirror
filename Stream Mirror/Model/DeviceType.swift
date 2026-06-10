//
//  DeviceType.swift
//  Screen Mirroring Casting
//
//  Created by Ronik Hirpara on 11/10/25.
//

import Foundation
import SwiftUI
import ConnectSDK
import GoogleCast


enum TVType {
    case ANDROID
    case LG
    case AIRPLAY
    case NONETV
    case ROKU
    case SAMSUNG
    case FIRE
}

var selectedTvType : TVType = .NONETV

enum DeviceType:Hashable {
    case lg(ConnectableDevice)
    case cast(GCKDevice)
    
    var name: String {
        switch self {
        case .lg(let device): return device.friendlyName ?? "Unknown LG TV"
        case .cast(let device): return device.friendlyName ?? "Unknown Android TV"
        }
    }
    
    var id: String {
        switch self {
        case .lg(let device): return device.address ?? UUID().uuidString
        case .cast(let device): return device.deviceID
        }
    }
}

extension DeviceType: Equatable {
    static func == (lhs: DeviceType, rhs: DeviceType) -> Bool {
        switch (lhs, rhs) {
        case (.lg(let d1), .lg(let d2)):
            return d1.address == d2.address

        case (.cast(let d1), .cast(let d2)):
            return d1.deviceID == d2.deviceID

        default:
            return false
        }
    }
}
