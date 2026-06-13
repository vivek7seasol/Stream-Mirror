//
//  BroadCastManager.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 06/05/26.
//

import Foundation
import Combine
import GoogleCast

class BroadCastPickerManager: NSObject, ObservableObject, GCKSessionManagerListener {
    @Published var isConnected: Bool = false
    private var castSession: GCKCastSession?
    private var customChannel: MyCustomCastChannel?
    private let commonVm: CommonConnectionViewModel?
    private var broadcastTimer: Timer?
    private var setupCompleted: Bool = false
    private let suiteName = AppStrings.groupID

    init(commonVm: CommonConnectionViewModel) {
        self.commonVm = commonVm
        super.init()
    
        GCKCastContext.sharedInstance().sessionManager.add(self)
        
        broadcastTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkBroadcastStatus()
        }
    }

    private func checkBroadcastStatus() {
        guard !setupCompleted else {
            broadcastTimer?.invalidate()
            return
        }
        
        if let userDefaults = UserDefaults(suiteName: suiteName),
           userDefaults.bool(forKey: "isBroadcasting") {
            if isConnected {
                sendMessageToCustomChannel()
                setupCompleted = true
                broadcastTimer?.invalidate()
            } else {
                connectToDevice()
            }
        }
    }
    
    func stopCastingSession() {
        if let castSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession {
            castSession.end(with: .stopCasting)
            print("Disconnected from device")
        }
    }

    @objc private func handleStartCastingSession() {
        print("channel connected")
        connectToDevice()
    }

    private func connectToDevice() {
        guard let device = commonVm?.castViewModel.selectedDevice else {
            print("No device selected in CastViewModel")
            return
        }
        commonVm?.castViewModel.startCustomReceiverSession(with: device)
        SilentAudioManager.shared.start()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        guard let castSession = session as? GCKCastSession else {
            print("Failed to cast session to GCKCastSession")
            return
        }
        self.castSession = castSession
        addCustomChannelToSession(castSession)
        print("Session started with device: \(session.device.friendlyName ?? "Unknown Device")")
    }

    private func addCustomChannelToSession(_ session: GCKCastSession) {
        if customChannel == nil {
            customChannel = MyCustomCastChannel(namespace: AppStrings.channelNamespace, suiteName: suiteName)
        }

        if let channel = customChannel {
            session.add(channel)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.isConnected = channel.isConnected
                self?.checkBroadcastStatus()
            }
        } else {
            isConnected = false
        }
    }

    private func sendMessageToCustomChannel() {
        guard let customChannel = customChannel, isConnected else {
            print("CustomChannel is not connected or initialized")
            return
        }
        if let url = TVMirrorServer.shared.serverURL {
            let urlString = url.absoluteString
            sendMessage(urlString)
        }
    }

    private func sendMessage(_ message: String) {
        guard let customChannel = customChannel, isConnected else {
            print("CustomChannel is not connected or initialized")
            return
        }
        var error: GCKError?
        customChannel.sendTextMessage(message, error: &error)
        if let error = error {
            print("Error sending text message: \(error.localizedDescription)")
        }
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didResume session: GCKSession) {
        guard let castSession = session as? GCKCastSession else {
            print("Failed to cast session to GCKCastSession")
            return
        }
        self.castSession = castSession
        addCustomChannelToSession(castSession)
        print("Session resumed with device: \(session.device.friendlyName ?? "Unknown Device")")
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        isConnected = false
        setupCompleted = false
        SilentAudioManager.shared.stop()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        isConnected = false
        setupCompleted = false
    }
    
    deinit {
        broadcastTimer?.invalidate()
        broadcastTimer = nil
        GCKCastContext.sharedInstance().sessionManager.remove(self)
    }
    
    
    func removeCurrentSession(){
        GCKCastContext.sharedInstance().sessionManager.remove(self)
    }
}


class MyCustomCastChannel: GCKCastChannel, GCKSessionManagerListener {
    private let suiteName: String

    init(namespace: String, suiteName: String) {
        self.suiteName = suiteName
        super.init(namespace: namespace)
    }

    override func didReceiveTextMessage(_ message: String) {
        super.didReceiveTextMessage(message)
        print("Received message: \(message)")
        handleMessage(message: message)
    }
    
    override func didConnect() {
        super.didConnect()
        print("Channel connected")
    }
    
    override func didDisconnect() {
        super.didDisconnect()
        GCKCastContext.sharedInstance().sessionManager.remove(self)
        print("Channel disconnected")
    }
    
    private func handleMessage(message: String) {
        print("Handling message: \(message)")
    }
}

