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
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(
                    title: str.Video,
                    onCast: {}
                )
                
                if photoVM.isLoading && !photoVM.showPlaceholder {

                    Spacer()

                    ProgressView()
                        .scaleEffect(1.3)

                    Spacer()

                } else if photoVM.videoAssets.isEmpty && photoVM.showPlaceholder {

                    Spacer()

                    placeholderView(
                        image: "VideoListPH",
                        title: str.NoPhotosAvailable,
                        title2: "",
                        isTitle2: false
                    )

//                    Spacer()

                } else {
                    
                    // MARK: - Photo Grid
                    ScrollView(.vertical, showsIndicators: false) {
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                
                if photoVM.assets.isEmpty {
                    photoVM.isLoading = false
                    photoVM.showPlaceholder = true
                }
            }
        }
        .fullScreenCover(isPresented: $photoVM.showDeviceList) {
            DeviceListview()
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .navigationDestination(
            isPresented: $photoVM.showVideoCasting
        ) {
            VideoCastingView(
                assets: photoVM.videoAssets,
                selectedIndex: photoVM.selectedVideoIndex
            )
        }
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

//                    TVRemoteVM.handleDeviceAction(
//                        onAirPlay: {
//
//                            if photoVM.videoAssets.indices.contains(index) {
//                                // ImageAirplayVM.shared.playPHAssetImage(photoVM.assets[index])
//                            }
//
//                            photoVM.selectedIndex = index
//                        },
//                        onTV: {

                            photoVM.selectedVideoIndex = index
                            photoVM.showVideoCasting = true

//                        },
//                        onNoDevice: {
//
//                            photoVM.showDeviceList = true
//                        }
//                    )

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
