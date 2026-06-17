//
//  LGTVManager.swift
//  TV Remote
//
//  Created by IOS Developer on 09/09/2025.
//

import Foundation
import ConnectSDK
import Combine

class LGTVManager: NSObject {
    var selectedDevice: ConnectableDevice?
    @Published var connectionStatus = false
    @Published var availableApps: [AppInfo] = []
    @Published var isMuted = false
    var connectedDevice: ConnectableDevice?
    
    func connectLG(device: ConnectableDevice) {
        connectedDevice = device
        device.setPairingType(DeviceServicePairingTypePinCode)
        device.delegate = self
        device.connect()
    }
    
    func disconnectFromTV() {
        selectedDevice?.disconnect()
        selectedDevice = nil
        connectionStatus = false
    }
    
    func fetchInstalledApps() {
        guard let launcher = selectedDevice?.launcher() else {
            print("App launcher is not available.")
            return
        }
        launcher.getAppList(success: { [weak self] apps in
            guard let self = self, let allApps = apps as? [AppInfo] else {
                print("Failed to cast apps to [AppInfo]")
                return
            }
            
            let inputPortsOnly = allApps.filter { app in
                guard let appId = app.id?.lowercased(),
                      let appName = app.name?.lowercased() else { return false }
                
                // 1. STAGE 1: ABSOLUTE BLACKLIST (Instantly drops the remaining system noise)
                let strictExclusions = [
                    "overlay", "liveplus", "inputcommon", "plus",
                    "screensaver", "screen saver", "exampleapp", ".nav"
                ]
                if strictExclusions.contains(where: { appId.contains($0) || appName.contains($0) }) {
                    return false
                }
                
                // 2. STAGE 2: STRICT SELECTION (Isolates genuine hardware ports)
                let isHDMI = appId.contains("hdmi") || appName.contains("hdmi")
                
                // Fixed the partial string matching loop bug (.nav matching av)
                let isAV = appId.contains("externalinput.av") ||
                appId.contains("input_av") ||
                appName == "av" ||
                appName.hasPrefix("av ") ||
                appName.hasPrefix("av1") ||
                appName.hasPrefix("av2")
                
                return isHDMI || isAV
            }
            DispatchQueue.main.async {
                // Sort them cleanly so your UI reads: AV, AV1, AV2, HDMI1...
                self.availableApps = inputPortsOnly.sorted { ($0.name ?? "") < ($1.name ?? "") }
                
                print("🔌 Final Locked Count: \(self.availableApps.count)")
                print("Available Ports: \(self.availableApps.map { $0.name ?? "Unknown" }.joined(separator: ", "))")
            }
            
        }, failure: { error in
            print("Failed to fetch apps: \(error?.localizedDescription ?? "Unknown Error")")
        })
    }
    
    
    
