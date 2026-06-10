//
//  CommonCastConnectSDKViewModel.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 06/05/26.
//

import Foundation
import Combine
import AVFoundation
internal import MediaPlayer
import GoogleCast

class CommonConnectionVM: ObservableObject {
    @Published var castViewModel: CastVM
    @Published var connectSDKDiscoveryModel: ConnectSDKVM
    
    @Published var connectedTvType: TVType?
    @Published var tvName: String?
    
    @Published var selectedQuality = 0
    @Published var isLoading = true
    @Published var isUploading = false
    
    @Published var isPlaying: Bool = false
    @Published var duration: Float = 0.0
    @Published var playbackPosition: Float = 0.0
    @Published var volume: Float = 0.5
    @Published var isSeeking = false
    @Published var playbackTimer: Timer?
    @Published var tvRemoteViewModel = TVRemoteViewModel()
    @Published var showVideoControls: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    private let volumeController = GCKUIDeviceVolumeController()
    
    init() {
        self.castViewModel = CastVM()
        self.connectSDKDiscoveryModel = ConnectSDKVM()
        
        observeAllTvManagersChanges()
    }
    
    private func observeAllTvManagersChanges() {
        castViewModel.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
        
        
        connectSDKDiscoveryModel.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    
    func setConnectedTv(tvType: TVType) {
        self.connectedTvType = tvType
        self.isDeviceConnected = true
        if tvType == .LG {
            connectSDKDiscoveryModel.isConnectedToLG = true
        }
        configureConnection(for: tvType)
    }
    
    
    func disconnectTv() {
        self.connectedTvType = nil
        tvName = nil
        self.isDeviceConnected = false
        castViewModel.disconnectFromDevice()
        connectSDKDiscoveryModel.disconnectFromTV()
    }
    
    
    func getConnectedTvType() -> TVType? {
        return connectedTvType
    }
    
    @Published var isDeviceConnected = false
    
    private func configureConnection(for tvType: TVType) {
        switch tvType {
        case .ANDROID:
            connectedTvType = .ANDROID
        case .LG:
            connectedTvType = .LG
        case .AIRPLAY:
            break
        case .NONETV:
            break
        case .ROKU:
            connectedTvType = .ROKU
        case .SAMSUNG:
            connectedTvType = .SAMSUNG
        case .FIRE:
            connectedTvType = .FIRE
        }
    }
    
    
    func StopCasting() {
        if connectedTvType == .ANDROID || connectedTvType == .SAMSUNG {
            castViewModel.stopCastingSession()
        } else if connectedTvType == .LG {
            connectSDKDiscoveryModel.stopMediaCasting()
        }
    }
    
    
    // MARK: - Start Playback
    func startPlaybackUpdates() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard !self.isSeeking else { return }
            self.updatePlayback()
        }
    }
    
    
    // MARK: - Stop Playback
    func stopPlaybackUpdates() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    
    // MARK: - Update Playback
    func updatePlayback() {
        if castViewModel.selectedDevice != nil {
            guard let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient else {
                return
            }
            
            if let mediaStatus = remoteMediaClient.mediaStatus {
                self.isPlaying = mediaStatus.playerState == .playing
                let newTime = Float(mediaStatus.streamPosition)
                if !isSeeking {
                    self.playbackPosition = newTime
                }
                self.playbackPosition = Float(remoteMediaClient.approximateStreamPosition())
                self.duration = Float(mediaStatus.mediaInformation?.streamDuration ?? 0)
            }
        } else if connectSDKDiscoveryModel.selectedLGDevice != nil {
            connectSDKDiscoveryModel.getCurrentMediaPosition(completion: { position in
                if let position = position {
                    self.playbackPosition = Float(position)
                }
            })
            
            connectSDKDiscoveryModel.getMediaDuration(completion: { duration in
                if let duration = duration {
                    self.duration = Float(duration)
                }
            })
            
            connectSDKDiscoveryModel.isMediaPlaying { isPlaying in
                if isPlaying {
                    self.isPlaying = isPlaying
                }
            }
        }
    }
    
    
    // MARK: - Seek Media
    func seek(to time: Float) {
        if getConnectedTvType() == .ANDROID {
            castViewModel.seekMedia(to: time)
        } else if connectSDKDiscoveryModel.selectedLGDevice != nil {
            connectSDKDiscoveryModel.seekMedia(to: TimeInterval(time))
        }
        
        isSeeking = false
    }
    
    
    // MARK: - Set Media Volume
    func setVolume(_ volume: Float) {
        if castViewModel.selectedDevice != nil {
            volumeController.setVolume(volume)
        }
    }
    
    
    // MARK: - Formate SeekBar Timer
    func formatTime(_ time: Float) -> String {
        guard !time.isNaN, time.isFinite, time >= 0 else { return "00:00" }
        
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    
    // MARK: - Toggle Pause & Resume
    func togglePauseResume() {
        if castViewModel.selectedDevice != nil {
            guard let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient else {
                return
            }
            if isPlaying {
                isPlaying = false
                remoteMediaClient.pause()
            } else {
                isPlaying = true
                remoteMediaClient.play()
            }
        } else if connectSDKDiscoveryModel.selectedLGDevice != nil {
            if isPlaying{
                isPlaying = false
                connectSDKDiscoveryModel.pauseMedia()
            } else {
                isPlaying = true
                connectSDKDiscoveryModel.playMedia()
            }
        }
    }
    
    func CastMedia(url: URL, mediaType: String, title: String, des: String, imgHei : Int, imgWid : Int) {
        
//        if isScreenMirroringActive() {
//            return
//        }
        
        switch getConnectedTvType() {
        case .ANDROID:
            castViewModel.castMedia(url, mediaType: mediaType, title: title, des: des)
        case .LG:
            connectSDKDiscoveryModel.sendMediaToLGTV(mediaUrl: url, mimeType: mediaType, title: title, des: des,imgHei: 500, imgWid: 500)
        case .none:
            print("none")
        case .some(.AIRPLAY):
            break
        case .some(.NONETV):
            break
        case .some(.ROKU):
            break
        case .some(.SAMSUNG):
            if castViewModel.selectedDevice == nil{
                connectSDKDiscoveryModel.sendMediaToLGTV(mediaUrl: url, mimeType: mediaType, title: title, des: des,imgHei: 500, imgWid: 500)
            } else {
                castViewModel.castMedia(url, mediaType: mediaType, title: title, des: des)
            }
        case .some(.FIRE):
            break
        }
    }
    
    func IPTVCast(mediaUrl: URL, title: String, des: String){
        //        if isScreenMirroringActive() {
        //            return
//        }
        if getConnectedTvType() == .ANDROID {
            CastMedia(url: mediaUrl, mediaType: "video/mp4", title: title, des: des,imgHei: 1024, imgWid: 1024)
//                        compressAndUploadVideo(from: mediaUrl, mediaType: "video/mp4", title: title, des: "", imgHei: 1024, imgWid: 1024, selectedQuality: 2)
        } else {
            connectSDKDiscoveryModel.sendMediaToLGTVWeb(mediaUrl: mediaUrl)
        }
    }
    
    func stopRemoteMediaClient() {
        if getConnectedTvType() == .ANDROID {
            castViewModel.StopRemoteMediaCleint()
        }
    }
    
    // MARK: - Stop Casting Media
    func stopMediaCasting() {
        switch getConnectedTvType() {
        case .ANDROID:
            castViewModel.stopCastingSession()
        case .LG:
            connectSDKDiscoveryModel.stopMediaCasting()
        case .AIRPLAY:
            break
        case .NONETV:
            break
        case .ROKU:
            break
        case .SAMSUNG:
            castViewModel.stopCastingSession()
            break
        case .FIRE:
            break
        case .none:
            print("none")
        }
        
        isPlaying = false
        stopPlaybackUpdates()
        setTVPlaceHolder(connectedTvType: connectedTvType ?? .ANDROID)
    }
    
    func resetMediaControl() {
        duration = 0.0
        playbackPosition = 0.0
        volume = 0.0
    }
    
    // MARK: - Photo casting
    func compressAndUploadImage(from url: URL, mediaType: String, title: String, des: String, imgHei : Int, imgWid : Int,selectedQuality : Int) {
        guard let image = UIImage(contentsOfFile: url.path) else {
            print("Unable to load image from URL")
            return
        }
        
        let targetSize: CGSize
        switch selectedQuality {
        case 0:
            targetSize = CGSize(width: 1280, height: 720)
        case 1:
            targetSize = CGSize(width: 1920, height: 1080)
        case 2:
            targetSize = CGSize(width: 3840, height: 2160)
        default:
            targetSize = CGSize(width: 1280, height: 720)
        }
        
        let compressionQuality: CGFloat
        switch selectedQuality {
        case 0:
            compressionQuality = 0.2
        case 1:
            compressionQuality = 0.6
        case 2:
            compressionQuality = 1.0
        default:
            compressionQuality = 0.6
        }
        
        let resizedImage = resizeImage(image: image, targetSize: targetSize)
        if let compressedImageData = resizedImage.jpegData(compressionQuality: compressionQuality) {
            let compressedURL = FileManager.default.temporaryDirectory.appendingPathComponent("compressed_image.jpg")
            do {
                try compressedImageData.write(to: compressedURL)
                uploadFile(compressedURL, mediaType: mediaType, title: title, des: des, imgHei: imgHei, imgWid: imgWid)
            } catch {
                print("Error writing compressed image to temporary URL: \(error)")
            }
        } else {
            print("Failed to compress image")
        }
    }
    
    // MARK: - Video casting
    func compressAndUploadVideo(_ url: URL) {
        let asset = AVAsset(url: url)
        let presetName: String
        
        switch selectedQuality {
        case 0:
            presetName = AVAssetExportPreset1280x720
        case 1:
            presetName = AVAssetExportPreset1920x1080
        case 2:
            presetName = AVAssetExportPreset3840x2160
        default:
            presetName = AVAssetExportPreset1280x720
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            print("Failed to create export session")
            return
        }
        
        let compressedURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        exportSession.outputURL = compressedURL
        exportSession.outputFileType = .mp4
        
        DispatchQueue.main.async {
            self.isUploading = true
        }
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    print("Video compressed successfully")
                    self.uploadFile(compressedURL, mediaType: "video/mp4", title: appName, des: "", imgHei: 1024, imgWid: 1024)
                case .failed:
                    self.isUploading = false
                    if let error = exportSession.error {
                        print("Video compression failed: \(error.localizedDescription)")
                    }
                case .cancelled:
                    self.isUploading = false
                    print("Video compression cancelled")
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Audio casting
    func exportAndUploadMusic(track: MPMediaItem) {
        guard let url = track.value(forProperty: MPMediaItemPropertyAssetURL) as? URL else {
            print("No URL for selected track.")
            return
        }
        
        let uniqueFileName = UUID().uuidString + ".m4a"
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let temporaryFileURL = temporaryDirectory.appendingPathComponent(uniqueFileName)
        
        if FileManager.default.fileExists(atPath: temporaryFileURL.path) {
            do {
                try FileManager.default.removeItem(at: temporaryFileURL)
            } catch {
                print("Failed to remove existing file: \(error)")
            }
        }
        
        exportMusic(from: url, to: temporaryFileURL) { success in
            if success {
                DispatchQueue.main.async {
                    self.uploadFile(temporaryFileURL, mediaType: "audio/m4a", title: track.title ?? appName, des: track.artist ?? "", imgHei: 1024, imgWid: 1024)
                }
            } else {
                print("Failed to export music")
            }
        }
    }
    
    // MARK: - Audio casting function
    private func exportMusic(from url: URL, to destinationURL: URL, completion: @escaping (Bool) -> Void) {
        let asset = AVAsset(url: url)
        guard let assetExportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            print("Failed to create export session")
            completion(false)
            return
        }
        
        assetExportSession.outputURL = destinationURL
        assetExportSession.outputFileType = .m4a
        
        assetExportSession.exportAsynchronously {
            switch assetExportSession.status {
            case .completed:
                completion(true)
            case .failed:
                print("Failed to export asset: \(String(describing: assetExportSession.error))")
                completion(false)
            default:
                print("Export session status: \(assetExportSession.status)")
                completion(false)
            }
        }
    }
    
    // MARK: - Photo resizing to the quality selected
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    // MARK: - upload to local server and then serve the tv
    func uploadFile(_ url: URL, mediaType: String, title: String, des: String,imgHei : Int, imgWid : Int) {
        guard var serverUrl = CastServer.shared.serverURL else {
            print("Invalid server URL")
            //            uploadFile(url, mediaType: mediaType)
            DispatchQueue.main.async { self.isUploading = false }
            return
        }
        
        serverUrl.appendPathComponent("upload")
        
        var request = URLRequest(url: serverUrl)
        request.httpMethod = "POST"
        request.setValue(mediaType, forHTTPHeaderField: "Content-Type")
        DispatchQueue.main.async {
            do {
                let fileData = try Data(contentsOf: url)
                
                // Ensure UI update
                DispatchQueue.main.async { self.isUploading = true }
                
                let task = URLSession.shared.uploadTask(with: request, from: fileData) { data, response, error in
                    DispatchQueue.main.async { self.isUploading = false }
                    
                    if let error = error {
                        print("Upload error: \(error)")
                        return
                    }
                    
                    guard
                        let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                        let data = data,
                        let responseUrl = String(data: data, encoding: .utf8),
                        let mediaUrl = URL(string: responseUrl)
                    else {
                        print("Invalid response")
                        return
                    }
                    print("📺 Connected TV Type:", self.getConnectedTvType() as Any)
                    print("Media uploaded to: \(mediaUrl)")
                    DispatchQueue.main.async {
                        if self.getConnectedTvType() != nil {
                            self.CastMedia(url: mediaUrl, mediaType: mediaType, title: title, des: des, imgHei: imgHei, imgWid: imgWid)
                        } else {
                            print("❌ No device connected, skipping cast")
                        }
                    }
                }
                
                task.resume()
            } catch {
                print("Error reading file data: \(error)")
                DispatchQueue.main.async { self.isUploading = false }
            }
        }
    }
    
//    MARK: - PDF,PPT Casting
//    func compressAndUploadPPT(from image: UIImage, mediaType: String, imgHei : Int, imgWid : Int,selectedQuality : Int) {
//
//        let targetSize: CGSize
//        switch selectedQuality {
//        case 0:
//            targetSize = CGSize(width: 1280, height: 720)
//        case 1:
//            targetSize = CGSize(width: 1920, height: 1080)
//        case 2:
//            targetSize = CGSize(width: 3840, height: 2160)
//        default:
//            targetSize = CGSize(width: 1280, height: 720)
//        }
//
//        let compressionQuality: CGFloat
//        switch selectedQuality {
//        case 0:
//            compressionQuality = 0.2
//        case 1:
//            compressionQuality = 0.6
//        case 2:
//            compressionQuality = 1.0
//        default:
//            compressionQuality = 0.6
//        }
//
//        let resizedImage = resizeImage(image: image, targetSize: targetSize)
//        if let compressedImageData = resizedImage.jpegData(compressionQuality: compressionQuality) {
//            let compressedURL = FileManager.default.temporaryDirectory.appendingPathComponent("compressed_image.jpg")
//            do {
//                try compressedImageData.write(to: compressedURL)
//                uploadFile(compressedURL, mediaType: mediaType, title: title, des: des, imgHei: imgHei, imgWid: imgWid)
//            } catch {
//                print("Error writing compressed image to temporary URL: \(error)")
//            }
//        } else {
//            print("Failed to compress image")
//        }
//    }
    
    func isAirPlayConnected() -> Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        return route.outputs.contains { $0.portType == .airPlay }
    }
    
    func isTVConnected() -> Bool {
        return connectedTvType != nil
    }
    
    func isAnyDeviceConnected() -> Bool {
        return isAirPlayConnected() || isTVConnected()
    }
}

extension CommonConnectionVM {
    func setTVPlaceHolder(connectedTvType: TVType){
        if connectedTvType == .ANDROID || connectedTvType == .SAMSUNG || connectedTvType == .FIRE || connectedTvType == .ROKU {
            CastMedia(url: URL(string: androidBannerUrl)!, mediaType: "image/jpeg",title: "", des: "", imgHei: 4096, imgWid: 2280)
        }
        else if connectedTvType == .LG {
            guard let asset = UIImage(named: "TVBanner") else { return }
            if let imageData = asset.jpegData(compressionQuality: 1.0) {
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileName = "Splash" + ".jpg"
                let fileURL = tempDirectory.appendingPathComponent(fileName)
                do {
                    try imageData.write(to: fileURL)
                    print("✅ Image saved temporarily at: \(fileURL)")
                    compressAndUploadImage(from: fileURL, mediaType: "image/jpeg", title: "", des: "", imgHei: 4096, imgWid: 2280, selectedQuality: 2)
                } catch {
                    print("❌ Failed to save image to temp file: \(error)")
                }
            }
        }
    }
}
