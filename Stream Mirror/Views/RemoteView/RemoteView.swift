//
//  RemoteView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

enum ControlType: CaseIterable {
    case remote, touchpad, mouse, keyboard

    var icon: String {
        switch self {
        case .remote: return "remote"
        case .touchpad: return "touchpad"
        case .mouse: return "mouse"
        case .keyboard: return "keyboard"
        }
    }
}
struct RemoteView: View {
    
    @EnvironmentObject var tabBarManager: TabBarManager
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var viewModel = RemoteControlViewModel()
    @State private var controlType: ControlType = .remote
    @State private var text: String = ""
    @Binding var showChannelView: Bool
    @Binding var showNumberPad: Bool
    @Binding var showDeviceList: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing:isIpad() ? 25 : 15){
                HStack {
                    Button {
                        showDeviceList = true
                    } label: {
                        
                        ZStack {
                            HStack {
                                Image("dot")
                                    .resizable()
                                    .frame(width: isIpad() ? 12 : 8,height:  isIpad() ? 12 : 8)
                                    .foregroundStyle(TVRemoteVM.connectedTVType != nil ? Color("#32F68C") : Color("#EF4444"))
                                
                                Text(((TVRemoteVM.connectedTVType != nil) ? TVRemoteVM.deviceName : str.ConnectTv) ?? "")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal,15)
                        .frame(height: isIpad() ? 50 : 42)
                        .modifier(GlassCardModifier(cornerRadius: isIpad() ? 25 : 21))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    Button {
                        handleDeviceSatus {
                            TVRemoteVM.sendCommand(.POWER)
                        }
                    } label: {
                        Image("power")
                            .resizable()
                            .frame(width: isIpad() ? 75 : 56,height:  isIpad() ? 75 : 56)
                    }

                }
                .padding(.horizontal,15)
                
                ZStack {
                    ControlBtn(selectedType: $controlType)
                        .padding(.horizontal, 25)
                }
                .padding(.vertical,10)
                
                Group {
                    if controlType == .remote {
                        controlTypeCard(
                            upAction: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.DPAD_UP)
                                }
                            },
                            downAction: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.DPAD_DOWN)
                                }
                            },
                            leftAction: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.DPAD_LEFT)
                                }
                            },
                            rightAction: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.DPAD_RIGHT)
                                }
                            },
                            okAction: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.OK)
                                }
                            }
                        )
                    } else if controlType == .touchpad {
                        touchPadView(
                            viewModel: viewModel, onSwipeUp: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.DPAD_UP)
                                }
                            },
                            onSwipeDown: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.DPAD_DOWN)
                                }
                            },
                            onSwipeLeft: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.DPAD_LEFT)
                                }
                            },
                            onSwipeRight: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.DPAD_RIGHT)
                                }
                            },
                            onTap: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.OK)
                                }
                            }
                        )
                    } else if controlType == .mouse {
                        mouseView(
                            viewModel: viewModel, onMouseMove: { dx, dy, dt in
                                handleDeviceSatus {
                                    sendMovement(dx: dx, dy: dy, dt: dt)
                                }
                            },
                            onMouseTap: {
                                handleDeviceSatus {
                                    TVRemoteVM.sendCommand(.OK)
                                }
                            }
                        )
                    } else if controlType == .keyboard {
                        KeyboardView(viewModel: viewModel, TVRemoteVM: TVRemoteVM, text: $text)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: controlType)
                
                HStack(spacing: isIpad() ? 40 : 20) {
                    
                    VolChButtonCard(image1: "plus", image2: "minus", title: str.VOL, action1: {
                        handleDeviceSatus {
                            TVRemoteVM.sendCommand(.VOLUMEUP)
                        }
                    }, action2: {
                        handleDeviceSatus {
                            TVRemoteVM.sendCommand(.VOLUMEDOWN)
                        }
                    })
                    
                    VStack(spacing:20) {
                        CircleButton(icon: "home2",size: 30,size2: 66, action: {
                            handleDeviceSatus {
                                TVRemoteVM.sendCommand(.HOME)
                            }
                        })
                        
                        CircleButton(icon: "mic",size: 30,size2: 66, action: {
                            
                        })
                    }
                    
                    VStack(spacing:20) {
                        CircleButton(icon: "mute",size: 30,size2: 66, action: {
                            handleDeviceSatus {
                                TVRemoteVM.sendCommand(.MUTE)
                            }
                        })
                        
                        CircleButton(icon: "setting",size: 30,size2: 66, action: {
                            handleDeviceSatus {
                                TVRemoteVM.sendCommand(.SETTINGS)
                            }
                        })
                    }
                    
                    VolChButtonCard(image1: "chevron.up", image2: "chevron.down", title: str.CH, action1: {
                        handleDeviceSatus {
                            TVRemoteVM.sendCommand(.CHANNELUP)
                        }
                    }, action2: {
                        handleDeviceSatus {
                            TVRemoteVM.sendCommand(.CHANNELDOWN)
                        }
                    })
                    
                }
                .padding(.horizontal,15)
                
                HStack(spacing: isIpad() ? 40 : 20) {
                    
                    CircleButton(icon: "back2",size: 30,size2: 66, action: {
                        handleDeviceSatus {
                            TVRemoteVM.sendCommand(.BACK)
                        }
                    })
                    
                    Button {
                        handleDeviceSatus {
                            showNumberPad = true
                        }
                    } label: {
                        ZStack {
                            Text("123")
                                .foregroundStyle(.white)
                                .font(.system(size:isIpad() ? 26 : 20,weight: .medium))
                        }
                        .padding(.horizontal,30)
                        .frame(height:isIpad() ? 67 : 66)
                        .modifier(GlassCardModifier(cornerRadius:isIpad() ? 38 : 33))
                        .clipShape(RoundedRectangle(cornerRadius:isIpad() ? 38 : 33))
                    }
                    .buttonStyle(.plain)
                    
                    
                    CircleButton(icon: "channel2", size: 30, size2: 66) {
                        handleDeviceSatus {
                            showChannelView = true
                        }
                    }
                    
                }
                .padding(.horizontal,15)
                .padding(.vertical,10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreen()
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func sendMovement(dx: CGFloat, dy: CGFloat, dt: TimeInterval) {
        let vx = dt > 0 ? dx / dt : 0
        let vy = dt > 0 ? dy / dt : 0
        
        let finalDX = Float((dx * 1.5) + (vx * 0.01))
        let finalDY = Float((dy * 1.5) + (vy * 0.01))
        
        switch TVRemoteVM.connectedTVType {
            
        case .LG:
            TVRemoteVM.moveCursor(dx: finalDX, dy: finalDY)
            
        case .SAMSUNG:
            TVRemoteVM.moveCursor(dx: finalDX, dy: finalDY)
            
        default:
            handleFallbackDPAD(dx: dx, dy: dy)
        }
    }
    
    private func handleFallbackDPAD(dx: CGFloat, dy: CGFloat) {
        
        let threshold: CGFloat = 8
        
        if abs(dx) > abs(dy) {
            if dx > threshold {
                TVRemoteVM.sendCommand(.DPAD_RIGHT)
            } else if dx < -threshold {
                TVRemoteVM.sendCommand(.DPAD_LEFT)
            }
        } else {
            if dy > threshold {
                TVRemoteVM.sendCommand(.DPAD_DOWN)
            } else if dy < -threshold {
                TVRemoteVM.sendCommand(.DPAD_UP)
            }
        }
    }
    
    func handleDeviceSatus(_ action: () -> Void) {
//        if isPro == true {
            if TVRemoteVM.connectedTVType == nil {
                
                showDeviceList = true
                return
            }
            
            action()
//        } else {
//            showPremium = true
//        }
    }
}

#Preview {
    RemoteView(showChannelView: .constant(false), showNumberPad: .constant(false), showDeviceList: .constant(false))
        .environmentObject(CommonConnectionViewModel())
        .environmentObject(RemoteViewModel())
}
