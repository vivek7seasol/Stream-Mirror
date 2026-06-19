//
//  AndroidRemoteManager.swift
//  TV Remote
//
//  Created by iOS Developer on 25/08/2025.
//

import Foundation
import Combine

class AndroidRemoteManager: ObservableObject {
    private let operationQueue = DispatchQueue(label: "operationQueue")
    
    let connectionHandler: PairManager
    private let deviceController: RemoteManager
    static var currentHost: String?
    public var connectionStateUpdated: ((String) -> ())?
    public var deviceStateUpdated: ((String) -> ())?
    var deviceIP: String = ""
    
    init() {
        let securityHandler = CryptoManager()
        
        securityHandler.clientPublicCertificate = {
            guard let url = Bundle.main.url(forResource: "cert", withExtension: "der") else {
                return .Error(.loadCertFromURLError(MyError.certNotFound))
            }
            return CertManager().getSecKey(url)
        }
        
        let encryptionHandler = TLSManager {
            guard let url = Bundle.main.url(forResource: "cert", withExtension: "p12") else {
                return .Error(.loadCertFromURLError(MyError.certNotFound))
            }
            return CertManager().cert(url, "")
        }
        
        encryptionHandler.secTrustClosure = { secTrust in
            securityHandler.serverPublicCertificate = {
                if #available(iOS 14.0, *) {
                    guard let key = SecTrustCopyKey(secTrust) else {
                        return .Error(.secTrustCopyKeyError)
                    }
                    return .Result(key)
                } else {
                    guard let key = SecTrustCopyPublicKey(secTrust) else {
                        return .Error(.secTrustCopyKeyError)
                    }
                    return .Result(key)
                }
            }
        }
        
        connectionHandler = PairManager(encryptionHandler, securityHandler, DefaultLogger())
        deviceController = RemoteManager(encryptionHandler, CommandNetwork.DeviceInfo("TV Remote", "iPhone", "1.0.0", AppStrings.appName, "235"), DefaultLogger())
    }
    
    func establishConnection(with host: String) {
        self.deviceIP = host
        AndroidRemoteManager.currentHost = host
        if ConnectedTVs.shared.isIPKnown(host) {
            pairWithOutCode(host: host)
        } else {
            pairWithCode(host: host)
        }
    }
    
    func pairWithOutCode(host: String) {
        operationQueue.async {
            self.deviceController.stateChanged = { [weak self] state in
                self?.deviceStateUpdated?(state.toString())

                if case .error(.connectionWaitingError) = state {
                    self?.connectionHandler.stateChanged = { newState in
                        self?.connectionStateUpdated?(newState.toString())

                        if case .successPaired = newState {
                            self?.deviceController.connect(host)
                        }
                    }

                    self?.connectionHandler.connect(host, AppStrings.appName, "App")
                }
            }

            self.deviceController.connect(host)
        }
    }
    
    func pairWithCode(host: String) {
        operationQueue.async {
            print("Starting connection process with client: 'client' and device: 'iPhone'")
            
            self.connectionHandler.stateChanged = { [weak self] state in
                print("Connection state updated: \(state.toString())")
                self?.connectionStateUpdated?(state.toString())
                
                if case .successPaired = state {
                    print("Connection successful. Linking DeviceController to host: \(host)")
                    
                    self?.deviceController.stateChanged = { newState in
                        print("Device state updated: \(newState.toString())")
                        self?.deviceStateUpdated?(newState.toString())
                    }
                    
                    self?.deviceController.connect(host)
                } else if case .error(let error) = state {
                    print("Connection failed with error: \(error.localizedDescription)")
                }
            }
            
            self.connectionHandler.connect(host, AppStrings.appName, "App")
        }
    }

    
    func terminateConnection() {
        connectionHandler.disconnect()
        deviceController.disconnect()
    }
    
    func submitCode(_ code: String) {
        operationQueue.async {
            self.connectionHandler.sendSecret(code)
        }
    }
    
    func launchMediaOnRemoteScreen(url: String) {
        operationQueue.async {
            self.deviceController.send(DeepLink(url))
        }
    }
    
    func launchChannel(with url: String) {
        operationQueue.async {
            self.deviceController.send(DeepLink(url))
        }
    }
    
    func adjustVolume(up: Bool) {
        operationQueue.async {
            let key = up ? Key.KEYCODE_VOLUME_UP : Key.KEYCODE_VOLUME_DOWN
            self.deviceController.send(KeyPress(key))
        }
    }
    
    func navigate(direction: Key) {
        operationQueue.async {
            self.deviceController.send(KeyPress(direction))
        }
    }
    
    func controlMedia(action: Key) {
        operationQueue.async {
            self.deviceController.send(KeyPress(action))
        }
    }
    
    func SendCommand(action: Key) {
        operationQueue.async {
            self.deviceController.send(KeyPress(action))
        }
    }
    
    func delete() {
        operationQueue.async {
            self.deviceController.send(KeyPress(.KEYCODE_DEL))
        }
    }
    
    func sendText(text: String) {
        print("text is being printing: \(text)")
        self.deviceController.sendText(text: text)
    }
    
}


public enum MyError: Error {
    case certNotFound
}

