//
//  IPTVChannelView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI

struct IPTVChannelView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @FocusState private var isSearchFocused: Bool
    @State private var text: String = ""
    @State private var showCastingView = false
    @State private var showDeviceList = false
    @State private var selectedChannel: Channel?
    @AppStorage(SessionKeys.isPro) var isPro = false
    @EnvironmentObject var adVm : AdCountViewModel
    @State private var showPremium = false
    
    var title: String
    var channels: [Channel]
    
    let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: isIpad() ? 4 : 3
    )
    var filteredChannels: [Channel] {

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return channels
        }

        return channels.filter {
            ($0.name ?? "")
                .localizedCaseInsensitiveContains(text)
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.IPTV,onCast: {
                    showDeviceList = true
                })
                
                ZStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .foregroundStyle(AppColor.textColor)
                            .frame(width: 18, height: 18)
                        
                        TextField("", text: $text, prompt: Text(str.Search).foregroundColor(AppColor.textColor))
                            .foregroundColor(.white)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .frame(height: isIpad() ? 70 : 50)
                .modifier(GlassCardModifier(cornerRadius: isIpad() ? 35 : 25))
                .padding(.horizontal, 15)
                .padding(.top, 10)
                
                if filteredChannels.isEmpty {
                    
                    Spacer()
                    
                    placeholderView(
                        image: "channelPH",
                        title: str.NoChannelsAvailable,
                        title2: "",
                        isTitle2: false,height: 110,width: 130
                    )
                    
                    Spacer()
                    
                } else {
                    ScrollView(showsIndicators: false) {
                        if !isPro {
                            NativeAd7()
                                .padding(.top,15)
                        }
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredChannels, id: \.self) { channel in
                                IPTVChannelCard(
                                    image: channel.logo ?? "channel",
                                    title: channel.name ?? "Channel",
                                    isURLImage: true
                                ) {
                                    if isPro {
                                        TVRemoteVM.handleDeviceAction {
                                            
                                        } onTV: {
                                            adVm.registerTap()
                                            selectedChannel = channel
                                            showCastingView = true
                                        } onNoDevice: {
                                            showDeviceList = true
                                        }
                                    } else {
                                        showPremium = true
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                
            }
        }
        .appScreen(isPresented: $showDeviceList) {
            DeviceListview(isPresented: $showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .onTapGesture {
            hideKeyboard()
        }
        .navigationDestination(isPresented: $showCastingView) {

            if let selectedChannel {

                IPTVCastingView(
                    channel: selectedChannel
                )
            }
        }
        .fullScreenCover(isPresented: $showPremium, onDismiss: {
            if pro_close_inter == "true" {
                adVm.registerTap()
            }
        }, content: {
            PremiumView()
        })
    }
}

#Preview {
    IPTVChannelView(title: "", channels: [])
        .environmentObject(RemoteViewModel())
        .environmentObject(CommonConnectionViewModel())
}
