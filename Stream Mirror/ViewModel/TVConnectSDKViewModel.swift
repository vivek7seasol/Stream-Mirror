//
//  ConnectSDKVM.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 06/05/26.
//

import Foundation
import Combine
import ConnectSDK

struct CastDetail{
    var titleStr : String
    var subtitleStr : String
    var image : URL
}

class TVConnectSDKViewModel: NSObject, ObservableObject {
    var discoveryManager: DiscoveryManager
    private var launchObject: MediaLaunchObject?
    private var launcher: Launcher!
    
    @Published var lgDevices: [ConnectableDevice] = []
    @Published var isConnectedToLG: Bool = false
    @Published var selectedLGDevice: ConnectableDevice? = nil
    @Published var showVideoControls: Bool = true
    let groupId = AppStrings.groupID
    var superVC : UIViewController?
    var isShowPopup : Bool = false
    var onStartVideo: (() -> Void)?
    let SELECTED_TV = "SELECTED_TV"

    var castDetail: CastDetail?
    
    @Published var deviceIpAddress: String? {
        didSet {
            UserDefaultManager.shared.saveStandard(deviceIpAddress, forKey: AppStrings.deviceIPKey)
        }
    }
    
    override init() {
    
        discoveryManager = DiscoveryManager.shared()
        super.init()
//        setupDiscovery()
        
        if let savedIpAddress: String = UserDefaultManager.shared.getStandard(forKey: AppStrings.deviceIPKey) {
            self.deviceIpAddress = savedIpAddress
        }
    }
    
    // MARK: - Discovery Setup
    func setupDiscovery() {
//        discoveryManager.delegate = self
//        discoveryManager.pairingLevel = DeviceServicePairingLevelOn
//        discoveryManager.registerDeviceService(WebOSTVService.self, withDiscovery: SSDPDiscoveryProvider.self)
//        discoveryManager.registerDeviceService(DLNAService.self, withDiscovery: SSDPDiscoveryProvider.self)
//        discoveryManager.startDiscovery()
    }
     
    func stopDiscovery() {
        discoveryManager.stopDiscovery()
    }
    
    func connectToLGDevice(at index: Int) {
        let device = lgDevices[index]
        device.setPairingType(DeviceServicePairingTypePinCode)
        device.delegate = self
        device.connect()
        
        print("Connecting to LG device: \(device.friendlyName ?? "Unknown LG Device")")
        
        if let ipAddress = device.address {
            self.deviceIpAddress = ipAddress
            print("Device IP Address: \(ipAddress)")
            
            UserDefaultManager.shared.saveShared(ipAddress, forKey: "ConnectedDeviceIP")
            print("IP Address saved to shared defaults: \(ipAddress)")
        }
    }
    
    func disconnectLGDevice() {
        selectedLGDevice?.disconnect()
        selectedLGDevice = nil
        isConnectedToLG = false
    }
    
    func LGMirroring(mediaURL: URL){
        print("lg mirror \(mediaURL)")
        SilentAudioManager.shared.start()
        if selectedLGDevice?.launcher() != nil{
            selectedLGDevice?.launcher().launchBrowser(mediaURL, success: { launchSession in
                print("Browser successfully launched.")
            }, failure: { error in
                if let error = error {
                    print("Failed to launch the browser: \(error.localizedDescription)")
                }
            })
        }else{
            print("Browser nil")
        }
    }
    
    func sendMediaToLGTVWeb(mediaUrl: URL) {
            guard let device = selectedLGDevice else {
                print("⚠️ sendMediaToLGTVWeb: no selected device")
                return
            }
    
            guard let launcher = device.launcher() else {
                print("⚠️ sendMediaToLGTVWeb: launcher() returned nil")
                return
            }
    
            DispatchQueue.main.async {   // <-- FIX
                launcher.launchBrowser(mediaUrl, success: { launchSession in
                    print("✅ Browser launched successfully")
                }, failure: { error in
                    print("❌ Failed to launch browser: \(error?.localizedDescription ?? "unknown error")")
                })
            }
        }
    
