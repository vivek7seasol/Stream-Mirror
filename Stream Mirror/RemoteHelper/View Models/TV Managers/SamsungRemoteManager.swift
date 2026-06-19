//
//  SamsungRemoteManager.swift
//  TV Remote
//
//  Created by IOS Developer on 09/09/2025.
//


import Foundation
import Combine

class SamsungRemoteManager: TVCommanderDelegate, ObservableObject {
    var deviceIP = ""
    var authToken: TVAuthToken?
    var tvWakeOnLANDevice = TVWakeOnLANDevice(mac: "")
    var remoteCommandKey = TVRemoteCommand.Params.ControlKey.mute
    var tvApp: TVApp = .netflix()
    var appStatus: TVAppStatus?
    private(set) var isConnecting = false
    @Published var isConnected = false
    @Published var authStatus = TVAuthStatus.none
    private(set) var isDisconnecting = false
    private(set) var tvIsWakingOnLAN = false
    private(set) var tvError: Error?
    private var commander: TVCommander?
    private let appManager: TVAppManaging

    private var webSocket: URLSessionWebSocketTask?
    private var webSocketSession: URLSession?
    private var isSocketConnected = false
    private let unsafeDelegate = UnsafeWebSocketDelegate()

    init() {
        appManager = TVAppManager()
    }

    var ControlsEnabled: Bool { isConnected && authStatus == .allowed }
    var DisconnectEnabled: Bool { isConnected }
    var WakeOnLANEnabled: Bool { !tvIsWakingOnLAN }
    var TvApps: [TVApp] { TVApp.allApps() }
    var ConnectEnabled: Bool { !isConnecting && !isConnected }
    var AuthTokenEntryDisabled: Bool { commander != nil || isConnecting || isConnected || isDisconnecting }

    var RemoteCommandKeys: [TVRemoteCommand.Params.ControlKey] {
        [ .powerOff, .up, .down, .left, .right, .enter, .returnKey, .channelList, .menu, .home, .play, .previous, .next,
            .pause, .exit, .source, .guide, .tools, .info, .colorRed, .colorGreen, .colorYellow, .colorBlue, .key3D,
            .volumeUp, .volumeDown, .mute, .number0, .number1, .number2, .number3, .number4, .number5, .number6,
            .number7, .number8, .number9, .sourceTV, .sourceHDMI, .contents,
        ]
    }

    func UserTappedConnect(ip: String) {
        SetupTVCommander(ip: ip)
        guard let commander else { return }
        isConnecting = true
        commander.connectToTV()
    }

    func UserTappedDismissError() { tvError = nil }

    func KeyPress(keyCode: TVRemoteCommand.Params.ControlKey) { commander?.sendRemoteCommand(key: keyCode) }

    func UserTappedSend() { commander?.sendRemoteCommand(key: remoteCommandKey) }

    func UserTappedDisconnect() {
        isDisconnecting = true
        commander?.disconnectFromTV()
    }

    func UserTappedWakeOnLAN() {
        
        guard !deviceIP.isEmpty else {
            print("❌ Missing IP")
            return
        }
        
        guard let mac = storedMac(for: deviceIP), !mac.isEmpty else {
            print("❌ MAC not available. Connect to TV once first.")
            tvError = NSError(domain: "WOL", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: "Connect to TV once to fetch MAC address"])
            return
        }
        
        let broadcast = getBroadcastAddress(from: deviceIP)
        
        let device = TVWakeOnLANDevice(
            mac: mac,
            broadcast: broadcast,
            port: 9
        )
        
        print("🚀 WOL → MAC:", mac)
        print("📡 Broadcast:", broadcast)
        
        tvIsWakingOnLAN = true
        
