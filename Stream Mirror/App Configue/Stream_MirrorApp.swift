//
//  Stream_MirrorApp.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

@main
struct Stream_MirrorApp: App {
    
    @StateObject var commonVM = CommonConnectionViewModel()
    @StateObject var TVRemoteVM = RemoteViewModel()
    @StateObject private var webServer = TVCastServer.shared
    @StateObject private var mirroringwebserver = TVMirrorServer.shared
    
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SplashView()
            }
            .environmentObject(commonVM)
            .environmentObject(TVRemoteVM)
        }
    }
}
