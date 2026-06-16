//
//  TVRemoteViewModel.swift
//  TV Remote
//
//  Created by iOS Developer on 26/08/2025.
//

import Foundation
import ConnectSDK
import Combine
import Network
import GoogleCast

class RemoteViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var connectedTVType: TVType?
    @Published var selectedTVType: TVType?
    @Published var deviceName: String?
    @Published var showSearchingSheet = false
    @Published var showDisconnectPopup = false
    @Published var showSearchBar = false
    @Published var showPinDialog = false
    @Published var showProgress = false
    @Published var showCountdownAlert = false
    @Published var discoveredDevices: [ConnectableDevice] = []
    @Published var pinCode = ""
    @Published var showAirPlayAlert = false
    
    private var isDiscoveryConfigured = false
    private var isSwitchingDevice = false
    private var pendingDevice: ConnectableDevice?
    weak var commonViewModel: CommonConnectionViewModel?
    // MARK: - Managers
    var currentTVManager: AnyObject?
    private var discoveryManager: DiscoveryManager
    private var cancellables: Set<AnyCancellable> = []
    @Published var isConnectedSuccessfully: Bool = false
    @Published var showAllowInTVSettingsAlert: Bool = false
    
    // MARK: - Port Mappings
    private let tvPorts: [TVType: [Int]] = [
        .LG: [3001],
        .ANDROID: [6467],
        .FIRE: [8009],
        .SAMSUNG: [8002],
        .ROKU: [8060]
        
    ]
    
    override init() {
        discoveryManager = DiscoveryManager.shared()
        
        super.init()
    }
    
    // MARK: - Discovery Setup
    func configureDiscoveryIfNeeded() {

        guard !isDiscoveryConfigured else { return }

        print("📡 Configuring DiscoveryManager")

        discoveryManager.delegate = self
        discoveryManager.pairingLevel = DeviceServicePairingLevelOn

        discoveryManager.registerDeviceService(RokuService.self, withDiscovery: SSDPDiscoveryProvider.self)
        discoveryManager.registerDeviceService(WebOSTVService.self, withDiscovery: SSDPDiscoveryProvider.self)
        discoveryManager.registerDeviceService(DLNAService.self, withDiscovery: SSDPDiscoveryProvider.self)
        discoveryManager.registerDeviceService(DIALService.self, withDiscovery: SSDPDiscoveryProvider.self)

        isDiscoveryConfigured = true
    }

    func startDiscovery() {
        print("📡 Starting Discovery")
        discoveryManager.startDiscovery()
    }
    
    func stopDiscovery() {
        print("🛑 Stopping Discovery")
        discoveryManager.stopDiscovery()
        isDiscoveryConfigured = false
    }

    func handleDeviceAction(
        onAirPlay: () -> Void,
        onTV: () -> Void,
        onNoDevice: () -> Void
    ) {
        let isAirPlayConnected = AVAudioSession.sharedInstance()
            .currentRoute.outputs
            .contains { $0.portType == .airPlay }

        if isAirPlayConnected {

            DispatchQueue.main.async {
                self.showAirPlayAlert = true
            }

            return
        }

        if let type = connectedTVType {
            if type == .AIRPLAY {

                DispatchQueue.main.async {
                    self.showAirPlayAlert = true
                }

            } else {
                onTV()
            }
        } else {
            onNoDevice()
        }
    }
    
    // MARK: - TV Connection Management
    func selectDevice(_ device: ConnectableDevice) {
        showProgress = true
        deviceName = device.friendlyName
                
        if let tvType = identifyTVType(from: device) {
            print("Identified by name: \(tvType), \(device.friendlyName)")
            connectToTV(type: tvType, device: device)
            return
        }
        
        print("Could not identify by name, starting port scan...")
        for (type, ports) in tvPorts {
            for port in ports {
                isPortOpen(host: device.address, port: port) { isOpen in
                    if isOpen {
                        DispatchQueue.main.async {
                            self.connectToTV(type: type, device: device)
                        }
                        return
                    }
                }
            }
        }
    }
    
    func connect(to device: ConnectableDevice) {

        // Prevent multiple taps while switching
        guard !isSwitchingDevice else {
            print("⚠️ Already switching device")
            return
        }

        // ✅ CASE 1: User tapped SAME device → DISCONNECT (Toggle behavior)
        if connectedTVType != nil,
           deviceName == device.friendlyName {

            print("🔌 Tapped connected device → Disconnecting")
            isSwitchingDevice = true

            disconnectTV()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isSwitchingDevice = false
            }

            return
        }

        // ✅ CASE 2: Connected to different TV → SWITCH
        if connectedTVType != nil {

            print("🔄 Switching TV connection...")
            isSwitchingDevice = true
            pendingDevice = device

            disconnectTV()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self,
                      let newDevice = self.pendingDevice else { return }

                print("🔌 Connecting to new device...")
                self.pendingDevice = nil
                self.isSwitchingDevice = false

                self.selectDevice(newDevice)
            }

            return
        }

        // ✅ CASE 3: Fresh connection
        print("🔌 Connecting to device...")
        selectDevice(device)
    }

    private func connectToTV(type: TVType, device: ConnectableDevice) {
        selectedTVType = type
        initializeTVManager(for: type, ipAddress: device.address)
        setupConnectionMonitoring(for: type)
        commonViewModel?.setConnectedTv(tvType: type)
        commonViewModel?.isDeviceConnected = true
        // Start connection process
        switch type {
        case .ANDROID:
            print("android connecting")
            // ✅ Start pairing process
            (currentTVManager as? AndroidTVManager)?.establishConnection(with: device.address)
            selectedTvType = .ANDROID
            // 🔥 MATCH CAST DEVICE USING IP
            if let castDevice = gcastDevice.first(where: {
                $0.ipAddress == device.address
            }) {
                print("✅ Found matching GCKDevice")
                commonViewModel?.castViewModel.selectedDevice = castDevice
                commonViewModel?.castViewModel.isConnected = true
            } else {
                print("⚠️ No matching GCKDevice found")
            }
            commonViewModel?.castViewModel.isConnected = true
            setSelectedTV(name: "Gcast-\(device.friendlyName ?? "GcastTV")")
        case .SAMSUNG:
            if let manager = currentTVManager as? SamsungTVManager {
                manager.deviceIP = device.address
                
                // ✅ STEP 1: Always connect FIRST
                manager.UserTappedConnect(ip: device.address)
                
                // ❗ DO NOT call WOL here
            }
            
            (currentTVManager as? SamsungTVManager)?.deviceIP = device.address
            (currentTVManager as? SamsungTVManager)?.UserTappedConnect(ip: device.address)
            selectedTvType = .SAMSUNG
            setSelectedTV(name: "Samsung-\(device.friendlyName ?? "SamsungTV")")
            if let castDevice = gcastDevice.first(where: {
                $0.ipAddress == device.address
            }) {
                print("✅ Found matching GCKDevice")
                commonViewModel?.castViewModel.selectedDevice = castDevice
                commonViewModel?.castViewModel.isConnected = true
            } else {
                print("⚠️ No matching GCKDevice found")
                if let device = device as? ConnectableDevice {
                    (currentTVManager as? LGTVManager)?.connectLG(device: device)
                }
                commonViewModel?.connectSDKDiscoveryModel.selectedLGDevice = device
                selectedTvType = .LG
                setSelectedTV(name: "LG-\(device.friendlyName ?? "LGTV")")
            }
            
        case .FIRE:
            (currentTVManager as? FireTVManager)?.deviceIP = device.address
            (currentTVManager as? FireTVManager)?.verifyInitialConnection { [weak self] showPin in
                DispatchQueue.main.async {
                    self?.showProgress = false
                    self?.showPinDialog = showPin
                }
            }
            selectedTvType = .FIRE
            setSelectedTV(name: "Fire-\(device.friendlyName ?? "FireTV")")
        case .ROKU: 
            (currentTVManager as? RokuTVManager)?.SelectRoku(device.address)
            selectedTvType = .ROKU
            setSelectedTV(name: "Roku-\(device.friendlyName ?? "RokuTV")")
        case .LG:
            if let device = device as? ConnectableDevice {
                (currentTVManager as? LGTVManager)?.connectLG(device: device)
            }
            commonViewModel?.connectSDKDiscoveryModel.selectedLGDevice = device
            selectedTvType = .LG
            setSelectedTV(name: "LG-\(device.friendlyName ?? "LGTV")")
        case .AIRPLAY:
            selectedTvType = .AIRPLAY
            break
        case .NONETV:
            selectedTvType = .NONETV
            setSelectedTV(name: "")
            break
        }
    }
    
    private func initializeTVManager(for type: TVType, ipAddress: String = "") {
        switch type {
        case .ANDROID:
            currentTVManager = AndroidTVManager()
        case .SAMSUNG:
            currentTVManager = SamsungTVManager()
        case .FIRE:
            currentTVManager = FireTVManager(ipAddress: ipAddress)
        case .ROKU:
            currentTVManager = RokuTVManager()
        case .LG:
            currentTVManager = LGTVManager()
        case .AIRPLAY:
            break
        case .NONETV:
            break
        }
    }
    
    private func setupConnectionMonitoring(for type: TVType) {
        switch type {
        case .ANDROID:
            monitorAndroidConnection()
        case .SAMSUNG:
            monitorSamsungConnection()
        case .FIRE:
            monitorFireConnection()
        case .ROKU:
            monitorRokuConnection()
        case .LG:
            monitorLGConnection()
        case .AIRPLAY:
            break
        case .NONETV:
            break
        }
    }
    
    func disconnectTV() {

        print("🛑 Disconnecting current TV")

        (currentTVManager as? AndroidTVManager)?.terminateConnection()
        (currentTVManager as? SamsungTVManager)?.UserTappedDisconnect()
        (currentTVManager as? FireTVManager)?.Disconnect()
        (currentTVManager as? RokuTVManager)?.Disconnect()
        (currentTVManager as? LGTVManager)?.disconnectFromTV()

        // Delay state reset slightly to allow SDK cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.connectedTVType = nil
            self.selectedTVType = nil
            self.currentTVManager = nil
            self.deviceName = nil
            self.showDisconnectPopup = false
            self.isConnectedSuccessfully = false
        }
        commonViewModel?.isDeviceConnected = false
        commonViewModel?.setConnectedTv(tvType: .NONETV)
        selectedTvType = .NONETV
        setSelectedTV(name: "")
        AppUtils.instance.hapticFeedback()
    }
    
    private func linkCastAfterAndroidConnected(retry: Int = 6) {
        guard retry > 0 else {
            print("❌ Cast device not found")
            return
        }

        let castDevices = gcastDevice

        print("📡 Available Cast Devices:", castDevices.map { $0.friendlyName ?? "" })

        // ✅ Try match by IP FIRST
        if let currentIP = (currentTVManager as? AndroidTVManager)?.deviceIP,
           let match = castDevices.first(where: {
               $0.ipAddress == currentIP
           }) {

            print("✅ Cast device linked via IP")

            TVCastViewModel.shared.selectedDevice = match
            TVCastViewModel.shared.isConnected = true
            return
        }

        // ✅ fallback name match
        if let tvName = deviceName,
           let match = castDevices.first(where: {
               ($0.friendlyName ?? "").lowercased().contains(tvName.lowercased())
           }) {

            print("✅ Cast device linked via NAME")

            TVCastViewModel.shared.selectedDevice = match
            TVCastViewModel.shared.isConnected = true
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.linkCastAfterAndroidConnected(retry: retry - 1)
        }
    }

    func submitPinCode() {
        print("PIN Submitted")
        print("selectedTVType =", selectedTVType as Any)
        guard let type = selectedTVType else { return }
        
        switch type {
        case .ANDROID:
            (currentTVManager as? AndroidTVManager)?.submitCode(pinCode)
        case .FIRE:
            (currentTVManager as? FireTVManager)?.verifyPin(pinCode: pinCode) { [weak self] status in
                if (self?.currentTVManager as? FireTVManager)?.connectionStatus == true {
                    self?.connectedTVType = .FIRE
                    self?.showPinDialog = false
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Remote Control Commands
    func sendCommand(_ key: RemoteKey) {
        guard let type = connectedTVType else {
            showSearchingSheet = true
            return
        }
        
        switch type {
        case .ANDROID:
            if let action = mapAndroidKey(key) {
                (currentTVManager as? AndroidTVManager)?.SendCommand(action: action)
            }
        case .SAMSUNG:
            if let code = mapSamsungKey(key) {
                (currentTVManager as? SamsungTVManager)?.KeyPress(keyCode: code)
            }
        case .FIRE:
            if let fireKey = mapFireTVKey(key) {
                (currentTVManager as? FireTVManager)?.PerformKeyPress(keyAction: fireKey)
            }
        case .ROKU:
            if let rokuKey = mapRokuKey(key) {
                (currentTVManager as? RokuTVManager)?.KeyPress(key: rokuKey)
            }
        case .LG:
            if let lgCommand = mapLGKey(key) {
                (currentTVManager as? LGTVManager)?.sendCommand(lgCommand)
            }
        case .AIRPLAY:
            break
        case .NONETV:
            break
        }
        
        AppUtils.instance.hapticFeedback()
    }
    
    func sendNumber(_ key: String) {
        print("Key pressed: \(key)")
        
        switch connectedTVType {
        case .ANDROID:
            let mapping: [String: Key] = [
                "0": .KEYCODE_0,
                "1": .KEYCODE_1,
                "2": .KEYCODE_2,
                "3": .KEYCODE_3,
                "4": .KEYCODE_4,
                "5": .KEYCODE_5,
                "6": .KEYCODE_6,
                "7": .KEYCODE_7,
                "8": .KEYCODE_8,
                "9": .KEYCODE_9
            ]
            if let keyCode = mapping[key] {
                (currentTVManager as? AndroidTVManager)?.SendCommand(action: keyCode)
            }
            
        case .SAMSUNG:
            let mapping: [String: TVRemoteCommand.Params.ControlKey] = [
                "0": .number0,
                "1": .number1,
                "2": .number2,
                "3": .number3,
                "4": .number4,
                "5": .number5,
                "6": .number6,
                "7": .number7,
                "8": .number8,
                "9": .number9
            ]
            if let keyCode = mapping[key] {
                (currentTVManager as? SamsungTVManager)?.KeyPress(keyCode: keyCode)
            }
            
        default:
            break
        }
        
        AppUtils.instance.hapticFeedback()
    }


    
    func showSearchBar(isPro: Bool) {
        guard connectedTVType != nil else {
            showSearchingSheet = true
            return
        }
        
        showSearchBar = true
        AppUtils.instance.hapticFeedback()
    }
    
    // MARK: - App Launching
    func launchApp(_ app: TVApps) {
        guard let type = connectedTVType else {
            showSearchingSheet = true
            return
        }
        
        switch type {
        case .ANDROID:
            (currentTVManager as? AndroidTVManager)?.launchMediaOnRemoteScreen(url: app.deepLinkURL)
        case .SAMSUNG:
            (currentTVManager as? SamsungTVManager)?.UserTappedLaunchApp(tvapp: app.toSamsungApp())
        case .FIRE:
            (currentTVManager as? FireTVManager)?.launchAppOnRemote(appId: app.fireTVAppId) { _ in }
        case .ROKU:
            (currentTVManager as? RokuTVManager)?.launchApp(app.rokuAppId)
        case .LG:
            switch app {
            case .youtube:
                (currentTVManager as? LGTVManager)?.LaunchApp(url: "youtube.leanback.v4")
            case .netflix:
                (currentTVManager as? LGTVManager)?.LauchNetfliz()
            case .prime:
                (currentTVManager as? LGTVManager)?.LauchPrime()
            case .hotstar:
                (currentTVManager as? LGTVManager)?
                    .LaunchApp(url: "com.disney.disneyplus")
            case .spotify:
                    (currentTVManager as? LGTVManager)?.LaunchApp(url: "spotify-beehive")
            case .disney:
                (currentTVManager as? LGTVManager)?.LaunchApp(url: "com.disney.disneyplus-prod")
            case .paramount:
                (currentTVManager as? LGTVManager)?.LaunchApp(url: "com.cbs.app")
            }
        case .AIRPLAY:
            break
        case .NONETV:
            break
        }
        
        AppUtils.instance.hapticFeedback()
    }

    
    // MARK: - Helper Methods
//    private func identifyTVType(from deviceName: String) -> TVType? {
//        let lowercasedName = deviceName.lowercased()
//        
//        if lowercasedName.contains("lg") { return .LG }
//        if lowercasedName.contains("android") { return .ANDROID }
//        if lowercasedName.contains("fire") { return .FIRE }
//        if lowercasedName.contains("samsung") { return .SAMSUNG }
//        if lowercasedName.contains("roku") { return .ROKU }
//        
//        return nil
//    }
    
    private func identifyTVType(from deviceName: ConnectableDevice) -> TVType? {
        if let services = deviceName.services {
            for service in services {
                guard let service = service as? DeviceService else {
                    continue
                }
                let serviceClass = NSStringFromClass(type(of: service).self)
                print("Service found: \(serviceClass)")
                
                let modelName = deviceName.modelName ?? ""
                let manufacturer = deviceName.serviceDescription?.manufacturer ?? ""
                print("modelName :- \(modelName) , manufacturer :- \(manufacturer)")
                if manufacturer.lowercased().contains("samsung") || modelName.lowercased().contains("samsung") {
                    return .SAMSUNG
                }else if manufacturer.lowercased().contains("xiaomi")
                            || modelName.lowercased().contains("xiaomi")
                            || modelName.lowercased().contains("mitv")
                            || modelName.lowercased().contains("mi tv") {
                    return .ANDROID
                }else if let cls = NSClassFromString("WebOSTVService"), service.isKind(of: cls) {
                    return .LG
                } else if let cls = NSClassFromString("DLNAService"), service.isKind(of: cls) {
                    return .LG
                } else if let dialCls = NSClassFromString("DIALService"), service.isKind(of: dialCls) {
                    return .ROKU
                } else if let rokuCls = NSClassFromString("RokuService"), service.isKind(of: rokuCls) {
                    return .ROKU
                } else if let cls = NSClassFromString("FireTVService"), service.isKind(of: cls) {
                    return .FIRE
                } else if let cls = NSClassFromString("CastService"), service.isKind(of: cls) {
                    return .ANDROID
                } else if let cls = NSClassFromString("NetcastTVService"), service.isKind(of: cls) {
                    return .LG // Note: you had .ROKU here, probably should be .LG (NetcastTV is LG)
                }
            }
        }
        return nil
        
    }
    
    func isPortOpen(host: String, port: Int, completion: @escaping (Bool) -> Void) {
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port("\(port)")!, using: .tcp)
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                completion(true)
                connection.cancel()
            case .failed(_), .cancelled:
                completion(false)
            default:
                break
            }
        }
        connection.start(queue: .global())
    }
    
    // MARK: - Connection Monitoring
    private func monitorAndroidConnection() {
        print("monitoring android")
        (currentTVManager as? AndroidTVManager)?.connectionStateUpdated = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case "Connection Prepairing":
                    print("[TV Remote View Model] Connetion Preparing")
                    self?.showProgress = true
                    self?.showPinDialog = false
                    
                case "Waiting Code":
                    print("[TV Remote View Model] Waiting for Code")
                    self?.showProgress = false
                    self?.showPinDialog = true
                
                case "Option Request Sent":
                    print("[TV Remote View Model] Option Request Sent")
                    self?.showProgress = false
                    self?.showPinDialog = true
                    
                default:
                    break
                }
            }
        }
        
        (currentTVManager as? AndroidTVManager)?.deviceStateUpdated = { [weak self] state in
            DispatchQueue.main.async {
                if state == "connected" {
                    self?.connectedTVType = .ANDROID
                    self?.showPinDialog = false
                    self?.showProgress = false
                    self?.isConnectedSuccessfully = true

                    print("✅ Android TV fully connected")

                    // 🔥 ADD THIS LINE
                    self?.linkCastAfterAndroidConnected()
                }
            }
        }
    }
    
    private func monitorSamsungConnection() {
        guard let samsungManager = currentTVManager as? SamsungTVManager else { return }
        samsungManager.$authStatus
                .sink { [weak self] authStatus in
                    print("🔐 Auth Status:", authStatus)

                    if authStatus == .denied {
                        DispatchQueue.main.async {
                            self?.showAllowInTVSettingsAlert = true
                        }
                    }
                }
                .store(in: &cancellables)

        samsungManager.$isConnected
            .combineLatest(samsungManager.$authStatus)
            .map { isConnected, authStatus in
                isConnected && authStatus == .allowed
            }
            .sink { [weak self] areBothConnected in
                if areBothConnected {
                    self?.connectedTVType = .SAMSUNG
                    self?.showCountdownAlert = false
                    self?.isConnectedSuccessfully = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func monitorFireConnection() {
        (currentTVManager as? FireTVManager)?.$connectionStatus
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.connectedTVType = .FIRE
                    self?.isConnectedSuccessfully = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func monitorRokuConnection() {
        (currentTVManager as? RokuTVManager)?.$connectionStatus
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.connectedTVType = .ROKU
                    self?.isConnectedSuccessfully = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func monitorLGConnection() {
        (currentTVManager as? LGTVManager)?.$connectionStatus
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.connectedTVType = .LG
                    self?.isConnectedSuccessfully = true
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Key Mapping (Keep your existing mapping functions)
    private func mapAndroidKey(_ key: RemoteKey) -> Key? {
        switch key {
        case .POWER: return .KEYCODE_POWER
        case .VOLUMEUP: return .KEYCODE_VOLUME_UP
        case .VOLUMEDOWN: return .KEYCODE_VOLUME_DOWN
        case .CHANNELUP: return .KEYCODE_CHANNEL_UP
        case .CHANNELDOWN: return .KEYCODE_CHANNEL_DOWN
        case .HOME: return .KEYCODE_HOME
        case .BACK: return .KEYCODE_BACK
        case .OK: return .KEYCODE_ENTER
        case .EXIT: return .KEYCODE_HOME
        case .MUTE: return .KEYCODE_MUTE
        case .DPAD_UP: return .KEYCODE_DPAD_UP
        case .DPAD_DOWN: return .KEYCODE_DPAD_DOWN
        case .DPAD_LEFT: return .KEYCODE_DPAD_LEFT
        case .DPAD_RIGHT: return .KEYCODE_DPAD_RIGHT
        case .PAUSE_PLAY: return .KEYCODE_MEDIA_PLAY_PAUSE
            
        case .MENU: return .KEYCODE_MENU
        case .SETTINGS: return .KEYCODE_SETTINGS
        case .PAUSE: return .KEYCODE_MEDIA_PAUSE
        case .PLAY: return .KEYCODE_MEDIA_PLAY
        default: return nil
        }
    }
    
    private func mapRokuKey(_ key: RemoteKey) -> RokuRemoteKeys? {
        switch key {
        case .POWER: return .KEYCODE_POWER
        case .VOLUMEUP: return .KEYCODE_VOLUME_UP
        case .VOLUMEDOWN: return .KEYCODE_VOLUME_DOWN
        case .CHANNELUP: return .KEYCODE_DPAD_UP
        case .CHANNELDOWN: return .KEYCODE_DPAD_DOWN
        case .HOME: return .KEYCODE_HOME
        case .BACK: return .KEYCODE_BACK
        case .OK: return .KEYCODE_OK
        case .EXIT: return .KEYCODE_HOME
        case .MUTE: return .KEYCODE_MUTE
        case .DPAD_UP: return .KEYCODE_DPAD_UP
        case .DPAD_DOWN: return .KEYCODE_DPAD_DOWN
        case .DPAD_LEFT: return .KEYCODE_DPAD_LEFT
        case .DPAD_RIGHT: return .KEYCODE_DPAD_RIGHT
        case .PAUSE_PLAY: return .KEYCODE_OK
            
        case .STAR: return .KEYCODE_STAR
        case .RESTART: return .KEYCODE_REPLAY
        case .PLAY: return .KEYCODE_OK
        case .PAUSE: return .KEYCODE_OK
        default: return nil
        }
    }
    
    private func mapSamsungKey(_ key: RemoteKey) ->  TVRemoteCommand.Params.ControlKey?{
        switch key {
        case .POWER: return .powerToggle
        case .VOLUMEUP: return .volumeUp
        case .VOLUMEDOWN: return .volumeDown
        case .CHANNELUP: return .channelUp
        case .CHANNELDOWN: return .channelDown
        case .HOME: return .home
        case .BACK: return .returnKey
        case .OK: return .enter
        case .EXIT: return .exit
        case .MUTE: return .mute
        case .DPAD_UP: return .up
        case .DPAD_DOWN: return .down
        case .DPAD_LEFT: return .left
        case .DPAD_RIGHT: return .right
        case .PAUSE_PLAY: return .enter
            
        case .MENU: return .menu
        case .SETTINGS: return .menu
        case .PAUSE: return .pause
        case .PLAY: return .play
        default: return nil
        }
    }
    
    private func mapLGKey(_ key: RemoteKey) -> LGRemoteKeys? {
        switch key {
        case .POWER: return .KEYCODE_POWER
        case .VOLUMEUP: return .KEYCODE_VOLUME_UP
        case .VOLUMEDOWN: return .KEYCODE_VOLUME_DOWN
        case .CHANNELUP: return .KEYCODE_CHANNEL_UP
        case .CHANNELDOWN: return .KEYCODE_CHANNEL_DOWN
        case .HOME: return .KEYCODE_HOME
        case .BACK: return .KEYCODE_BACK
        case .OK: return .KEYCODE_OK
        case .EXIT: return .KEYCODE_HOME
        case .MUTE: return .KEYCODE_MUTE
        case .DPAD_UP: return .KEYCODE_DPAD_UP
        case .DPAD_DOWN: return .KEYCODE_DPAD_DOWN
        case .DPAD_LEFT: return .KEYCODE_DPAD_LEFT
        case .DPAD_RIGHT: return .KEYCODE_DPAD_RIGHT
        case .PAUSE_PLAY: return .KEYCODE_OK
            
            
        case .MENU: return .KEYCODE_MENU
        case .SETTINGS: return .KEYCODE_MENU
        case .PAUSE: return .KEYCODE_PAUSE
        case .PLAY: return .KEYCODE_PLAY
        default: return nil
        }
    }
    
    private func mapFireTVKey(_ key: RemoteKey) -> FireTVKeys? {
        switch key {
        case .POWER: return .KEYCODE_POWER
        case .VOLUMEUP: return .KEYCODE_VOLUME_UP
        case .VOLUMEDOWN: return .KEYCODE_VOLUME_DOWN
        case .CHANNELUP: return .KEYCODE_DPAD_UP
        case .CHANNELDOWN: return .KEYCODE_DPAD_DOWN
        case .HOME: return .KEYCODE_HOME
        case .BACK: return .KEYCODE_BACK
        case .OK: return .KEYCODE_OK
        case .EXIT: return .KEYCODE_EXIT
        case .MUTE: return .KEYCODE_MUTE
        case .DPAD_UP: return .KEYCODE_DPAD_UP
        case .DPAD_DOWN: return .KEYCODE_DPAD_DOWN
        case .DPAD_LEFT: return .KEYCODE_DPAD_LEFT
        case .DPAD_RIGHT: return .KEYCODE_DPAD_RIGHT
        case .PAUSE_PLAY: return .KEYCODE_OK
            
        case .PLAY: return .KEYCODE_PLAY
        case .PAUSE: return .KEYCODE_PAUSE
        case .SETTINGS: return .KEYCODE_MENU
        case .MENU: return .KEYCODE_MENU
        default: return nil
        }
    }
    
    private func mapHisenseKey(_ key: RemoteKey) -> HisenseRemoteKeys? {
        switch key {
        case .POWER: return .power
        case .VOLUMEUP: return .volumeUp
        case .VOLUMEDOWN: return .volumeDown
        case .CHANNELUP: return .channelUp
        case .CHANNELDOWN: return .channelDown
        case .HOME: return .home
        case .BACK: return .back
        case .OK: return .select
        case .EXIT: return .exit
        case .MUTE: return .mute
        case .DPAD_UP: return .up
        case .DPAD_DOWN: return .down
        case .DPAD_LEFT: return .left
        case .DPAD_RIGHT: return .right
        case .PAUSE_PLAY: return .play
            
        case .MENU: return .menu
        case .SETTINGS: return .menu
        case .PAUSE: return .pause
        case .PLAY: return .play
        default: return nil
        }
    }
    
    func moveCursor(dx: Float, dy: Float) {
        guard let type = connectedTVType else {
            showSearchingSheet = true
            return
        }
        
        switch type {
            
        case .LG:
            (currentTVManager as? LGTVManager)?.movePointer(dx: dx, dy: dy)
            
        case .SAMSUNG:
            (currentTVManager as? SamsungTVManager)?.mouseMove(dx: dx, dy: dy)
            
        default:
            // Optional fallback (you can ignore or use DPAD)
            break
        }
    }
    
    func clickCursor() {
        guard let type = connectedTVType else {
            showSearchingSheet = true
            return
        }
        
        switch type {
            
        case .LG:
            (currentTVManager as? LGTVManager)?.clickPointer()
            
        case .SAMSUNG:
            (currentTVManager as? SamsungTVManager)?.mouseClick()
            
        default:
            sendCommand(.OK)
        }
    }
}

// MARK: - DiscoveryManagerDelegate
extension RemoteViewModel: DiscoveryManagerDelegate {
    func discoveryManager(_ manager: DiscoveryManager!, didFind device: ConnectableDevice!) {
        print("ConnectSDK Found:",
                  device.friendlyName ?? "",
                  device.address)

        if !discoveredDevices.contains(where: { $0.address == device.address }) {
            discoveredDevices.append(device)
        }
        print("ConnectSDK Count:", discoveredDevices.count)
    }
    
    func discoveryManager(_ manager: DiscoveryManager!, didLose device: ConnectableDevice!) {
        discoveredDevices.removeAll { $0.address == device.address }
    }
    
    func discoveryManager(_ manager: DiscoveryManager!, didUpdate device: ConnectableDevice!) {
        if let index = discoveredDevices.firstIndex(where: { $0.address == device.address }) {
            discoveredDevices[index] = device
        }
    }
}

extension RemoteViewModel {

    func handleVoiceCommands(_ rawText: String) {

        let text = normalize(rawText)
        print("🎤 Normalized: \(text)")

        // =========================
        // 🎬 APP LAUNCH (SMART)
        // =========================

        if containsAny(text, ["youtube"]) {
            launchApp(.youtube)
            return
        }

        if containsAny(text, ["netflix"]) {
            launchApp(.netflix)
            return
        }

        if containsAny(text, ["prime", "amazon"]) {
            launchApp(.prime)
            return
        }

        // =========================
        // 🔍 CONTENT SEARCH
        // =========================

        if text.contains("search") || text.contains("play") || text.contains("watch") {

            if text.contains("youtube") {
                let query = extractSearchQuery(from: text, app: "youtube")
                launchApp(.youtube)

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.typeTextOnTV(query)
                }
                return
            }

            if text.contains("netflix") {
                let query = extractSearchQuery(from: text, app: "netflix")
                launchApp(.netflix)

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self.typeTextOnTV(query)
                }
                return
            }
        }

        // =========================
        // 🎮 REMOTE COMMANDS (SMART)
        // =========================

        if containsAny(text, ["volume up", "increase volume", "louder", "raise volume"]) {
            sendCommand(.VOLUMEUP)
            return
        }

        if containsAny(text, ["volume down", "decrease volume", "lower volume", "quieter"]) {
            sendCommand(.VOLUMEDOWN)
            return
        }

        if containsAny(text, ["mute", "silence"]) {
            sendCommand(.MUTE)
            return
        }

        if containsAny(text, ["home", "go home", "exit"]) {
            sendCommand(.HOME)
            return
        }

        if containsAny(text, ["back", "go back", "previous"]) {
            sendCommand(.BACK)
            return
        }

        if containsAny(text, ["up", "move up"]) {
            sendCommand(.DPAD_UP)
            return
        }

        if containsAny(text, ["down", "move down"]) {
            sendCommand(.DPAD_DOWN)
            return
        }

        if containsAny(text, ["left", "move left"]) {
            sendCommand(.DPAD_LEFT)
            return
        }

        if containsAny(text, ["right", "move right"]) {
            sendCommand(.DPAD_RIGHT)
            return
        }

        if containsAny(text, ["ok", "select", "confirm", "enter"]) {
            sendCommand(.OK)
            return
        }

        if containsAny(text, ["play", "resume"]) {
            sendCommand(.PLAY)
            return
        }

        if containsAny(text, ["pause", "stop"]) {
            sendCommand(.PAUSE)
            return
        }

        print("⚠️ Unknown command: \(text)")
    }

    private func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        return keywords.first { text.contains($0) } != nil
    }

    private func normalize(_ text: String) -> String {
        return text
            .lowercased()
            .replacingOccurrences(of: "please", with: "")
            .replacingOccurrences(of: "can you", with: "")
            .replacingOccurrences(of: "could you", with: "")
            .replacingOccurrences(of: "i want to", with: "")
            .replacingOccurrences(of: "let me", with: "")
            .replacingOccurrences(of: "show me", with: "")
            .replacingOccurrences(of: "open up", with: "open")
            .replacingOccurrences(of: "start up", with: "start")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractSearchQuery(from text: String, app: String) -> String {
        var cleaned = text

        cleaned = cleaned
            .replacingOccurrences(of: "play", with: "")
            .replacingOccurrences(of: "watch", with: "")
            .replacingOccurrences(of: "search", with: "")
            .replacingOccurrences(of: "on \(app)", with: "")

        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    func typeTextOnTV(_ text: String) {
        guard let type = connectedTVType else { return }

        switch type {

        case .ANDROID:
            (currentTVManager as? AndroidTVManager)?.sendText(text: text)

        case .FIRE:
            //            (currentTVManager as? FireTVManager)?.sendText(text)
            break
        case .ROKU:
            //            (currentTVManager as? RokuTVRemoteManager)?.sendText(text)
            break
        case .LG:
            //            (currentTVManager as? LGTVRemoteManager)?.sendText(text)
            break
        case .SAMSUNG:
            sendTextViaDPAD(text) // ✅ fallback

        default:
            break
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sendCommand(.OK)
        }
    }

    private func sendTextViaDPAD(_ text: String) {
        print("⌨️ Samsung fallback typing: \(text)")

        // NOTE: Samsung doesn't support direct typing
        // You can:
        // 1. Open keyboard UI
        // 2. Navigate (complex)

        // For now → just log or skip
    }
}
