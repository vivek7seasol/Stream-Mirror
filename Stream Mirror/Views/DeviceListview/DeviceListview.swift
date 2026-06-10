//
//  DeviceListview.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI
import ConnectSDK

struct DeviceListview: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var TVRemoteVM: RemoteViewModel
    @EnvironmentObject private var commonVM: CommonConnectionViewModel
    
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
                
                VStack(spacing:15) {
                    Text(str.ConnecttoaDevice)
                        .font(.system(size: isIpad() ? 28 : 20,weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(str.ConnecttoaDevice2)
                        .font(.system(size: isIpad() ? 18 : 12))
                        .foregroundStyle(AppColor.textColor)
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
                        
                        DeviceListingRow(
                            deviceName: device.friendlyName ?? "Unknown TV".localized,
                            status: .connected
                        )
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
                
                if otherDevices.isEmpty {
                    Spacer()
                    VStack {
                        placeholderView(image: "DeviceListPH", title: str.NoDevicesAvailable, title2: str.GetConnectedinaThreeSimpleSteps, isTitle2: true)
                        
                        Button {
                            
                        } label: {
                            
                            VStack {
                                Text(str.HowItWorks)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .padding(.top, 50)
                                    .overlay(alignment: .bottom) {
                                        Rectangle()
                                            .fill(.white)
                                            .frame(height: 1)
                                            .offset(y: 4)
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                } else {
                    ScrollView(.vertical,showsIndicators: false) {
                        ForEach(otherDevices, id: \.address) { device in
                            
                            Button {
                                TVRemoteVM.connect(to: device)
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
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        
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