    func sendMediaToLGTVYT(mediaUrl: URL, mimeType: String) {
        if selectedLGDevice?.launcher() != nil{
            selectedLGDevice?.launcher().launchBrowser(mediaUrl, success: { launchSession in
                print("Browser successfully launched.")
                self.onStartVideo?()
            }, failure: { error in
                if let error = error {
                    self.onStartVideo?()
                    print("Failed to launch the browser: \(error.localizedDescription)")
                }
            })
        } else {
            print("Browser nil")
        }
    }
    
    func sendMediaToLGTV(mediaUrl: URL, mimeType: String, title: String?, des: String?, imgHei : Int, imgWid : Int) {
                if let userDefaults = UserDefaults(suiteName: AppStrings.groupID){
                    if userDefaults.bool(forKey: "isBroadcasting") == true {
                        return
                    }
                }
                if mimeType == "video/mp4" {
                    if let dlnaService = selectedLGDevice?.service(withName: "DLNA") as? DLNAService {
                        let mediaInfo = MediaInfo(url: mediaUrl, mimeType: mimeType)
    //                    mediaInfo?.title = castDetail?.titleStr ?? "\(APP_NAME)"
    //                    mediaInfo?.description = castDetail?.subtitleStr ?? ""
                        mediaInfo?.title = AppStrings.appName
                        mediaInfo?.description = ""
                        dlnaService.mediaPlayer().playMedia(with: mediaInfo, shouldLoop: false, success: { _ in
                            DispatchQueue.main.async {
                                    self.showVideoControls = true
                                }
                            print("✅ Playing via DLNA")
    //                        setIsCastOne(status: true)
    //                        self.onStartVideo?()
                        }, failure: { error in
                            DispatchQueue.main.async {
                                    self.showVideoControls = false
                                }
                            print("❌ DLNA playback failed: \(error?.localizedDescription ?? "Unknown")")
                            self.sendMediaToLGTVWeb(mediaUrl: mediaUrl)
                        })
                    }
                } else if mimeType == "image/jpeg"{
                    let mediaInfo = MediaInfo(url: mediaUrl, mimeType: mimeType)
    //                mediaInfo?.title = castDetail?.titleStr ?? "\(APP_NAME)"
    //                mediaInfo?.description = castDetail?.subtitleStr ?? ""
                    mediaInfo?.title = AppStrings.appName
                    mediaInfo?.description = des ?? ""
                    let imageInfo = ImageInfo(url: mediaUrl, type: .min)
                    imageInfo?.height = imgHei
                    imageInfo?.width = imgWid
                    mediaInfo?.addImage(imageInfo)
                    if let dlnaService = selectedLGDevice?.service(withName: "DLNA") as? DLNAService {
                        dlnaService.mediaPlayer().displayImage(with: mediaInfo) { _ in
                            print("✅ Image sent to TV via DLNA")
                        } failure: { error in
                            self.sendMediaToLGTVWeb(mediaUrl: mediaUrl)
                            print("❌ DLNA image display failed: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }else if mimeType == "audio/m4a"{
    //                isSplashCasting = false
                    if let dlnaService = selectedLGDevice?.service(withName: "DLNA") as? DLNAService {
                        let mediaInfo = MediaInfo(url: mediaUrl, mimeType: "audio/m4a")
    //                    mediaInfo?.title = castDetail?.titleStr ?? "\(APP_NAME)"
    //                    mediaInfo?.description = castDetail?.subtitleStr ?? ""
                        mediaInfo?.title = title ?? AppStrings.appName
                        mediaInfo?.description = des ?? ""
                        let imageInfo = ImageInfo(url: URL(string: "https://buffer.com/library/content/images/library/wp-content/uploads/2017/09/13-Places-to-Find-Background-Music-for-Video-Cover-Image-2.jpg"), type: .min)
                        mediaInfo?.addImage(imageInfo)
                        dlnaService.mediaPlayer().playMedia(with: mediaInfo, shouldLoop: false, success: { _ in
                            print("✅ Playing via DLNA")
                        }, failure: { error in
                            self.sendMediaToLGTVWeb(mediaUrl: mediaUrl)
                            print("❌ DLNA playback failed: \(error?.localizedDescription ?? "Unknown")")
                        })
                    }
                }
            }
    
    func pauseMedia() {
        guard let mediaControl = launchObject?.mediaControl else {
            print("Media control is not available")
            return
        }
        
        mediaControl.pause(success: {_ in
            print("Media paused successfully")
        }, failure: { error in
            print("Failed to pause media: \(error?.localizedDescription ?? "Unknown error")")
        })
    }
    
    func playMedia() {
        guard let mediaControl = launchObject?.mediaControl else {
            print("Media control is not available")
            return
        }
        
        mediaControl.play(success: {_ in
            print("Media resumed successfully")
        }, failure: { error in
            print("Failed to play media: \(error?.localizedDescription ?? "Unknown error")")
        })
    }
    
    func seekMedia(to seconds: TimeInterval) {
        guard let mediaControl = launchObject?.mediaControl else {
            print("Media control is not available")
            return
        }
        
        mediaControl.seek(seconds, success: {_ in
            print("Media seeked to \(seconds) seconds successfully")
        }, failure: { error in
            print("Failed to seek media: \(error?.localizedDescription ?? "Unknown error")")
        })
    }
    
    func disconnectFromTV() {
        guard let mediaSession = launchObject?.session else {
            print("No active session to close during disconnect")
            return
        }
        
        mediaSession.close(success: {_ in
            print("Disconnected and closed media session successfully")
            self.launchObject = nil
        }, failure: { error in
            print("Failed to close media session during disconnect: \(error?.localizedDescription ?? "Unknown error")")
            self.launchObject = nil
        })
    }
    
    func getMediaDuration(completion: @escaping (TimeInterval?) -> Void) {
        guard let mediaControl = launchObject?.mediaControl else {
            print("Media control is not available")
            completion(nil)
            return
        }
        
        mediaControl.getDurationWithSuccess({ duration in
            completion(duration)
        }, failure: { error in
            print("Failed to get media duration: \(error?.localizedDescription ?? "Unknown error")")
            completion(nil)
        })
    }
    
    func getCurrentMediaPosition(completion: @escaping (TimeInterval?) -> Void) {
        guard let mediaControl = launchObject?.mediaControl else {
            print("Media control is not available")
            completion(nil)
            return
        }
        
        mediaControl.getPositionWithSuccess({ position in
            completion(position)
        }, failure: { error in
            print("Failed to get media position: \(error?.localizedDescription ?? "Unknown error")")
            completion(nil)
        })
    }
    
    func stopMediaCasting() {
        SilentAudioManager.shared.stop()
        if let dlnaService = selectedLGDevice?.service(withName: "DLNA") as? DLNAService {
            dlnaService.mediaPlayer().closeMedia(launchObject?.session) { _ in
                print("Media casting stopped successfully")
            } failure: { error in
                print("Failed to stop media casting: \(error?.localizedDescription ?? "Unknown error")")
            }
            
            dlnaService.stop { _ in
                print("Media casting stopped successfully")
            } failure: { error in
                print("Failed to stop media casting: \(error?.localizedDescription ?? "Unknown error")")
            }
            
        }
        guard let mediaSession = launchObject?.session else {
            print("No active media session to close")
            return
        }
        
        mediaSession.close(success: {_ in
            print("Media casting stopped successfully")
            self.launchObject = nil
        }, failure: { error in
            print("Failed to stop media casting: \(error?.localizedDescription ?? "Unknown error")")
        })
    }
    
    func isMediaPlaying(completion: @escaping (Bool) -> Void) {
        guard let mediaControl = launchObject?.mediaControl else {
            print("Media control is not available")
            completion(false)
            return
        }
        
        mediaControl.getPlayState(success: { playState in
            print("Play state received: \(playState.rawValue)")
            if playState == MediaControlPlayStatePlaying {
                print("Yes, playing video")
                completion(true)
            } else {
                print("Not playing video")
                completion(false)
            }
        }, failure: { error in
            print("Failed to get play state: \(error?.localizedDescription ?? "Unknown error")")
            completion(false)
        })
    }
}


extension TVConnectSDKViewModel: DiscoveryManagerDelegate {
    func discoveryManager(_ manager: DiscoveryManager, didFind device: ConnectableDevice) {
        DispatchQueue.main.async {
            if !self.lgDevices.contains(where: { $0 == device }) {
                self.lgDevices.append(device)
                print("LG TV : \(self.lgDevices)")
            }
        }
    }
    
    func discoveryManager(_ manager: DiscoveryManager, didLose device: ConnectableDevice) {
        DispatchQueue.main.async {
            self.lgDevices.removeAll { $0 == device }
            print("LG TV : \(self.lgDevices)")
        }
    }
    
    func discoveryManager(_ manager: DiscoveryManager, didUpdate device: ConnectableDevice) {
        DispatchQueue.main.async {
            print("Device updated: \(device.friendlyName ?? "Unknown Device")")
            if !self.lgDevices.contains(where: { $0 == device }) {
                self.lgDevices.append(device)
                print("LG TV : \(self.lgDevices)")
            }
        }
    }
    
    func discoveryManager(_ manager: DiscoveryManager, didFailWithError error: NSError) {
        print("Discovery failed with error: \(error.localizedDescription)")
    }
}

// MARK: - ConnectableDeviceDelegate
extension TVConnectSDKViewModel: ConnectableDeviceDelegate {
    func connectableDeviceReady(_ device: ConnectableDevice) {
        DispatchQueue.main.async {
            if self.lgDevices.contains(device) {
                self.selectedLGDevice = device
                self.isConnectedToLG = true
                self.setSelectedTV(name: "LG-\(device.friendlyName ?? "LGTV")")
                selectedTvType = .LG
                print("LG device is ready: \(device.friendlyName ?? "Unknown LG Device")")
//                if let sVC = self.superVC as? DeviceListVC{
//                    sVC.connectedDevice = .LG(device)
//                    sVC.deviceListTableView.reloadData()
//                    DispatchQueue.main.async {
//                        sVC.connectionNameUpdateDelegate?.updateConnectionStatus(name: device.friendlyName ?? "Unknown", status: "Connected")
//                        sVC.showloader(isShow: false,isShowPopup: self.isShowPopup)
//                    }
//                }
                
            }
        }
    }
    func setSelectedTV(name:String){
        UserDefaults().set(name, forKey: SELECTED_TV)
        UserDefaults().synchronize()
    }
    
    func connectableDeviceDisconnected(_ device: ConnectableDevice, withError error: Error?) {
        DispatchQueue.main.async {
            if device == self.selectedLGDevice {
                self.selectedLGDevice = nil
                self.isConnectedToLG = false
//                if let sVC = self.superVC as? DeviceListVC{
//                    setSelectedTV(name: "")
//                    sVC.deviceListTableView.reloadData()
//                    DispatchQueue.main.async {
//                        sVC.connectionNameUpdateDelegate?.updateConnectionStatus(name: "Connect To TV", status: "Not Connected")
//                    }
//                }
            }
            print("Disconnected from device: \(device.friendlyName ?? "Unknown Device"), error: \(error?.localizedDescription ?? "No error info")")
        }
    }
    
    func connectableDeviceConnectionRequired(_ device: ConnectableDevice!, for service: DeviceService!) {
        print("LG device connectableDeviceConnectionRequired11")
    }
    
    func connectableDeviceConnectionSuccess(_ device: ConnectableDevice!, for service: DeviceService!) {
        print("LG device connectableDeviceConnectionSuccess2")
    }
    
    func connectableDevice(_ device: ConnectableDevice!, service: DeviceService!, disconnectedWithError error: (any Error)!) {
        disConntPairing()
        print("LG device disconnectedWithError- on cancel2")
    }
    
    func connectableDevice(_ device: ConnectableDevice!, service: DeviceService!, pairingRequiredOfType pairingType: Int32, withData pairingData: Any!) {
        print("LG device pairingRequiredOfType")
        disConntPairing()
    }
    
    func deviceService(_ service: DeviceService!, pairingFailedWithError error: (any Error)!) {
        disConntPairing()
        print("LG device pairingFailedWithError")
    }
    
    func disConntPairing(){
        self.selectedLGDevice = nil
        self.isConnectedToLG = false
//        if let sVC = self.superVC as? DeviceListVC{
//            sVC.deviceListTableView.reloadData()
//        }
    }
}


