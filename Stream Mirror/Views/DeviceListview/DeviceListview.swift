//
//  DeviceListview.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI
import ConnectSDK
import GoogleCast

struct DeviceListview: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var TVRemoteVM: RemoteViewModel
    @EnvironmentObject private var commonVM: CommonConnectionViewModel
    @StateObject var permissionVM = DeviceListViewModel()
    @State private var showStep: Bool = false
    @State private var showConnectionPopup = false
    @State private var showDisconnectPopup = false
    @State private var pendingDevice: ConnectableDevice?
    @State private var showSwitchDevicePopup = false
    @Binding var isPresented: Bool
    
    private var connectedDevices: [ConnectableDevice] {
        TVRemoteVM.discoveredDevices.filter {
            TVRemoteVM.connectedTVType != nil &&
            TVRemoteVM.deviceName == $0.friendlyName
        }
    }
    
    private var otherDevices: [ConnectableDevice] {
        TVRemoteVM.discoveredDevices.filter {
            TVRemoteVM.deviceName != $0.friendlyName ||
            TVRemoteVM.connectedTVType == nil
        }
    }
    
    var body: some View {
        ZStack {
            Image("sheetBG")
                    .resizable()
//                    .scaledToFit()
                    .ignoresSafeArea()
            
            VStack {
                singleButtonCard(image: "close") {
                    isPresented = false
                }
                .frame(maxWidth: .infinity,alignment: .trailing)
                .padding(.top,20)
                .padding(.trailing,20)
                
                VStack(spacing:8) {
                    Text(str.ConnecttoaDevice)
                        .font(.system(size: isIpad() ? 28 : 20,weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(str.ConnecttoaDevice2)
                        .font(.system(size: isIpad() ? 18 : 12))
                        .foregroundStyle(AppColor.textColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal,20)
                
                if TVRemoteVM.connectedTVType != nil {
                    HStack {
                        Divider()
                            .frame(width: isIpad() ? 7 :4,height: isIpad() ? 26 : 22)
                            .background(.white)
                        
                        Text(str.ActiveDevices)
                            .font(.system(size: isIpad() ? 24 : 18,weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity,alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical,15)
                    
                    ForEach(connectedDevices, id: \.address) { device in
                        
                        Button {
                            withAnimation(.spring()) {
                                showDisconnectPopup = true
                            }
                        } label: {
                            
                            DeviceListingRow(
                                deviceName: device.friendlyName ?? "Unknown TV".localized,
                                status: .connected
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                }
                HStack {
                    Divider()
                        .frame(width: isIpad() ? 7 :4,height: isIpad() ? 26 : 22)
                        .background(.white)
                    
                    Text(str.OtherDevices)
                        .font(.system(size: isIpad() ? 24 : 18,weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity,alignment: .leading)
                .padding(.horizontal,15)
                .padding(.vertical,15)
                
                if showStep {
                    
                    stepCard()
                    
                } else if TVRemoteVM.discoveredDevices.isEmpty {
                    
                    Spacer()
                    VStack(spacing:50) {
                        placeholderView(
                            image: "DeviceListPH",
                            title: str.NoDevicesAvailable,
                            title2: str.GetConnectedinaThreeSimpleSteps,
                            isTitle2: true
                        )
                        
                        Button {
                            withAnimation {
                                showStep = true
                            }
                        } label: {
                            Text(str.HowItWorks)
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(.white)
                                        .frame(height: 1)
                                        .offset(y: 4)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    
                } else {
                    
                    VStack(spacing: 12) {
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            ForEach(TVRemoteVM.discoveredDevices, id: \.address) { device in
                                Button {
                                    if TVRemoteVM.connectedTVType != nil &&
                                           TVRemoteVM.deviceName == device.friendlyName {

                                           withAnimation(.spring()) {
                                               showDisconnectPopup = true
                                           }

                                       }
                                       // Different device tapped
                                       else if TVRemoteVM.connectedTVType != nil {

                                           pendingDevice = device

                                           withAnimation(.spring()) {
                                               showSwitchDevicePopup = true
                                           }

                                       }
                                       // No device connected
                                       else {

                                           TVRemoteVM.connect(to: device)
                                       }
                                } label: {
                                    DeviceListingRow(
                                        deviceName: device.friendlyName ?? "Unknown TV".localized,
                                        status: statusForDevice(device)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
//                        .padding(.horizontal)
                    }
                }
                Spacer()
            }
//            .padding(.horizontal,24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            permissionVM.startNetworkMonitoring()
            permissionVM.checkLocalNetworkPermission()
            
        }
        .onChange(of: TVRemoteVM.connectedTVType) { connectedTvType in
            if let type = connectedTvType,
               TVRemoteVM.isConnectedSuccessfully {
                withAnimation(.spring()) {
                    showConnectionPopup = true
                }
                print("🔥 CommonVM Updated:", type, TVRemoteVM.deviceName ?? "")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let connectedType = commonVM.getConnectedTvType() {
                        commonVM.setTVPlaceHolder(connectedTvType: connectedType)
                        print("✅ Placeholder casted")
                    }
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            
            if phase == .active {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    permissionVM.checkLocalNetworkPermission()
                }
            }
        }
        .onDisappear {
            permissionVM.stopChecking()
            TVRemoteVM.showProgress = false
            TVRemoteVM.pinCode = ""
            TVRemoteVM.showPinDialog = false
        }
        .alert(
            str.EnterPINCode,
            isPresented: $TVRemoteVM.showPinDialog
        ) {
            TextField(str.EnterPIN, text: $TVRemoteVM.pinCode)
            
            Button(str.Cancel, role: .cancel) {
                TVRemoteVM.pinCode = ""
                TVRemoteVM.showPinDialog = false
                TVRemoteVM.disconnectTV()
            }
            
            Button(str.Submit) {
                TVRemoteVM.submitPinCode()
                TVRemoteVM.pinCode = ""
                TVRemoteVM.showPinDialog = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if TVRemoteVM.connectedTVType == nil {
                        TVRemoteVM.showProgress = false
                    }
                }
            }
            
        } message: {
            Text(str.PleaseenterthePINcodedisplayedonyourTV)
        }
        
        // MARK: - Samsung Alert (unchanged)
        .alert(
            str.SamsungTVPermissionRequired,
            isPresented: $TVRemoteVM.showAllowInTVSettingsAlert
        ) {
            Button(str.OK, role: .cancel) { }
        } message: {
            Text(String(
                format: str.samsungFormat,
                AppStrings.appName
            ))
        }
        .overlay(alignment: .bottom) {
            
            ZStack {
                
                if permissionVM.showNoNetworkPopup ||
                   permissionVM.showLocalNetworkPopup ||
                   showConnectionPopup ||
                   showDisconnectPopup ||
                   showSwitchDevicePopup {

                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                }
                
                VStack {
                    Spacer()

                    // 1. WIFI POPUP (Highest Priority)
                    if permissionVM.showNoNetworkPopup {

                        PopupCard(
                            image: "WIFI",
                            title: str.WIFI1,
                            subtitle: str.WIFI2,
                            btnTitle: str.WIFI3
                        ) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } closeAction: {
                            permissionVM.showNoNetworkPopup = false
                        }

                    }

                    // 2. LOCAL NETWORK POPUP
                    else if permissionVM.showLocalNetworkPopup {

                        PopupCard(
                            image: "Network",
                            title: str.localNetwork1,
                            subtitle: str.localNetwork2,
                            btnTitle: str.localNetwork3
                        ) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } closeAction: {
                            permissionVM.showLocalNetworkPopup = false
                        }

                    }

                    // 3. CONNECTION SUCCESS POPUP
                    else if showConnectionPopup {

                        PopupCard(
                            image: "connect2",
                            title: "\(str.connect1) \(TVRemoteVM.deviceName ?? "")",
                            subtitle: str.connect2,
                            btnTitle: str.Connect
                        ) {
                            withAnimation(.spring()) {
                                showConnectionPopup = false
                                commonVM.setTVPlaceHolder(
                                    connectedTvType: commonVM.connectedTvType ?? .ANDROID
                                )
                            }
                        } closeAction: {
                            withAnimation(.spring()) {
                                showConnectionPopup = false
                            }
                        }

                    }

                    // 4. DISCONNECT POPUP
                    else if showDisconnectPopup {

                        PopupCard(
                            image: "disconnect",
                            title: str.disconnect1,
                            subtitle: str.disconnect2 + "\(TVRemoteVM.deviceName ?? "")?",
                            btnTitle: str.Disconnect
                        ) {
                            TVRemoteVM.disconnectTV()

                            withAnimation(.spring()) {
                                showDisconnectPopup = false
                            }
                        } closeAction: {
                            withAnimation(.spring()) {
                                showDisconnectPopup = false
                            }
                        }

                    }

                    // 5. SWITCH DEVICE POPUP (Lowest Priority)
                    else if showSwitchDevicePopup {

                        PopupCard(
                            image: "disconnectCurrentDevice",
                            title: str.DisconnectCurrentDevice1,
                            subtitle: str.DisconnectCurrentDevice2,
                            btnTitle: str.Disconnect
                        ) {

                            guard let device = pendingDevice else { return }

                            TVRemoteVM.disconnectTV()

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                TVRemoteVM.connect(to: device)
                            }

                            pendingDevice = nil

                            withAnimation(.spring()) {
                                showSwitchDevicePopup = false
                            }

                        } closeAction: {

                            pendingDevice = nil

                            withAnimation(.spring()) {
                                showSwitchDevicePopup = false
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges:.bottom)
            }
            .animation(.spring(), value: showConnectionPopup)
            .animation(.spring(), value: showDisconnectPopup)
        }
    }
    
    private func statusForDevice(_ device: ConnectableDevice) -> deviceStatus {
        
        if TVRemoteVM.connectedTVType != nil,
           TVRemoteVM.deviceName == device.friendlyName {
            return .connected
        }
        
        if TVRemoteVM.showProgress,
           TVRemoteVM.deviceName == device.friendlyName {
            return .connecting
        }
        
        return .notConnected
    }
}

#Preview {
    DeviceListview(isPresented: .constant(true))
        .environmentObject(RemoteViewModel())
        .environmentObject(CommonConnectionViewModel())
}
