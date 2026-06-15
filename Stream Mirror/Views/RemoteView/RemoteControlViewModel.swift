//
//  RemoteVM.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 11/05/26.
//

import Foundation
import Combine
import AVFoundation
import Speech
import UIKit

class RemoteControlViewModel: ObservableObject {
    
    @Published var showConnectionView = false
    @Published var showPremiumView = false
    
    @Published var showNumberPadSheet: Bool = false
    @Published var selectedTab: Int = 1
    @Published var keyboardText: String = ""
    @Published var showKeyboardField = false
    @Published var isRecording = false
    @Published var recognizedText: String = ""
    @Published var showRecognizedView: Bool = false
    @Published var showAirPlayAlert = false
    @Published var lastPoint: CGPoint = .zero
    @Published var lastTime: TimeInterval = 0
    @Published var isDragging = false
    @Published var showMicPermissionAlert = false
    @Published var showSpeechPermissionAlert = false
    @Published var micPermissionDeniedPermanently = false
    
    var previousTextInput: String = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    let channels: [TVApps] = [
        .youtube, .netflix, .prime
    ]
    
    // MARK: - Keyboard Text Input
    
    func showKeyboard() {
        showKeyboardField = true
    }

    func hideKeyboard() {
        showKeyboardField = false
        keyboardText = ""
        previousTextInput = ""
    }
    
    func handleTextChange(_ newValue: String, tvVM: RemoteViewModel) {
        
        if newValue.count < previousTextInput.count {
            
            switch tvVM.connectedTVType {
            case .ROKU:
                (tvVM.currentTVManager as? RokuTVManager)?.sendKeyboardInput("")
                
            case .FIRE:
                (tvVM.currentTVManager as? FireTVManager)?
                    .PerformKeyPress(keyAction: .KEYCODE_BACKSPACE)
                
            case .LG:
                (tvVM.currentTVManager as? LGTVManager)?
                    .sendCommand(.KEYCODE_BACKSPACE)
                
            case .ANDROID:
                (tvVM.currentTVManager as? AndroidTVManager)?
                    .delete()
                
            default:
                break
            }
            
        } else if let lastChar = newValue.last {
            
            let char = String(lastChar)
            
            switch tvVM.connectedTVType {
            case .ROKU:
                (tvVM.currentTVManager as? RokuTVManager)?
                    .sendKeyboardInput(char)
                
            case .FIRE:
                (tvVM.currentTVManager as? FireTVManager)?
                    .sendSearchTextInput(action: char) { _ in }
                
            case .LG:
                (tvVM.currentTVManager as? LGTVManager)?
                    .keyboard(input: char)
                
            case .ANDROID:
                (tvVM.currentTVManager as? AndroidTVManager)?
                    .sendText(text: char)
                
            default:
                break
            }
        }
        
        previousTextInput = newValue
    }
    
    // MARK: - Mic Actions
    
    func micTouchDown() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioSession.sharedInstance().recordPermission
        
        if speechStatus == .authorized && micStatus == .granted {
            startLiveRecognition()
            return
        }
        
        if speechStatus == .denied || micStatus == .denied {
            DispatchQueue.main.async {
                self.micPermissionDeniedPermanently = true
                self.showMicPermissionAlert = true
            }
            return
        }
        
        // First time request
        requestMicPermissionAndStart()
    }
    
    func micTouchUp(tvVM: RemoteViewModel) {
        stopRecording(tvVM: tvVM)
    }
    
    // MARK: - Live Speech Recognition
    
    func startLiveRecognition() {
        if audioEngine.isRunning { return }
        
        DispatchQueue.main.async {
            self.isRecording = true
            self.recognizedText = "Listening..."
            self.showRecognizedView = true
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(
                .record,
                mode: .measurement,
                options: [.mixWithOthers]
            )
            try session.setActive(true, options: [])
        } catch {
            print("Audio session error:", error)
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest else {
            stopLiveRecognition()
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            
            if let result = result {
                let text = result.bestTranscription.formattedString
                
                DispatchQueue.main.async {
                    self.recognizedText = text.isEmpty ? "Listening..." : text
                    self.showRecognizedView = true
                }
            }
            
            if error != nil {
                self.stopLiveRecognition()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine error:", error)
            stopLiveRecognition()
        }
    }
    
    func stopRecording(tvVM: RemoteViewModel) {
        stopLiveRecognition()
        
        let finalText = recognizedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !finalText.isEmpty && finalText != "Listening..." {
            tvVM.handleVoiceCommands(finalText)
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showRecognizedView = false
            }
        }
    }
    
    func stopLiveRecognition() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: [.notifyOthersOnDeactivation]
            )
        } catch {
            print("Audio session deactivate error:", error)
        }
    }
    
    // MARK: - Send Voice Text To TV
    
    private func sendRecognizedTextToTV(_ text: String, tvVM: RemoteViewModel) {
        
        switch tvVM.connectedTVType {
        case .ROKU:
            (tvVM.currentTVManager as? RokuTVManager)?
                .sendKeyboardInput(text)
            
        case .FIRE:
            (tvVM.currentTVManager as? FireTVManager)?
                .sendSearchTextInput(action: text) { _ in }
            
        case .LG:
            (tvVM.currentTVManager as? LGTVManager)?
                .keyboard(input: text)
            
        case .ANDROID:
            (tvVM.currentTVManager as? AndroidTVManager)?
                .sendText(text: text)
            
        default:
            break
        }
    }
    
    // MARK: - Permissions
    
    func requestMicPermissionAndStart() {
        
        let session = AVAudioSession.sharedInstance()
        
        switch session.recordPermission {
            
        case .granted:
            
            requestSpeechPermission()
            
        case .denied:
            
            DispatchQueue.main.async {
                self.showMicPermissionAlert = true
            }
            
        case .undetermined:
            
            session.requestRecordPermission { granted in
                
                DispatchQueue.main.async {
                    
                    if granted {
                        self.requestSpeechPermission()
                    } else {
                        self.showMicPermissionAlert = true
                    }
                }
            }
            
        @unknown default:
            break
        }
    }
    
    func requestSpeechPermission() {
        
        SFSpeechRecognizer.requestAuthorization { status in
            
            DispatchQueue.main.async {
                
                switch status {
                    
                case .authorized:
                    
                    self.startLiveRecognition()
                    self.isRecording = true
                    
                case .denied, .restricted:
                    
                    self.showSpeechPermissionAlert = true
                    
                case .notDetermined:
                    break
                    
                @unknown default:
                    break
                }
            }
        }
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        
        UIApplication.shared.open(url)
    }
    
    deinit {
        stopLiveRecognition()
    }
    
}
