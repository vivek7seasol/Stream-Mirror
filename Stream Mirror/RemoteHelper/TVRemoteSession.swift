//
//  TVRemoteSession.swift
//  TVRemote
//
//  Created by Parthiv Akbari on 17/02/26.
//

import Foundation

final class TVRemoteSession {

    static let shared = TVRemoteSession()

    let viewModel = TVRemoteViewModel()
    private var isConfigured = false

    private init() {}

    func startDiscovery() {

        viewModel.configureDiscoveryIfNeeded()   // ← configure FIRST
        viewModel.startDiscovery()               // ← then start
    }


    func restartDiscovery() {

        viewModel.stopDiscovery()

        // ⚠️ VERY IMPORTANT — give SSDP time to release sockets
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {

            self.viewModel.discoveredDevices.removeAll()

            self.viewModel.startDiscovery()
        }
    }


    func stopDiscovery() {
        viewModel.stopDiscovery()
    }
}