        // 🔥 Send multiple packets for reliability
        for i in 0..<3 {
            DispatchQueue.global().asyncAfter(deadline: .now() + Double(i) * 0.3) {
                TVCommander.wakeOnLANSamsung(device: device, queue: .main) { [weak self] error in
                    DispatchQueue.main.async {
                        self?.tvIsWakingOnLAN = false
                        self?.tvError = error
                    }
                }
            }
        }
    }


    func UserTappedAppStatus() {
        Task {
            await FetchAppStatus()
        }
    }

    func UserTappedLaunchApp(tvapp: TVApp) {
        Task {
            await LaunchApplication(app: tvapp)
        }
    }

    func UserTappedCustomApp(tvapp: TVApp) {
        Task {
            await LaunchApplication(app: tvapp)
        }
    }

    private func SetupTVCommander(ip: String) {
        guard commander == nil else { return }

        // ✅ LOAD SAVED TOKEN
        let savedToken = UserDefaults.standard.string(forKey: "samsung_tv_token_\(ip)")

        do {
            commander = try TVCommander(
                tvIPAddress: ip,
                appName: AppStrings.appName,
                authToken: savedToken // ✅ PASS TOKEN HERE
            )
            commander?.delegate = self
        } catch {
            tvError = error
        }
    }

    private func RemoveTVCommander() {
        commander = nil
    }

    private func FetchAppStatus() async {
        do {
            appStatus = try await appManager.fetchStatus(for: tvApp, tvIPAddress: deviceIP)
        } catch {
            tvError = error
        }
    }

    private func LaunchApplication(app: TVApp) async {
        do {
            try await appManager.launch(tvApp: app, tvIPAddress: deviceIP)
        } catch {
            tvError = error
        }
    }

    func tvCommanderDidConnect(_ tvCommander: TVCommander) {
        isConnecting = false
        isConnected = true

    }

    func tvCommanderDidDisconnect(_ tvCommander: TVCommander) {
        isDisconnecting = false
        isConnected = false

        // ✅ ADD THIS
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        webSocketSession = nil

        RemoveTVCommander()
    }

    func tvCommander(_ tvCommander: TVCommander, didUpdateAuthState authStatus: TVAuthStatus) {
        self.authStatus = authStatus
        authToken = tvCommander.tvConfig.token

        print("🔐 Auth Status:", authStatus)
        print("🔑 Token:", authToken ?? "nil")

        let key = "samsung_tv_token_\(deviceIP)"

        // ✅ ONLY connect when fully authorized
        if authStatus == .allowed {
            print("✅ AUTH COMPLETE → Connecting Mouse Socket")
            // ✅ SAVE TOKEN HERE
            if let token = authToken {
                UserDefaults.standard.set(token, forKey: key)
            }

            connectMouseSocket()
        }

        if authStatus == .denied {
            // ❌ REMOVE INVALID TOKEN
            UserDefaults.standard.removeObject(forKey: key)

            print("🗑️ Token removed (denied)")
        }
    }

    func tvCommander(_ tvCommander: TVCommander, didWriteRemoteCommand command: TVRemoteCommand) {
    }

    func tvCommander(_ tvCommander: TVCommander, didEncounterError error: TVCommanderError) {
        tvError = error
    }

    private func connectMouseSocket() {

        guard let token = authToken, !token.isEmpty else {
            print("❌ Token not available yet")
            return
        }

        let urlString = "wss://\(deviceIP):8002/api/v2/channels/samsung.remote.control?name=U2FtU3VuZw==&token=\(token)"

        guard let url = URL(string: urlString) else { return }

        let config = URLSessionConfiguration.default
        webSocketSession = URLSession(configuration: config,
                                      delegate: unsafeDelegate,
                                      delegateQueue: OperationQueue())

        webSocket = webSocketSession?.webSocketTask(with: url)
        webSocket?.resume()

        receiveMessages()

        print("✅ Samsung Mouse WebSocket Connected")
    }

    private func receiveMessages() {
            webSocket?.receive { [weak self] result in
                switch result {
                case .success(let message):
                    
                    if case let .string(text) = message {
                        print("📩 Samsung WS:", text)
                        
                        // ✅ Detect socket connected
                        if text.contains("ms.channel.connect") {
                            self?.isSocketConnected = true
                            print("✅ WebSocket AUTH SUCCESS")
                        }
                        
                        // 🔥 NEW: Extract MAC dynamically
                        self?.extractMac(from: text)
                    }
                    
                    self?.receiveMessages()
                    
                case .failure(let error):
                    print("❌ WS Error:", error)
                }
            }
        }


    func mouseMove(dx: Float, dy: Float) {
        guard isConnected else { return }

        let timestamp = Int(Date().timeIntervalSince1970)

        let json: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": "Move",
                "Position": [
                    "Time": "\(timestamp)",
                    "x": Int(dx),
                    "y": Int(dy)
                ],
                "TypeOfRemote": "ProcessMouseDevice"
            ]
        ]

        send(json: json)
    }

    func mouseClick() {
        guard isConnected else { return }

        let json: [String: Any] = [
            "method": "ms.remote.control",
            "params": [
                "Cmd": "LeftClick",
                "TypeOfRemote": "ProcessMouseDevice"
            ]
        ]

        send(json: json)
    }

    private func send(json: [String: Any]) {
        guard let ws = webSocket, isSocketConnected else {
            print("⚠️ Socket not ready / not authorized")
            return
        }

        if let data = try? JSONSerialization.data(withJSONObject: json),
           let string = String(data: data, encoding: .utf8) {

            ws.send(.string(string)) { error in
                if let error = error {
                    print("❌ Send error:", error)
                }
            }
        }
    }
    
    func getBroadcastAddress(from ip: String) -> String {
            var components = ip.split(separator: ".").map { String($0) }
            guard components.count == 4 else { return "255.255.255.255" }
            components[3] = "255"
            return components.joined(separator: ".")
        }
        
        private func storedMac(for ip: String) -> String? {
            UserDefaults.standard.string(forKey: "tv_mac_\(ip)")
        }
        private func saveMac(_ mac: String, for ip: String) {
            UserDefaults.standard.set(mac, forKey: "tv_mac_\(ip)")
        }
          
        private func extractMac(from text: String) {
            
            guard let data = text.data(using: .utf8) else { return }
            
            // 🔍 Try raw string fallback (IMPORTANT)
            if let mac = extractMacFromRawString(text) {
                print("✅ MAC FOUND (raw):", mac)
                saveMac(mac, for: deviceIP)
                return
            }
            
            // 🔍 Try JSON parsing
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            
            // Case 1: data.device.wifiMac
            if let dataObj = json["data"] as? [String: Any],
               let device = dataObj["device"] as? [String: Any],
               let mac = device["wifiMac"] as? String {
                
                print("✅ MAC FOUND (device.wifiMac):", mac)
                saveMac(mac, for: deviceIP)
                return
            }
            
            // Case 2: data.clients[].attributes.mac
            if let dataObj = json["data"] as? [String: Any],
               let clients = dataObj["clients"] as? [[String: Any]],
               let attributes = clients.first?["attributes"] as? [String: Any],
               let mac = attributes["mac"] as? String {
                
                print("✅ MAC FOUND (clients):", mac)
                saveMac(mac, for: deviceIP)
                return
            }
        }
        
        private func extractMacFromRawString(_ text: String) -> String? {
            
            let pattern = "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}"
            
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                
                return String(text[range])
            }
            
            return nil
        }
        
        
}

class UnsafeWebSocketDelegate: NSObject, URLSessionDelegate {

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        // ✅ Accept all certificates (for local TV)
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
