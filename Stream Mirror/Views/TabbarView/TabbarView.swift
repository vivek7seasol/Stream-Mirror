//
//  TabbarView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI
import Combine

final class TabBarManager: ObservableObject {
    @Published var isHidden = false
}

struct TabbarView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @EnvironmentObject var tabBarManager: TabBarManager
    @State private var selectedTab: Int = 0
    @State private var keyboardVisible = false
    @State private var showChannelView = false
    @State private var showNumberPad = false
    @State private var showDeviceList = false
    @State private var showTVInputList = false
    @State private var refreshID = UUID()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            Group {
                if selectedTab == 0 {
                    HomeView(showDeviceList: $showDeviceList)
                } else if selectedTab == 1 {
                    RemoteView(
                        showChannelView: $showChannelView,
                        showNumberPad: $showNumberPad,
                        showDeviceList: $showDeviceList,
                        showTVinputList: $showTVInputList
                    )
                } else if selectedTab == 2 {
                    RecordingView()
                } else {
                    SettingView()
                }
            }
            
            if !keyboardVisible && !tabBarManager.isHidden {
                HStack {
                    tabItem(index: 0, icon: "Home", title: str.Home)
                    tabItem(index: 1, icon: "Remote", title: str.Remote)
                    tabItem(index: 2, icon: "Recoding", title: str.Recoding)
                    tabItem(index: 3, icon: "Settings", title: str.Settings)
                }
                .padding(.bottom, 15)
                .padding(.horizontal, 15)
                .gradientBackground(
                    colors: [Color("#222222"), Color("#111111")],
                    start: .topLeading,
                    end: .bottomTrailing
                )
                .modifier(GlassCardModifier(cornerRadius: 20))
                .offset(y: 10)
            }
        }
        .id(refreshID)
        .appScreen(disableSwipeBack: true)
        .onAppear {
            refreshID = UUID()
        }
        .ignoresSafeArea(edges: .bottom)
        .overlay {
            
            if showChannelView {
                ChannelView(
                    isPresented: $showChannelView
                ) { app in
                    
                    switch app {
                        
                    case .youtube:
                        TVRemoteVM.launchApp(.youtube)
                        
                    case .netflix:
                        TVRemoteVM.launchApp(.netflix)
                        
                    case .disney:
                        TVRemoteVM.launchApp(.disney)
                        
                    case .prime:
                        TVRemoteVM.launchApp(.prime)
                        
                    case .spotify:
                        TVRemoteVM.launchApp(.spotify)
                        
                    case .paramount:
                        TVRemoteVM.launchApp(.paramount)
                    default:
                        break
                    }
                }
                .offset(y: 50)
                .zIndex(1)
            }
            
            if showNumberPad {
                NumberPadView(
                    isPresented: $showNumberPad,
                    
                    onNumberTap: { number in
                        print("Tapped:", number)
                        TVRemoteVM.sendNumber(number)
                    },
                    
                    onClear: {
                        TVRemoteVM.sendCommand(.BACK)
                    },
                    
                    onDone: { value in
                        print("Entered:", value)
                        showNumberPad = false
                    }
                )
                .offset(y: 50)
                .zIndex(2)
            }
            if showTVInputList {
                
                TVInputSourceView(
                    isPresented: $showTVInputList,
                    TVRemoteVM: TVRemoteVM
                )
                .offset(y: 50)
                .zIndex(2)
            }
            
        }
        .fullScreenCover(isPresented: $showDeviceList) {
            DeviceListview(isPresented: $showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .alert(
            "AirPlay Connected",
            isPresented: $TVRemoteVM.showAirPlayAlert
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This feature is not available while using AirPlay.")
        }
        
    }
    
    
    func tabItem(index: Int, icon: String, title: String) -> some View {
        Button {
            selectedTab = index
        } label: {
            ZStack {
                VStack {
                    
                    if selectedTab == index {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: isIpad() ? 34 : 24, height: isIpad() ? 34 : 24)
                            .foregroundStyle(.white)
                    } else {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: isIpad() ? 34 : 24, height: isIpad() ? 34 : 24)
                            .foregroundStyle(AppColor.textColor)
                    }
                    
                    Text(title.uppercased())
                        .font(.system(size: isIpad() ? 16 : 8, weight: .semibold))
                    
                }
                .foregroundColor(selectedTab == index ? .white : AppColor.textColor)
            }
            .padding()
            .background(
                selectedTab == index ?
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color.white.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                : LinearGradient(
                    colors: [.clear, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .top) {
                if selectedTab == index {
                    Rectangle()
                        .fill(.white)
                        .frame(height: isIpad() ? 4 : 2)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        
        
    }
}

#Preview {
    TabbarView()
}
