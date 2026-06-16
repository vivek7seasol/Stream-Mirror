//
//  CameraManager.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 16/06/26.
//

import Foundation
import SwiftUI
import AVFoundation
import Combine

struct CameraPreview: UIViewRepresentable {
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) { }
}

class PreviewView: UIView {
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

final class CameraPreviewManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    
    let session = AVCaptureSession()
    
    private let output = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    
    @Published var isFlashOn = false
    
    private var currentPosition: AVCaptureDevice.Position = .back
    
    func setupCamera(position: AVCaptureDevice.Position) {
        
        session.beginConfiguration()
        
        session.sessionPreset = .photo
        
        // Remove Old Inputs
        session.inputs.forEach { session.removeInput($0) }
        
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: position
        ) else {
            return
        }
        
        do {
            
            let input = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(input) {
                session.addInput(input)
                currentInput = input
            }
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            session.commitConfiguration()
            
            currentPosition = position
            
            DispatchQueue.global(qos: .background).async {
                
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            }
            
        } catch {
            print("❌ Camera Setup Error:", error.localizedDescription)
        }
    }
    
    func switchCamera() {
        
        currentPosition = currentPosition == .back ? .front : .back
        setupCamera(position: currentPosition)
    }
    
    func toggleFlash() {
        
        isFlashOn.toggle()
    }
    
    func capturePhoto() {
        
        let settings = AVCapturePhotoSettings()
        
        settings.flashMode = isFlashOn ? .on : .off
        
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(
            UIImage(data: imageData)!,
            nil,
            nil,
            nil
        )
        
        print("✅ Photo Saved")
    }
}
