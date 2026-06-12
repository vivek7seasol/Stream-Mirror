//
//  PhotosView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import SwiftUI
internal import Photos

struct PhotosView: View {
    
    @StateObject private var photoVM = PhotoVideoListingViewModel()
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(
                    title: str.Photo,
                    onCast: {}
                )
                
                if photoVM.isLoading && !photoVM.showPlaceholder {

                    Spacer()

                    ProgressView()
                        .scaleEffect(1.3)

                    Spacer()

                } else if photoVM.assets.isEmpty && photoVM.showPlaceholder {

                    Spacer()

                    placeholderView(
                        image: "PhotoListPH",
                        title: str.NoPhotosAvailable,
                        title2: "",
                        isTitle2: false
                    )

//                    Spacer()

                } else {
                    
                    // MARK: - Photo Grid
                    ScrollView(.vertical, showsIndicators: false) {
                        photoGridView
                            .padding(.bottom, 16)
                        
                    }
                }
                Spacer()
            }
        }
        .appScreen()
        .onAppear {
            
            photoVM.requestPhotoAccess()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                
                if photoVM.assets.isEmpty {
                    photoVM.isLoading = false
                    photoVM.showPlaceholder = true
                }
            }
        }
        .navigationDestination(isPresented: $photoVM.showPhotoCasting) {
            PhotoCastingView(
                assets: photoVM.assets,
                selectedIndex: photoVM.selectedIndex
            )
        }
        .fullScreenCover(isPresented: $photoVM.showDeviceList) {
            DeviceListview()
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
    }
}

extension PhotosView {
    var photoGridView: some View {
        
        let spacing: CGFloat = 10
        let columns: Int = DeviceHelper.isIpad ? 4 : 3
        
        let totalSpacing = spacing * CGFloat(columns - 1) + 32
        let itemWidth = (UIScreen.main.bounds.width - totalSpacing) / CGFloat(columns)
        
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            
            ForEach(
                Array(photoVM.assets.enumerated()),
                id: \.element.localIdentifier
            ) { index, asset in

                Button {

                    TVRemoteVM.handleDeviceAction(
                        onAirPlay: {

                            if photoVM.assets.indices.contains(index) {
                                // ImageAirplayVM.shared.playPHAssetImage(photoVM.assets[index])
                            }

                            photoVM.selectedIndex = index
                        },
                        onTV: {

                            photoVM.selectedIndex = index
                            photoVM.showPhotoCasting = true

                        },
                        onNoDevice: {

                            photoVM.showDeviceList = true
                        }
                    )

                } label: {

                    ImageAssetView(asset: asset)
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
    PhotosView()
}
