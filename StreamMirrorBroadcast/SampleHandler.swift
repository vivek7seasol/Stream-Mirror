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
    
    // MARK: - Broadcast Lifecycle Methods
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        print("Broadcast started.")
        updateBroadcastStatus(isBroadcasting: true)
        postDarwinNotification(name: "BROADCAST_STARTED")
        loadUserPreferences()
        startOrientationTracking()
        if shouldSaveRecording {
            setupVideoWriter()
        }
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
        case .audioApp, .audioMic:
            break
        @unknown default:
            fatalError("Unknown type of sample buffer")
        }
    }
    
    private func handleVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        
        frameCount += 1
        
        // ✅ ADD THIS LINE
        writeSampleBuffer(sampleBuffer)
        
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

    private func setupVideoWriter() {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: userDefaultsSuiteName) else {
            print("App Group not found")
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
            
            let settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 720,
                AVVideoHeightKey: 1280
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            videoInput?.expectsMediaDataInRealTime = true
            
            if let writer = assetWriter,
               let input = videoInput,
               writer.canAdd(input) {
                writer.add(input)
            }
            
            assetWriter?.startWriting()
            print("Recording started: \(url)")
            
        } catch {
            print("Writer error: \(error)")
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
        
        assetWriter?.finishWriting { [weak self] in
            guard let self = self else { return }
            
            if let url = self.outputURL {
                print("Video saved at: \(url)")
                
                // Save filename for app access
                if let userDefaults = UserDefaults(suiteName: self.userDefaultsSuiteName) {
                    userDefaults.set(url.lastPathComponent, forKey: "lastRecording")
                }
            }
        }
    }
    
    // MARK: - User Defaults (UNCHANGED)

    private func loadUserPreferences() {
            if let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName) {
                videoQuality = userDefaults.string(forKey: "selectedQuality") ?? "Low"
                print("Video Quality: \(videoQuality)")
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
