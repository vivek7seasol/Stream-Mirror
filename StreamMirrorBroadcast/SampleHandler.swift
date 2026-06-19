//
//  SampleHandler.swift
//  StreamMirrorBroadcast
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import ReplayKit
import AVFoundation
import CoreImage
import CoreMotion

class SampleHandler: RPBroadcastSampleHandler {
    
    // MARK: - Existing Properties
//    private let maxImageSize: Int = 111 * 111
    private let maxImageSize: Int = 500 * 1024
    private var frameCount = 0
    private var videoQuality: String = "Low"
    private var serverUrl: String = ""
    private let userDefaultsSuiteName = AppStrings.groupID
    
    private let motionManager = CMMotionManager()
    private var currentOrientation: UIDeviceOrientation = .portrait

    // MARK: - Recording Properties (NEW)
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var isWritingStarted = false
    private var outputURL: URL?
    private var isMicEnabled: Bool = false
    private var shouldSaveRecording: Bool = false
    private var audioInput: AVAssetWriterInput?
//    private var appAudioInput: AVAssetWriterInput?
//    private var micAudioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var recordingSize: CGSize?
    private let ciContext = CIContext()
    private var isCameraEnabled: Bool = false
    private var broadcastMode: String = ""
    
    
    // MARK: - Broadcast Lifecycle Methods
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        print("Broadcast started.")
        updateBroadcastStatus(isBroadcasting: true)
        postDarwinNotification(name: "BROADCAST_STARTED")
        loadUserPreferences()
        startOrientationTracking()
//        if shouldSaveRecording {
//            setupVideoWriter()
//        }
    }

    override func broadcastPaused() {
        print("Broadcast paused.")
    }

    override func broadcastResumed() {
        print("Broadcast resumed.")
    }

    override func broadcastFinished() {
        print("Broadcast finished.")
        updateBroadcastStatus(isBroadcasting: false)
        postDarwinNotification(name: "BROADCAST_STOPPED")
        
        finishWriting()
    }
    
    private func startOrientationTracking() {
           guard motionManager.isAccelerometerAvailable else {
               print("Accelerometer not available.")
               return
           }
           motionManager.accelerometerUpdateInterval = 0.3
           motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
               guard let self = self, let data = data else { return }
               self.currentOrientation = self.orientation(from: data.acceleration)
           }
       }
       
       private func stopOrientationTracking() {
           motionManager.stopAccelerometerUpdates()
       }
       
       /// Derives device orientation from raw accelerometer gravity vector.
       private func orientation(from acceleration: CMAcceleration) -> UIDeviceOrientation {
           let threshold = 0.6  // tilt sensitivity
           if acceleration.z < -0.8 {
               return .faceUp
           } else if acceleration.z > 0.8 {
               return .faceDown
           } else if acceleration.x > threshold {
               return .landscapeLeft      // home button on the left
           } else if acceleration.x < -threshold {
               return .landscapeRight     // home button on the right
           } else if acceleration.y < -threshold {
               return .portrait           // home button at bottom
           } else if acceleration.y > threshold {
               return .portraitUpsideDown
           }
           return currentOrientation      // no significant change, keep previous
       }

    
    // MARK: - Sample Buffer Processing
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            handleVideoSampleBuffer(sampleBuffer)
        case .audioMic:
            if isMicEnabled {
                writeAudioSampleBuffer(sampleBuffer, input: audioInput)
            }
        case .audioApp:
            if !isMicEnabled {
                writeAudioSampleBuffer(sampleBuffer, input: audioInput)
            }
            
        @unknown default:
            fatalError("Unknown type of sample buffer")
        }
    }
    
    private func writeAudioSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        input: AVAssetWriterInput?
    ) {
        guard shouldSaveRecording else { return }
        guard let writer = assetWriter,
              let input = input else { return }

        // Sirf tab audio append karo jab session already started ho
        guard isWritingStarted else { return }

        if writer.status == .writing,
           input.isReadyForMoreMediaData {
            input.append(sampleBuffer)
        }
    }

    private func writeCompositedVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard shouldSaveRecording else { return }

        guard let writer = assetWriter,
              let input = videoInput,
              let adaptor = pixelBufferAdaptor,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        // Session always video pe start karo
        if !isWritingStarted {
            writer.startSession(atSourceTime: time)
            isWritingStarted = true
        }

        guard writer.status == .writing,
              input.isReadyForMoreMediaData,
              let pixelBufferPool = adaptor.pixelBufferPool
        else { return }

        var outputPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(
            kCFAllocatorDefault,
            pixelBufferPool,
            &outputPixelBuffer
        )

        guard let outputPixelBuffer else { return }

        var screenImage = CIImage(cvPixelBuffer: imageBuffer)

        if let userDefaults = UserDefaults(suiteName: AppStrings.groupID),
           userDefaults.bool(forKey: AppStrings.rotateMirror) == true {
            screenImage = rotateImageForOrientation(screenImage, orientation: currentOrientation)
        }

        let targetSize = recordingSize ?? CGSize(
            width: CVPixelBufferGetWidth(imageBuffer),
            height: CVPixelBufferGetHeight(imageBuffer)
        )
        var finalImage = resizeImage(screenImage, targetSize: targetSize)

        if isCameraEnabled, let cameraImage = loadLatestCameraCIImage() {

            let cameraWidth: CGFloat = 160
            let cameraHeight: CGFloat = 220
            let padding: CGFloat = 24

            let x = targetSize.width - cameraWidth - padding
            let y = targetSize.height - cameraHeight - padding

            let testBox = CIImage(color: CIColor(red: 1, green: 0, blue: 0, alpha: 1))
                .cropped(to: CGRect(x: x, y: y, width: cameraWidth, height: cameraHeight))

            finalImage = testBox.composited(over: finalImage)

            if let cameraImage = loadLatestCameraCIImage() {
                let normalizedCamera = cameraImage.transformed(
                    by: CGAffineTransform(
                        translationX: -cameraImage.extent.origin.x,
                        y: -cameraImage.extent.origin.y
                    )
                )

                let scale = max(
                    cameraWidth / normalizedCamera.extent.width,
                    cameraHeight / normalizedCamera.extent.height
                )

                let scaledCamera = normalizedCamera.transformed(
                    by: CGAffineTransform(scaleX: scale, y: scale)
                )

                let cropRect = CGRect(
                    x: (scaledCamera.extent.width - cameraWidth) / 2,
                    y: (scaledCamera.extent.height - cameraHeight) / 2,
                    width: cameraWidth,
                    height: cameraHeight
                )

                let croppedCamera = scaledCamera
                    .cropped(to: cropRect)
                    .transformed(
                        by: CGAffineTransform(
                            translationX: -cropRect.origin.x,
                            y: -cropRect.origin.y
                        )
                    )

                let positionedCamera = croppedCamera.transformed(
                    by: CGAffineTransform(translationX: x, y: y)
                )

                finalImage = positionedCamera.composited(over: finalImage)
            }
        }

        ciContext.render(
            finalImage.cropped(to: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)),
            to: outputPixelBuffer
        )

        adaptor.append(outputPixelBuffer, withPresentationTime: time)
    }
    
    private func handleVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        
        if broadcastMode == "recording" {
            
            if shouldSaveRecording {
                if assetWriter == nil,
                   let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {

                    let width = CVPixelBufferGetWidth(imageBuffer)
                    let height = CVPixelBufferGetHeight(imageBuffer)

                    recordingSize = CGSize(width: width, height: height)
                    setupVideoWriter(size: recordingSize!)
                }

                writeCompositedVideoSampleBuffer(sampleBuffer)
            }

            return
        }
        
        frameCount += 1
        
        guard frameCount % 2 == 0 else { return }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer.")
            return
        }
        
        let adjustedSize = adjustSizeForQuality(quality: videoQuality)
        
        guard let resizedPixelBuffer = resizePixelBuffer(imageBuffer, targetSize: adjustedSize) else {
            print("Failed to resize pixel buffer.")
            return
        }
        
        guard let jpegData = createJPEGData(from: resizedPixelBuffer) else {
            print("Failed to create JPEG representation.")
            return
        }
        
        if jpegData.count > maxImageSize {
            print("JPEG data exceeds max size.")
        }
        
        sendToServer(data: jpegData)
    }
    
    private func loadLatestCameraCIImage() -> CIImage? {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: userDefaultsSuiteName)
        else {
            print("Camera App Group not found")
            return nil
        }

        let url = containerURL.appendingPathComponent("latest_camera.jpg")

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("latest_camera.jpg not found")
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let image = CIImage(data: data)
        else {
            print("Camera image load failed")
            return nil
        }

        print("Camera image loaded:", image.extent)
        return image
    }
    
    // MARK: - Image Processing (UNCHANGED)

    private func adjustSizeForQuality(quality: String) -> CGSize {
        switch quality {
        case "Low":
            return CGSize(width: 1280, height: 720)
        case "Medium", "High":
            return CGSize(width: 1920, height: 1080)
        default:
            return CGSize(width: 1280, height: 720)
        }
    }
    
    private func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer, targetSize: CGSize) -> CVPixelBuffer? {
           // 1. Read latest preferences first
           if let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName) {
               videoQuality = userDefaults.string(forKey: "selectedQuality") ?? "Low"
           }
           // 2. Apply rotation based on ACTUAL device orientation
           var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        if let userDefaults = UserDefaults(suiteName: AppStrings.groupID){
               if userDefaults.bool(forKey: AppStrings.rotateMirror) == true {
                   ciImage = rotateImageForOrientation(ciImage, orientation: currentOrientation)
               }
           }
           // 3. Resize to target
           let resizedImage = resizeImage(ciImage, targetSize: targetSize)
           // 4. Render into new pixel buffer
           var resizedPixelBuffer: CVPixelBuffer?
           let status = CVPixelBufferCreate(
               kCFAllocatorDefault,
               Int(targetSize.width),
               Int(targetSize.height),
               kCVPixelFormatType_32BGRA,
               nil,
               &resizedPixelBuffer
           )
           
           guard status == kCVReturnSuccess, let buffer = resizedPixelBuffer else {
               return nil
           }
           
           CIContext().render(resizedImage, to: buffer)
           return buffer
       }

    private func rotateImageForOrientation(_ image: CIImage, orientation: UIDeviceOrientation) -> CIImage {
            let angle: CGFloat
            switch orientation {
            case .portrait:
                angle = 0      // ✅ FIXED (was wrong)
            case .portraitUpsideDown:
                angle = .pi         // ✅ FIXED
            case .landscapeLeft:
                angle = -.pi / 2       // ✅ FIXED
            case .landscapeRight:
                angle = .pi / 2   // ✅ FIXED
            case .faceUp, .faceDown, .unknown:
                return image
            @unknown default:
                return image
            }
            
            let rotated = image.transformed(by: CGAffineTransform(rotationAngle: angle))
            
            return rotated.transformed(
                by: CGAffineTransform(
                    translationX: -rotated.extent.origin.x,
                    y: -rotated.extent.origin.y
                )
            )
        }

    
    private func resizeImage(_ image: CIImage, targetSize: CGSize) -> CIImage {
           let scaleX = targetSize.width / image.extent.width
           let scaleY = targetSize.height / image.extent.height
           
           let scale = min(scaleX, scaleY)
           let resizedImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
           
           let offsetX = (targetSize.width - resizedImage.extent.width) / 2
           let offsetY = (targetSize.height - resizedImage.extent.height) / 2
           return resizedImage.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
       }

    
    private func createJPEGData(from pixelBuffer: CVPixelBuffer) -> Data? {
           let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
           let context = CIContext()
           
           var compression: CGFloat
           switch videoQuality {
           case "Low": compression = 0.3
           case "Medium": compression = 0.6
           case "High": compression = 0.9
           default: compression = 0.5
           }
           
           return context.jpegRepresentation(
               of: ciImage,
               colorSpace: CGColorSpaceCreateDeviceRGB(),
               options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: compression]
           )
       }

    
    // MARK: - Server Communication (UNCHANGED)

    private func sendToServer(data: Data) {
            guard let url = URL(string: serverUrl) else {
                print("Invalid server URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("Error sending data: \(error.localizedDescription)")
                } else if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                    print("Server returned status code \(response.statusCode)")
                } else {
                    print("Data sent successfully")
                }
            }
            
            task.resume()
        }

    
    // MARK: - Recording Logic (NEW)

    private func setupVideoWriter(size: CGSize) {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: userDefaultsSuiteName) else {
            return
        }
        
        let fileName = "recording_\(Int(Date().timeIntervalSince1970)).mp4"
        let recordingsFolder = containerURL.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: recordingsFolder, withIntermediateDirectories: true)
        
        let url = recordingsFolder.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        
        do {
            assetWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)
            outputURL = url
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(size.width),
                AVVideoHeightKey: Int(size.height),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6_000_000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true
            
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 48000,
                AVEncoderBitRateKey: 192000
            ]
            
