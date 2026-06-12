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
            DeviceListBG()
            
            VStack {
                singleButtonCard(image: "close") {
                    dismiss()
                }
                .frame(maxWidth: .infinity,alignment: .trailing)
                .padding(.trailing)
                
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
                .padding(.horizontal)
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
                    }
                }
                Spacer()
            }
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
            "Enter PIN Code".localized,
            isPresented: $TVRemoteVM.showPinDialog
        ) {
            TextField("Enter PIN".localized, text: $TVRemoteVM.pinCode)
            
            Button("Cancel".localized, role: .cancel) {
                TVRemoteVM.pinCode = ""
                TVRemoteVM.showPinDialog = false
                TVRemoteVM.disconnectTV()
            }
            
            Button("Submit".localized) {
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
            Text("Please enter the PIN code displayed on your TV".localized)
        }
        
        // MARK: - Samsung Alert (unchanged)
        .alert(
            "Samsung TV Permission Required".localized,
            isPresented: $TVRemoteVM.showAllowInTVSettingsAlert
        ) {
            Button("OK".localized, role: .cancel) { }
        } message: {
            Text(String(
                format: "To connect your iPhone, please allow permission on your Samsung TV:\n\n1. Open Settings on your TV\n2. Go to Connections → External Device Manager\n3. Select Device Connection Manager\n4. Open Device List\n5. Find %@ and select it\n6. Set it to \"Allowed\"\n\nAfter allowing, try connecting again.".localized,
                AppStrings.appName
            ))
        }
        .overlay(alignment: .bottom) {
            
            ZStack {
                
                if showConnectionPopup || showDisconnectPopup {
                    
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showConnectionPopup = false
                                showDisconnectPopup = false
                            }
                        }
                }
                
                VStack {
                    Spacer()
                    
                    // Connection Success Popup
                    if showConnectionPopup {
                        
                        PopupCard(
                            image: "connect2",
                            title: "\(str.connect1) \(TVRemoteVM.deviceName ?? "")",
                            subtitle: str.connect2,
                            btnTitle: str.Connect
                        ) {
                            
                            withAnimation(.spring()) {
                                showConnectionPopup = false
                            }
                        } closeAction: {
                            withAnimation(.spring()) {
                                showConnectionPopup = false
                            }
                        }
                    }
                    
                    // Disconnect Popup
                    if showDisconnectPopup {
                        
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
                    
                    if showSwitchDevicePopup {
                        
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
                    if permissionVM.showLocalNetworkPopup {
                        
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
    DeviceListview()
        .environmentObject(RemoteViewModel())
        .environmentObject(CommonConnectionViewModel())
}
