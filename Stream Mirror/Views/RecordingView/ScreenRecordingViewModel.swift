//
//  RecordingVM.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 11/05/26.
//

import Foundation
import Combine
import ReplayKit

struct RecordingItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let date: Date
}

class ScreenRecordingViewModel: ObservableObject {
    @Published var showConnectionView = false
    @Published var showRecordingList = false
    @Published var showDeviceList = false
    
    @Published var isVideo: Bool = true
    @Published var isMicroPhone: Bool = true
    @Published var broadcastSessionManager: BroadCastPickerManager?
    
    @Published var startMirroring = false
    @Published var showAirPlayAlert = false
    @Published var isRecording: Bool = false
    @Published var recordings: [RecordingItem] = []
    @Published var selectedRecording: RecordingItem?
    @Published var shareItem: ShareItem?
    @Published var showPreview = false
    @Published var recordingTime: String = "00:00:00"
    @Published var isWaitingForBroadcast = false
    
    private var timer: Timer?
    private var waitingTimer: Timer?  // ← YEH ADD KARO
    private let defaults = UserDefaults(suiteName: AppStrings.groupID)
    private let recordingStartDateKey = "recordingStartDate"
    private let broadcastKey = "isRecordingBroadcasting"
    
    init() {
        checkBroadcastStatus()
        loadScreenRecordings()
    }
    
    deinit {
        timer?.invalidate()
        waitingTimer?.invalidate() 
    }
    
    func checkBroadcastStatus() {
        let isBroadcasting = defaults?.bool(forKey: "isBroadcasting") ?? false
        let isRecordingSession = defaults?.bool(forKey: "shouldSaveRecording") ?? false
        
        // Sirf tab recording maano jab dono true hon
        let status = isBroadcasting && isRecordingSession
        
        if status {
            if defaults?.object(forKey: recordingStartDateKey) == nil {
                defaults?.set(Date(), forKey: recordingStartDateKey)
            }
            
            isRecording = true
            startRecordingTimer()
            updateRecordingTimer()
        } else {
            isRecording = false
            stopTimer()
            recordingTime = "00:00:00"
            defaults?.removeObject(forKey: recordingStartDateKey)
        }
    }
    
    func toggleRecording() {
        if isRecording {
            // Stop recording
            openBroadcastPicker()
            isWaitingForBroadcast = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.checkBroadcastStatus()
            }
        } else {
            // Start recording - polling shuru karo
            isWaitingForBroadcast = true
            openBroadcastPicker()
            startWaitingForBroadcastPoll()
        }
    }

    private func startWaitingForBroadcastPoll() {
        var attempts = 0
        let maxAttempts = 15 // 15 seconds tak wait karega
        
        // Pehle existing timer band karo
        waitingTimer?.invalidate()
        
        waitingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            
            attempts += 1
            let status = self.defaults?.bool(forKey: self.broadcastKey) ?? false
            
            if status {
                // Broadcast shuru ho gaya!
                t.invalidate()
                self.waitingTimer = nil
                Task { @MainActor in
                    self.isWaitingForBroadcast = false
                    self.checkBroadcastStatus()
                }
            } else if attempts >= maxAttempts {
                // Timeout - user ne cancel kiya hoga
                t.invalidate()
                self.waitingTimer = nil
                Task { @MainActor in
                    self.isWaitingForBroadcast = false
                }
            }
        }
    }
    
    private func startRecordingTimer() {
        timer?.invalidate()
        updateRecordingTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.updateRecordingTimer()
                self.checkOnlyBroadcastStatus()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func recordingsFolderURL() -> URL? {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppStrings.groupID) else {
            return nil
        }
        
        let folderURL = containerURL.appendingPathComponent("Recordings", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        return folderURL
    }
    
    func loadScreenRecordings() {
        guard let folder = recordingsFolderURL() else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.creationDateKey]
            )
            
            let items: [RecordingItem] = files.compactMap { url in
                let values = try? url.resourceValues(forKeys: [.creationDateKey])
                
                return RecordingItem(
                    url: url,
                    name: url.lastPathComponent,
                    date: values?.creationDate ?? Date()
                )
            }
            
            recordings = items
                .sorted(by: { $0.date > $1.date })
                .map { $0 }
            
        } catch {
            print("Fetch error:", error)
        }
    }
        
    private func openBroadcastPicker() {
        let picker = RPSystemBroadcastPickerView()
        picker.preferredExtension = AppStrings.appExtensionPackageName
        picker.showsMicrophoneButton = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for subview in picker.subviews {
                if let button = subview as? UIButton {
                    button.sendActions(for: .touchUpInside)
                }
            }
        }
    }
    
    func deleteRecording(_ item: RecordingItem) {

        do {

            try FileManager.default.removeItem(at: item.url)

            DispatchQueue.main.async {

                self.recordings.removeAll {
                    $0.id == item.id
                }
            }

        } catch {

            print("Delete error:", error)
        }
    }
    
    private func updateRecordingTimer() {
           guard let startDate = defaults?.object(forKey: recordingStartDateKey) as? Date else {
               recordingTime = "00:00:00"
               return
           }
           
           let elapsed = max(0, Int(Date().timeIntervalSince(startDate)))
           let hours = elapsed / 3600
           let minutes = (elapsed % 3600) / 60
           let seconds = elapsed % 60
           
           recordingTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
       }
       
       private func checkOnlyBroadcastStatus() {
           let status = defaults?.bool(forKey: broadcastKey) ?? false
           
           if status != isRecording {
               checkBroadcastStatus()
           }
       }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}