    func sendCommand(_ key: LGRemoteKeys) {
        switch key {
        case .KEYCODE_CHANNEL_UP:
            selectedDevice?.tvControl()?.channelUp(success: { _ in
                print("Channel Up Success")},
                                                   failure: { error in
                print("Channel Up Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_CHANNEL_DOWN:
            selectedDevice?.tvControl()?.channelDown(success: { _ in
                print("Channel Down Success") },
                                                     failure: { error in
                print("Channel Down Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_VOLUME_UP:
            selectedDevice?.volumeControl()?.volumeUp(success: { _ in
                print("Volume Up Success") },
                                                      failure: { error in
                print("Volume Up Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_VOLUME_DOWN:
            selectedDevice?.volumeControl()?.volumeDown(success: { _ in
                print("Volume Down Success") },
                                                        failure: { error in
                print("Volume Down Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_MUTE:
            let newMuteState = !isMuted
            selectedDevice?.volumeControl()?.setMute(newMuteState, success: { _ in
                DispatchQueue.main.async {
                    self.isMuted = newMuteState
                }
                print(newMuteState ? "Mute Success" : "Unmute Success")
            }, failure: { error in
                print("Mute Toggle Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_POWER:
            selectedDevice?.powerControl()?.powerOff(success: { _ in
                print("Power Off Success") },
                                                     failure: { error in
                print("Power Off Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_DPAD_UP:
            selectedDevice?.keyControl()?.up(success: { _ in
                print("Navigate Up Success") },
                                             failure: { error in
                print("Navigate Up Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_DPAD_DOWN:
            selectedDevice?.keyControl()?.down(success: { _ in
                print("Navigate Down Success") },
                                               failure: { error in
                print("Navigate Down Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_DPAD_LEFT:
            selectedDevice?.keyControl()?.left(success: { _ in
                print("Navigate Left Success") },
                                               failure: { error in
                print("Navigate Left Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_DPAD_RIGHT:
            selectedDevice?.keyControl()?.right(success: { _ in
                print("Navigate Right Success") },
                                                failure: { error in
                print("Navigate Right Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_OK:
            selectedDevice?.keyControl()?.ok(success: { _ in
                print("Select (OK) Success") },
                                             failure: { error in
                print("Select (OK) Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_HOME:
            selectedDevice?.keyControl()?.home(success: { _ in
                print("Home Success") },
                                               failure: { error in
                print("Home Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_BACK:
            selectedDevice?.keyControl()?.back(success: { _ in
                print("Back Success") },
                                               failure: { error in
                print("Back Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_PLAY:
            selectedDevice?.mediaControl()?.play(success: { _ in
                print("Play Success") },
                                                 failure: { error in
                print("Play Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_PAUSE:
            selectedDevice?.mediaControl()?.pause(success: { _ in
                print("Pause Success") },
                                                  failure: { error in
                print("Pause Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_FAST_FORWARD:
            selectedDevice?.mediaControl()?.fastForward(success: { _ in
                print("Fast Forward Success") },
                                                        failure: { error in
                print("Fast Forward Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_REWIND:
            selectedDevice?.mediaControl()?.rewind(success: { _ in
                print("Rewind Success") },
                                                   failure: { error in
                print("Rewind Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_STOP:
            selectedDevice?.mediaControl()?.stop(success: { _ in
                print("Stop Success") },
                                                 failure: { error in
                print("Stop Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
            
        case .KEYCODE_BACKSPACE:
            selectedDevice?.textInputControl()?.sendDelete(success: { _ in
                print("Delete Success") },
                                                           failure: { error in
                print("Delete Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
        case .KEYCODE_MENU:
            selectedDevice?.keyControl()?.home(success: { _ in
                print("Menu Success") },
                                               failure: { error in
                print("Home Failed: \(error?.localizedDescription ?? "Unknown Error")")
            })
        }
    }
    
    func LaunchYoutube() {
        selectedDevice?.launcher()?.launchYouTube("https://www.youtube.com/", success: {_ in
            print("Back Success")
        }, failure: { error in
            print("Back Failed: \(error?.localizedDescription ?? "Unknown Error")")
        })
    }
    
    func LauchNetfliz() {
        selectedDevice?.launcher()?.launchNetflix("https://www.netflix.com/", success: {_ in
            print("Back Success")
        }, failure: { error in
            print("Back Failed: \(error?.localizedDescription ?? "Unknown Error")")
        })
    }
    
    func LauchPrime() {
        selectedDevice?.launcher()?.launchApp("amazon", success: {_ in
            print("Back Success")
        }, failure: { error in
            print("Back Failed: \(error?.localizedDescription ?? "Unknown Error")")
        })
    }
    
    func LaunchApp(url: String) {
        selectedDevice?.launcher()?.launchApp(url, success: {_ in
            print("Back Success")
        }, failure: { error in
            print("Back Failed: \(error?.localizedDescription ?? "Unknown Error")")
        })
    }
    
    func keyboard(input: String) {
        selectedDevice?.textInputControl()?.subscribeTextInputStatus { textInputStatus in
            if let status = textInputStatus {
                print("[DEBUG] Current text input status: \(status)")
                if status.isVisible {
                    
                }
            }
        } failure: { error in
            print("[DEBUG] Failed to subscribe to text input status: \(error?.localizedDescription ?? "Unknown error")")
        }
        
        selectedDevice?.textInputControl()?.sendText(input, success: { _ in
            print(input)
        }, failure: { error in
            print("[DEBUG] sendText failed with error: \(error?.localizedDescription)")
        })
    }
    
    func movePointer(dx: Float, dy: Float) {
        guard let mouse = selectedDevice?.mouseControl() else {
            print("⚠️ Mouse control not available")
            return
        }
        
        let vector = CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
        
        mouse.move(vector, success: nil, failure: { error in
            print("❌ Move failed: \(error?.localizedDescription ?? "Unknown")")
        })
    }
    
    func clickPointer() {
        guard let mouse = selectedDevice?.mouseControl() else {
            print("⚠️ Mouse control not available")
            return
        }
        
        mouse.click(success: nil, failure: { error in
            print("❌ Click failed: \(error?.localizedDescription ?? "Unknown")")
        })
    }
    
    func scrollPointer(dx: Float, dy: Float) {
        guard let mouse = selectedDevice?.mouseControl() else {
            print("⚠️ Mouse control not available")
            return
        }
        
        let vector = CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
        
        mouse.scroll(vector, success: nil, failure: { error in
            print("❌ Scroll failed: \(error?.localizedDescription ?? "Unknown")")
        })
    }
}

extension LGTVManager: ConnectableDeviceDelegate {
    func connectableDeviceReady(_ device: ConnectableDevice) {
        DispatchQueue.main.async {
            self.selectedDevice = device
            self.connectionStatus = true
            self.fetchInstalledApps()
        }
    }
    
    func connectableDeviceDisconnected(_ device: ConnectableDevice, withError error: Error?) {
        DispatchQueue.main.async {
            self.connectionStatus = false
            self.selectedDevice = nil
            print("Device disconnected: \(error?.localizedDescription ?? "No Error Info")")
        }
    }
}

