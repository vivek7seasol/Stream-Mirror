//
//  HomeView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @State private var showDeviceList: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text(AppStrings.appName)
                        .font(.system(size: 24,weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        
                    } label: {
                        Image("premium")
                            .resizable()
                            .frame(width: isIpad() ?30 : 26, height: isIpad() ? 30 : 26)
                    }
                    .buttonStyle(.plain)
                    
                }
                .padding(.horizontal,15)
                
                ScrollView(.vertical,showsIndicators: false) {
                    connectDeviceCard {
                        showDeviceList = true
                    }
                    
                    firstCard {
                        
                    } YTAction: {
                        
                    } FileAction: {
                        
                    }
                    
                    VStack(spacing:15) {
                        ZStack {
                            VStack(spacing:20) {
                                HStack {
                                    Divider()
                                        .frame(width: isIpad() ? 7 : 4,height: isIpad() ? 26 : 22)
                                        .background(.white)
                                    
                                    Text(str.DisplayCasting)
                                        .font(.system(size: isIpad() ? 24 : 18,weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity,alignment: .leading)
                                .padding(.horizontal)
                                HStack {
                                    Spacer()
                                    castingCard(title: str.Camera, image: "Camera") {
                                        
                                    }
                                    Spacer()
                                    castingCard(title: str.Photo, image: "Photo") {
                                        
                                    }
                                    Spacer()
                                    castingCard(title: str.Video, image: "Video") {
                                        
                                    }
                                    Spacer()
                                    castingCard(title: str.Music, image: "Music") {
                                        
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical,20)
                        .modifier(GlassCardModifier(cornerRadius: 30))
                        .padding(.horizontal,15)
                        
                        ZStack {
                            VStack(spacing:20) {
                                HStack {
                                    Divider()
                                        .frame(width: isIpad() ? 7 :4,height: isIpad() ? 26 : 22)
                                        .background(.white)
                                    
                                    Text(str.SmartTools)
                                        .font(.system(size: isIpad() ? 24 : 18,weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity,alignment: .leading)
                                .padding(.horizontal)
                                HStack {
                                    Spacer()
                                    castingCard(title: str.Browser, image: "Browser") {
                                        
                                    }
                                    Spacer()
                                    castingCard(title: str.OnlineImage, image: "Online Image") {
                                        
                                    }
                                    Spacer()
                                    castingCard(title: str.IPTV, image: "IPTV") {
                                        
                                    }
                                    Spacer()
                                    castingCard(title: str.Drawing, image: "Drawing") {
                                        
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical,20)
                        .modifier(GlassCardModifier(cornerRadius: 30))
                        .padding(.horizontal,15)
                        
                    }
                }
            }
        }
        .appScreen()
        .navigationDestination(isPresented: $showDeviceList) {
            DeviceListview()
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(RemoteViewModel())
        .environmentObject(CommonConnectionViewModel())
}