//            appAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
//            appAudioInput?.expectsMediaDataInRealTime = true
//            
//            micAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
//            micAudioInput?.expectsMediaDataInRealTime = true
//            
            guard let writer = assetWriter else { return }
            
            if let videoInput, writer.canAdd(videoInput) {
                writer.add(videoInput)
                
                pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: videoInput,
                    sourcePixelBufferAttributes: [
                        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                        kCVPixelBufferWidthKey as String: Int(size.width),
                        kCVPixelBufferHeightKey as String: Int(size.height),
                        kCVPixelBufferIOSurfacePropertiesKey as String: [:]
                    ]
                )
            }
            
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput?.expectsMediaDataInRealTime = true

            if let audioInput, writer.canAdd(audioInput) {
                writer.add(audioInput)
            }
            
            writer.startWriting()
            
        } catch {
            print("Writer error:", error.localizedDescription)
        }
    }
    
    private func writeSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        
        guard shouldSaveRecording else { return }
        
        guard let writer = assetWriter,
              let input = videoInput else { return }
        
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if !isWritingStarted {
            writer.startSession(atSourceTime: time)
            isWritingStarted = true
        }
        
        if writer.status == .writing,
           input.isReadyForMoreMediaData {
            input.append(sampleBuffer)
        }
    }
    
    private func finishWriting() {

        videoInput?.markAsFinished()
        audioInput?.markAsFinished()

        assetWriter?.finishWriting { [weak self] in
            guard let self = self else { return }

            print("Writer Status = \(self.assetWriter?.status.rawValue ?? -1)")

            if let error = self.assetWriter?.error {
                print("Writer Error = \(error)")
            }

            if let url = self.outputURL {
                print("Video saved at: \(url)")
            }
        }
    }
    // MARK: - User Defaults (UNCHANGED)

    private func loadUserPreferences() {
            if let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName) {
                videoQuality = userDefaults.string(forKey: "selectedQuality") ?? "Low"
                print("Video Quality: \(videoQuality)")
                isMicEnabled =
                    userDefaults.bool(forKey: "recordingMicEnabled")
                isCameraEnabled = userDefaults.bool(forKey: "recordingVideoEnabled")
                broadcastMode = userDefaults.string(forKey: "broadcastMode") ?? ""
                shouldSaveRecording = userDefaults.bool(forKey: "shouldSaveRecording")
                if let urlString = userDefaults.string(forKey: AppStrings.serverUrlKey) {
                    serverUrl = urlString
                    print("Server URL: \(serverUrl)")
                } else {
                    print("No URL found in UserDefaults.")
                }
            }
        }

    
    private func updateBroadcastStatus(isBroadcasting: Bool) {
           if let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName) {
               userDefaults.set(isBroadcasting, forKey: "isBroadcasting")
               userDefaults.synchronize()
           }
       }
    
    private func postDarwinNotification(name: String) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name as CFString),
            nil,
            nil,
            true
        )
    }
}
