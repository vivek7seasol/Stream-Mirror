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
    @Published var showPremiumView = false
    @Published var showDeviceList = false
    @Published var showRecordingList = false
    
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
    var recordingStatusText: String {
        if isRecording {
            return str.RecordinginProgress
        } else if isWaitingForBroadcast {
            return "Waiting for confirmation..."
        } else {
            return str.ReadytoRecord
        }
    }
    
    private var timer: Timer?
    private let defaults = UserDefaults(suiteName: AppStrings.groupID)
    private let broadcastKey = "isRecordingBroadcasting"
    private let recordingStartDateKey = "recordingStartDate"
    
    init() {
        checkBroadcastStatus()
        loadScreenRecordings()
        registerForBroadcastNotifications() // ← Add this
    }
    
    deinit {
        timer?.invalidate()
        removeBroadcastNotifications() // ← Add this
    }
    
    // MARK: - Darwin Notification Listener

    private func registerForBroadcastNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let selfPtr = Unmanaged.passRetained(self).toOpaque()

        let callback: CFNotificationCallback = { _, observer, _, _, _ in
            guard let observer else { return }
            let vm = Unmanaged<ScreenRecordingViewModel>
                .fromOpaque(observer)
                .takeUnretainedValue()
            DispatchQueue.main.async {
                vm.checkBroadcastStatus()
                vm.loadScreenRecordings()
            }
        }

        CFNotificationCenterAddObserver(
            center, selfPtr, callback,
            "BROADCAST_STARTED" as CFString,
            nil, .deliverImmediately
        )

        CFNotificationCenterAddObserver(
            center, selfPtr, callback,
            "BROADCAST_STOPPED" as CFString,
            nil, .deliverImmediately
        )
    }

    private func removeBroadcastNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterRemoveEveryObserver(center, selfPtr)
    }
    
    func checkBroadcastStatus() {
        let status = defaults?.bool(forKey: broadcastKey) ?? false

        if status {
            isWaitingForBroadcast = false  // ← Add this
            if defaults?.object(forKey: recordingStartDateKey) == nil {
                defaults?.set(Date(), forKey: recordingStartDateKey)
            }
            isRecording = true
            startTimer()
            updateRecordingTime()
        } else {
            isWaitingForBroadcast = false  // ← Add this
            isRecording = false
            stopTimer()
            recordingTime = "00:00:00"
            defaults?.removeObject(forKey: recordingStartDateKey)
        }
    }
    
    private func checkOnlyBroadcastStatus() {
        
        let status = defaults?.bool(forKey: broadcastKey) ?? false
        
        let mode =
        defaults?.string(forKey: "broadcastMode") ?? ""
        
        let isRealRecording =
        status &&
        mode == "recording"
        
        if isRealRecording != isRecording {
            checkBroadcastStatus()
        }
    }
    
    func toggleRecording() {
        if !isRecording {
            isWaitingForBroadcast = true  // ← "Waiting for confirmation..." dikhega
        }
        openSystemBroadcastPicker()

        // Fallback polls (agar Darwin notification miss ho)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.checkBroadcastStatus()
            self.loadScreenRecordings()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isWaitingForBroadcast = false
            self.checkBroadcastStatus()
            self.loadScreenRecordings()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        updateRecordingTime()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.updateRecordingTime()
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
                .prefix(3)
                .map { $0 }
            
        } catch {
            print("Fetch error:", error)
        }
    }
    
    private func openSystemBroadcastPicker() {
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
    
    private func updateRecordingTime() {
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
    
}
struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}
