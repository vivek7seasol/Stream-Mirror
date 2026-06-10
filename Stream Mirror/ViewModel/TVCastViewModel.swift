//
//  TVCastViewModel.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 06/05/26.
//

import Foundation
import Combine
import GoogleCast

var gcastDevice: [GCKDevice] = []
class TVCastViewModel: NSObject, ObservableObject, GCKDiscoveryManagerListener  {
//    @Published var devices: [GCKDevice] = []
    @Published var selectedDevice: GCKDevice?
    @Published var isDiscovering: Bool = false
    @Published var isCastingInProgress = false
    @Published var isConnected = false
    let SELECTED_TV = "SELECTED_TV"
    static let shared = TVCastViewModel()
    var superVC : UIViewController?
    var castDetail: CastDetail?
    var onStartVideo: (() -> Void)?
    
    var discoveryManager: GCKDiscoveryManager?
    private var sessionCompletionHandler: ((Bool) -> Void)?
    private var pendingMediaToCast: (url: URL, mediaType: String)?
    
    
    override init() {
        super.init()
        GCKCastContext.sharedInstance().sessionManager.add(self)
        startDiscovery()
    }
    
    func startDiscovery() {
        isDiscovering = true
        
        discoveryManager?.stopDiscovery()
        let receiverAppID = kGCKDefaultMediaReceiverApplicationID
        let discoveryCriteria = GCKDiscoveryCriteria(applicationID: receiverAppID)
        let options = GCKCastOptions(discoveryCriteria: discoveryCriteria)
        GCKCastContext.setSharedInstanceWith(options)
        
        GCKLogger.sharedInstance().delegate = self
        
        discoveryManager = GCKCastContext.sharedInstance().discoveryManager
        discoveryManager?.add(self)
        discoveryManager?.passiveScan = true
        discoveryManager?.startDiscovery()
        print("CastViewModel Devices :-  \(discoveryManager?.deviceCount) \(gcastDevice)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isDiscovering = false
        }
    }
    
    func connectToDevice(_ device: GCKDevice, isShowPopup : Bool) {
        selectedDevice = device
        isConnected = true
        selectedTvType = .ANDROID
        startDefaultMediaPlayerSession(with: device)
        
        setSelectedTV(name: "Gcast-\(device.friendlyName ?? "GcastTV")")
        
        print("Connected to device: \(selectedDevice?.friendlyName ?? "Unknown")")
    }
    
    func setSelectedTV(name:String){
        UserDefaults().set(name, forKey: SELECTED_TV)
        UserDefaults().synchronize()
    }
    
    func disconnectFromDevice() {
        if let castSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession {
            castSession.end(with: .stopCasting)
            selectedDevice = nil
            GCKCastContext.sharedInstance().sessionManager.remove(self)
            print("Disconnected from device")
        }
        selectedDevice = nil
        isConnected = false
    }
    
    func stopCastingSession() {
        if let castSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession {
            castSession.end(with: .stopCasting)
            isCastingInProgress = false
            print("Disconnected from device")
        }
    }
    
    func isCastingSessionGoing() -> Bool {
        return GCKCastContext.sharedInstance().sessionManager.currentCastSession != nil
    }
    
    func setDefaultSessionOptions(for appID: String) {
        GCKCastContext.sharedInstance().sessionManager.setDefaultSessionOptions(
            ["gck_applicationID": NSString(string: appID)],
            forDeviceCategory: kGCKCastDeviceCategory
        )
    }
    
    func startDefaultMediaPlayerSession(with device: GCKDevice) {
        print("Starting default media session")
        setDefaultSessionOptions(for: kGCKDefaultMediaReceiverApplicationID)
        GCKCastContext.sharedInstance().sessionManager.startSession(with: device)
    }
    
    func startCustomReceiverSession(with device: GCKDevice) {
        setDefaultSessionOptions(for: AppStrings.kCustomReceiverAppID)
        GCKCastContext.sharedInstance().sessionManager.startSession(with: device)
    }
    
    func StopRemoteMediaCleint() {
        guard let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient else {
            return
        }
        remoteMediaClient.stop()
    }
    
    func startCastSession() {
        
        if selectedDevice == nil {
            print("⚠️ Fixing missing device automatically")
            
            if let first = gcastDevice.first {
                selectedDevice = first
                print("✅ Auto-selected device:", first.friendlyName ?? "")
            }
        }
        
        guard let device = selectedDevice else {
            print("❌ STILL no device")
            return
        }
        
        startDefaultMediaPlayerSession(with: device)
    }
    
    func castMedia(_ url: URL, mediaType: String, title: String, des: String) {
        StopRemoteMediaCleint()
        pendingMediaToCast = (url, mediaType)
        onStartVideo?()
        if isCastingSessionGoing() {
            executeMediaCasting(url, mediaType: mediaType, title: title, des: des)
        } else {
            startCastSession()
        }
    }
    
