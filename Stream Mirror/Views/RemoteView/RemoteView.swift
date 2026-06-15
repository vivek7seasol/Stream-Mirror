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
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    
    @State private var controlType: ControlType = .remote
    @State private var text: String = ""
    
    var body: some View {
        ZStack {
            VStack(spacing:isIpad() ? 25 : 15){
                HStack {
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
                    Spacer()
                    Button {
                        TVRemoteVM.sendCommand(.POWER)
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
                                TVRemoteVM.sendCommand(.DPAD_UP)
                            },
                            downAction: {
                                TVRemoteVM.sendCommand(.DPAD_DOWN)
                            },
                            leftAction: {
                                TVRemoteVM.sendCommand(.DPAD_LEFT)
                            },
                            rightAction: {
                                TVRemoteVM.sendCommand(.DPAD_RIGHT)
                            },
                            okAction: {
                                TVRemoteVM.sendCommand(.OK)
                            }
                        )
                    } else if controlType == .touchpad {
                        touchPadView(
                            onSwipeUp: {
                                TVRemoteVM.sendCommand(.DPAD_UP)
                            },
                            onSwipeDown: {
                                TVRemoteVM.sendCommand(.DPAD_DOWN)
                            },
                            onSwipeLeft: {
                                TVRemoteVM.sendCommand(.DPAD_LEFT)
                            },
                            onSwipeRight: {
                                TVRemoteVM.sendCommand(.DPAD_RIGHT)
                            },
                            onTap: {
                                TVRemoteVM.sendCommand(.OK)
                            }
                        )
                    } else if controlType == .mouse {
                        mouseView()
                    } else if controlType == .keyboard {
                        KeyboardView(text: $text)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: controlType)
                
                HStack(spacing: isIpad() ? 40 : 20) {
                    
                    VolChButtonCard(image1: "plus", image2: "minus", title: str.VOL, action1: {
                        TVRemoteVM.sendCommand(.VOLUMEUP)
                    }, action2: {
                        TVRemoteVM.sendCommand(.VOLUMEDOWN)
                    })
                    
                    VStack(spacing:20) {
                        CircleButton(icon: "home2",size: 30,size2: 66, action: {
                            TVRemoteVM.sendCommand(.HOME)
                        })
                        
                        CircleButton(icon: "mic",size: 30,size2: 66, action: {
                            
                        })
                    }
                    
                    VStack(spacing:20) {
                        CircleButton(icon: "mute",size: 30,size2: 66, action: {
                            TVRemoteVM.sendCommand(.MUTE)
                        })
                        
                        CircleButton(icon: "setting",size: 30,size2: 66, action: {
                            TVRemoteVM.sendCommand(.SETTINGS)
                        })
                    }
                    
                    VolChButtonCard(image1: "chevron.up", image2: "chevron.down", title: str.CH, action1: {
                        TVRemoteVM.sendCommand(.CHANNELUP)
                    }, action2: {
                        TVRemoteVM.sendCommand(.CHANNELDOWN)
                    })
                    
                }
                .padding(.horizontal,20)
                
                HStack(spacing: isIpad() ? 40 : 20) {
                    
                    CircleButton(icon: "back2",size: 30,size2: 66, action: {
                        TVRemoteVM.sendCommand(.BACK)
                    })
                    
                    Button {
                        
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
                    
                    
                    CircleButton(icon: "channel2",size: 30,size2: 66, action: {
                        
                    })
                    
                }
                .padding(.horizontal,20)
                .padding(.vertical,10)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .appScreen()
        .onTapGesture {
            hideKeyboard()
        }
    }
}

#Preview {
    RemoteView()
        .environmentObject(CommonConnectionViewModel())
        .environmentObject(RemoteViewModel())
}
