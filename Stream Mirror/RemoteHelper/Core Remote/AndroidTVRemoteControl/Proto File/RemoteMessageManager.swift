//
//  RemoteMessageManager.swift
//  TV Remote
//
//  Created by iOS Developer on 27/08/2025.
//


import Foundation
import SwiftProtobuf

class RemoteMessageManager {
    private var manufacturer: String = ""
    private var model: String = ""
    
    init() {
        getSystemInfo()
    }
    
    private func getSystemInfo() {
        let device = ProcessInfo.processInfo.hostName
        self.model = device
        self.manufacturer = "Apple"
    }
    
    func create(payload: Remote_RemoteMessage) throws -> Data {
        if !payload.hasRemotePingResponse {
            print("Create Remote \(payload)")
        }
        
        do {
            var message: any Message = payload
            var data = Data()
            try data.appendDelimited(message: &message)
            
            print("Size of message: \(data.count)")
            if !payload.hasRemotePingResponse {
                print("Sending \(payload)")
            }
            
            return data
        } catch {
            throw error
        }
    }
    
    func createRemoteConfigure() throws -> Data {
        var deviceInfo = Remote_RemoteDeviceInfo()
        deviceInfo.model = self.model
        deviceInfo.vendor = self.manufacturer
        deviceInfo.unknown1 = 1
        deviceInfo.unknown2 = "1"
        deviceInfo.packageName = "androidtv-remote"
        deviceInfo.appVersion = "1.0.0"
        
        var remoteConfigure = Remote_RemoteConfigure()
        remoteConfigure.code1 = 622
        remoteConfigure.deviceInfo = deviceInfo
        
        var message = Remote_RemoteMessage()
        message.remoteConfigure = remoteConfigure
        
        return try create(payload: message)
    }
    
    func createRemoteSetActive(active: Int) throws -> Data {
        var remoteSetActive = Remote_RemoteSetActive()
        remoteSetActive.active = Int32(active)
        
        var message = Remote_RemoteMessage()
        message.remoteSetActive = remoteSetActive
        
        return try create(payload: message)
    }
    
    func createRemotePingResponse(val1: Int32) throws -> Data {
        var remotePingResponse = Remote_RemotePingResponse()
        remotePingResponse.val1 = val1
        
        var message = Remote_RemoteMessage()
        message.remotePingResponse = remotePingResponse
        
        return try create(payload: message)
    }
    
    func createRemoteKeyInject(direction: Remote_RemoteDirection, keyCode: Remote_RemoteKeyCode) throws -> Data {
        var remoteKeyInject = Remote_RemoteKeyInject()
        remoteKeyInject.keyCode = keyCode
        remoteKeyInject.direction = direction
        
        var message = Remote_RemoteMessage()
        message.remoteKeyInject = remoteKeyInject
        
        return try create(payload: message)
    }
    
    func createRemoteAdjustVolumeLevel(level: Remote_RemoteAdjustVolumeLevel) throws -> Data {
        var message = Remote_RemoteMessage()
        message.remoteAdjustVolumeLevel = level
        
        return try create(payload: message)
    }
    
    func createRemoteResetPreferredAudioDevice() throws -> Data {
        var message = Remote_RemoteMessage()
        message.remoteResetPreferredAudioDevice = Remote_RemoteResetPreferredAudioDevice()
        
        return try create(payload: message)
    }
    
    func createRemoteImeKeyInject(appPackage: String, status: Remote_RemoteTextFieldStatus) throws -> Data {
        var appInfo = Remote_RemoteAppInfo()
        appInfo.appPackage = appPackage
        
        var remoteImeKeyInject = Remote_RemoteImeKeyInject()
        remoteImeKeyInject.textFieldStatus = status
        remoteImeKeyInject.appInfo = appInfo
        
        var message = Remote_RemoteMessage()
        message.remoteImeKeyInject = remoteImeKeyInject
        
        return try create(payload: message)
    }
    
    func createRemoteAppLinkLaunchRequest(app_link: String) throws -> Data {
        var remoteAppLinkLaunchRequest = Remote_RemoteAppLinkLaunchRequest()
        remoteAppLinkLaunchRequest.appLink = app_link
        
        var message = Remote_RemoteMessage()
        message.remoteAppLinkLaunchRequest = remoteAppLinkLaunchRequest
        
        return try create(payload: message)
    }
    
    func createRemoteImeBatchEdit(text: String, imeCounter: Int32, fieldCounter: Int32) throws -> Data {
        // Create the text field status
        var textFieldStatus = Remote_RemoteImeObject()
        textFieldStatus.start = Int32(text.count - 1)
        textFieldStatus.end = Int32(text.count - 1)
        textFieldStatus.value = text
        
        // Create the edit info
        var editInfo = Remote_RemoteEditInfo()
        editInfo.insert = 0
        editInfo.textFieldStatus = textFieldStatus
        
        // Create the batch edit message
        var remoteImeBatchEdit = Remote_RemoteImeBatchEdit()
        remoteImeBatchEdit.imeCounter = imeCounter
        remoteImeBatchEdit.fieldCounter = fieldCounter
        remoteImeBatchEdit.editInfo = [editInfo]
        
        // Create the main message
        var message = Remote_RemoteMessage()
        message.remoteImeBatchEdit = remoteImeBatchEdit
        
        return try create(payload: message)
    }

    func createRemoteVoiceBegin(sessionID: Int32) throws -> Data {
        var begin = Remote_RemoteVoiceBegin()
        begin.sessionID = sessionID

        var message = Remote_RemoteMessage()
        message.remoteVoiceBegin = begin
        return try create(payload: message)
    }

    func createRemoteVoicePayload(sessionID: Int32, audioData: Data) throws -> Data {
        var payload = Remote_RemoteVoicePayload()
        payload.sessionID = sessionID
        payload.voicePayload = audioData

        var message = Remote_RemoteMessage()
        message.remoteVoicePayload = payload
        return try create(payload: message)
    }
    
    func createRemoteVoiceEnd(sessionID: Int32) throws -> Data {
        var end = Remote_RemoteVoiceEnd()
        end.sessionID = sessionID

        var message = Remote_RemoteMessage()
        message.remoteVoiceEnd = end
        return try create(payload: message)
    }
    
    func parse(data: Data) throws -> Remote_RemoteMessage {
        let message = try Remote_RemoteMessage(serializedData: data)
        return message
    }
}

extension Data {
    mutating func appendVarint(_ value: UInt64) {
        var val = value
        while val >= 0x80 {
            self.append(UInt8(val & 0x7F | 0x80))
            val >>= 7
        }
        self.append(UInt8(val))
    }

    mutating func appendDelimited(message: inout Message) throws {
        let serialized = try message.serializedData()
        self.appendVarint(UInt64(serialized.count))
        self.append(serialized)
    }
}