    func youtubeCasting(videoId: String) {
        
        guard let remoteMediaClient = GCKCastContext.sharedInstance()
            .sessionManager.currentCastSession?.remoteMediaClient else {
            print("No active cast session")
            startCastSession()
            return
        }
        
        let youtubeURL = "https://www.youtube.com/watch?v=\(videoId)"
        
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString("YouTube", forKey: kGCKMetadataKeyTitle)
        
        let mediaInformation = GCKMediaInformation(
            contentID: youtubeURL,
            streamType: .buffered,
            contentType: "video/mp4",
            metadata: metadata,
            streamDuration: 0,
            mediaTracks: nil,
            textTrackStyle: nil,
            customData: nil
        )
        
        let options = GCKMediaLoadOptions()
        options.autoplay = true
        
        remoteMediaClient.loadMedia(mediaInformation, with: options)
        
        print("Casting YouTube video: \(videoId)")
    }
    
    private func executeMediaCasting(_ url: URL, mediaType: String, title: String, des: String) {
        guard let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient else {
            print("executeMediaCasting: No cast session found.")
            startCastSession()
            return
        }
        
        if let mediaStatus = remoteMediaClient.mediaStatus, mediaStatus.playerState == .playing {
            print("executeMediaCasting: Stopping current media before casting new media...")
            remoteMediaClient.stop()
        }
        
        print("executeMediaCasting: Casting media...")
        
        let metaData = GCKMediaMetadata()
        metaData.setString(title, forKey: kGCKMetadataKeyTitle)
        metaData.setString(des, forKey: kGCKMetadataKeySubtitle)
        if mediaType != "image/jpeg"{
            metaData.addImage(GCKImage(url: URL(string: "https://buffer.com/library/content/images/library/wp-content/uploads/2017/09/13-Places-to-Find-Background-Music-for-Video-Cover-Image-2.jpg")!, width: 480, height: 360))
        }
        let mediaInformation = GCKMediaInformation(
            contentID: url.absoluteString,
            streamType: .buffered,
            contentType: mediaType,
            metadata: metaData,
            streamDuration: 0,
            mediaTracks: nil,
            textTrackStyle: nil,
            customData: nil
        )
        
        let mediaLoadOptions = GCKMediaLoadOptions()
        mediaLoadOptions.autoplay = true
        
        remoteMediaClient.loadMedia(mediaInformation, with: mediaLoadOptions)
        
        DispatchQueue.main.async {
            self.isCastingInProgress = false
            print("executeMediaCasting: isCastingInProgress set to false")
        }
    }
    
    func seekMedia(to time: Float) {
        guard let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient else {
            return
        }
        
        let mediaSeekOptions = GCKMediaSeekOptions()
        mediaSeekOptions.interval = TimeInterval(time)
        mediaSeekOptions.resumeState = .unchanged
        remoteMediaClient.seek(with: mediaSeekOptions)
    }
    
    // MARK: - GCKDiscoveryManagerListener
    
    func didUpdateDeviceList() {
        guard let discoveryManager = discoveryManager else { return }
        DispatchQueue.main.async {
            gcastDevice = (0..<discoveryManager.deviceCount).compactMap { discoveryManager.device(at: $0) }
            print("Google Cast TV : \(gcastDevice)")
            gcastDevice.forEach {
                print("Google Cast TV List update  : \($0.friendlyName ?? "")")
                
            }
        }
    }
    
    func didAddDevice(_ device: GCKDevice) {
        DispatchQueue.main.async {
            if !gcastDevice.contains(device) {
                gcastDevice.append(device)
                print("Google Cast TV : \(gcastDevice)")
                
            }
        }
    }
    
    func didRemoveDevice(_ device: GCKDevice) {
        DispatchQueue.main.async {
            gcastDevice.removeAll { $0 == device }
            print("Google Cast TV : \(gcastDevice)")
        }
    }
    
    private func attemptCastingPendingMedia(_ pendingMedia: (url: URL, mediaType: String), retries: Int, delay: TimeInterval, title: String, des: String) {
        guard retries > 0 else {
            print("executeMediaCasting: failed after retries, remoteMediaClient not ready ❌")
            return
        }
        
        if let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient {
            print("executeMediaCasting: remoteMediaClient ready, casting ✅")
            self.executeMediaCasting(pendingMedia.url, mediaType: pendingMedia.mediaType, title: title, des: des)
            self.pendingMediaToCast = nil
        } else {
            print("executeMediaCasting: remoteMediaClient not ready, retrying...")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.attemptCastingPendingMedia(pendingMedia, retries: retries - 1, delay: delay, title: title, des: des)
            }
        }
    }
    
}

extension TVCastViewModel: GCKLoggerDelegate {
    func logMessage(_ message: String, fromFunction function: String, location: String) {
        print("\(location): \(function) - \(message)")
    }
}


extension TVCastViewModel: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        print("sessionManager: didStart session")
        
        self.isCastingInProgress = false
        
        guard let pendingMedia = self.pendingMediaToCast else {
            print("sessionManager: no pending media to cast")
            return
        }
        
        attemptCastingPendingMedia(pendingMedia, retries: 3, delay: 1.0, title: AppStrings.appName, des: "")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        print("Failed to start session: \(error.localizedDescription)")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        print("Session ended: \(error?.localizedDescription ?? "No error")")
        self.isCastingInProgress = false
    }
}

