//
//  VideosView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI
internal import Photos

struct VideosView: View {
    
    @StateObject private var photoVM = PhotoVideoListingViewModel()
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @AppStorage(SessionKeys.isPro) var isPro = false
    @EnvironmentObject var adVm : AdCountViewModel
    @State private var showPremium = false
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(
                    title: str.Video,
                    onCast: {
                        photoVM.showDeviceList = true
                    }
                )
                
                limitedAccessCard(photoVM: photoVM)
                
                if photoVM.isLoading {

                    Spacer()

                    ProgressView("Loading Videos...")
                        .tint(.white)
                        .foregroundColor(.white)

                    Spacer()

                } else if photoVM.videoAssets.isEmpty {

                    Spacer()

                    placeholderView(
                        image: "VideoListPH",
                        title: str.NoVideoAvailable,
                        title2: "",
                        isTitle2: false
                    )

//                    Spacer()

                } else {
                    
                    // MARK: - Photo Grid
                    ScrollView(.vertical, showsIndicators: false) {
                        if !isPro {
                            NativeAd7()
                                .padding(.top,15)
                        }
                        videoGridView
                            .padding(.bottom, 16)
                        
                    }
                }
                Spacer()
            }
        }
        .appScreen()
        .onAppear {
            
            photoVM.requestVideoAccess()
            
        }
        .sheet(isPresented: $photoVM.showDeviceList) {
            DeviceListview(isPresented: $photoVM.showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
                .presentationDetents([.height(isIpad() ? 830 : 700)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(LinearGradient(colors: [Color("#222222"), Color("#1A1A1A"), Color("#111111")], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .navigationDestination(
            isPresented: $photoVM.showVideoCasting
        ) {
            VideoCastingView(
                assets: photoVM.videoAssets,
                selectedIndex: photoVM.selectedVideoIndex
            )
        }
        .alert(str.VideoAccessRequired, isPresented: $photoVM.showSettingsAlert) {
            
            Button(str.Settings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            
            Button(str.Cancel, role: .cancel) { }
            
        } message: {
            Text(str.videoAlertMsg)
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

extension VideosView {
    var videoGridView: some View {
        
        let spacing: CGFloat = 10
        let columns: Int = DeviceHelper.isIpad ? 4 : 3
        
        let totalSpacing = spacing * CGFloat(columns - 1) + 32
        let itemWidth = (UIScreen.main.bounds.width - totalSpacing) / CGFloat(columns)
        
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            
            ForEach(
                Array(photoVM.videoAssets.enumerated()),
                id: \.element.localIdentifier
            ) { index, asset in

                Button {
                    if isPro {
                        TVRemoteVM.handleDeviceAction(
                            onAirPlay: {
                                
                                if photoVM.videoAssets.indices.contains(index) {
                                    // ImageAirplayVM.shared.playPHAssetImage(photoVM.assets[index])
                                }
                                
                                photoVM.selectedIndex = index
                            },
                            onTV: {
                                adVm.registerTap()
                                photoVM.selectedVideoIndex = index
                                photoVM.showVideoCasting = true
                                
                            },
                            onNoDevice: {
                                
                                photoVM.showDeviceList = true
                            }
                        )
                    } else {
                        showPremium = true
                    }

                } label: {

                    ImageAssetView(asset: asset,isVideo: true)
                        .frame(width: itemWidth, height: itemWidth)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    VideosView()
}
