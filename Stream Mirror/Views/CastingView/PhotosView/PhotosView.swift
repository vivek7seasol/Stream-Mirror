//
//  PhotosView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import SwiftUI
internal import Photos
internal import PhotosUI

struct PhotosView: View {
    
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
                    title: str.Photo,
                    onCast: {
                        photoVM.showDeviceList = true
                    }
                )
                
                limitedAccessCard(photoVM: photoVM)
                
                if photoVM.isLoading && !photoVM.showPlaceholder {

                    Spacer()

                    ProgressView("Loading Photos...".localized)
                        .tint(.white)
                        .foregroundColor(.white)

                    Spacer()

                } else if photoVM.assets.isEmpty && photoVM.showPlaceholder {

                    Spacer()

                    placeholderView(
                        image: "PhotoListPH",
                        title: str.NoPhotosAvailable,
                        title2: "",
                        isTitle2: false
                    )

                } else {
                    
                    // MARK: - Photo Grid
                    ScrollView(.vertical, showsIndicators: false) {
                        if !isPro {
                            NativeAd7()
                                .padding(.top,15)
                                .padding(.horizontal,15)
                        }
                        photoGridView
                            .padding(.bottom, 16)
                        
                    }
                }
                Spacer()
            }
        }
        .appScreen(isPresented: $photoVM.showDeviceList) {
            DeviceListview(isPresented: $photoVM.showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .onAppear {
            
            photoVM.requestPhotoAccess()
            
        }
        .navigationDestination(isPresented: $photoVM.showPhotoCasting) {
            PhotoCastingView(
                images: [], assets: photoVM.assets,
                selectedIndex: photoVM.selectedIndex
            )
        }
        .sheet(isPresented: $photoVM.showDeviceList) {
            DeviceListview(isPresented: $photoVM.showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
                .presentationDetents([.height(isIpad() ? 830 : 700)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(LinearGradient(colors: [Color("#222222"), Color("#1A1A1A"), Color("#111111")], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .alert(str.Photo_Access_Required, isPresented: $photoVM.showSettingsAlert) {
            
            Button(str.Settings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            
            Button(str.Cancel, role: .cancel) { }
            
        } message: {
            Text(str.photoAlertMsg)
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
                    if isPro {
                        TVRemoteVM.handleDeviceAction(
                            onAirPlay: {
                                
                                if photoVM.assets.indices.contains(index) {
                                    // ImageAirplayVM.shared.playPHAssetImage(photoVM.assets[index])
                                }
                                
                                photoVM.selectedIndex = index
                            },
                            onTV: {
                                adVm.registerTap()
                                photoVM.selectedIndex = index
                                photoVM.showPhotoCasting = true
                                
                            },
                            onNoDevice: {
                                
                                photoVM.showDeviceList = true
                            }
                        )
                    } else {
                        showPremium = true
                    }

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

struct limitedAccessCard: View {
    
    @ObservedObject var photoVM: PhotoVideoListingViewModel
    var body: some View {
        if photoVM.isPremissionLimited {
            HStack {
                Text(str.Youvegiven + AppStrings.appName + str.accesstoselecofphotosorvideos)
                    .foregroundStyle(AppColor.textColor)
                    .font(.system(size: isIpad() ? 20 :  14))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                
                Spacer()
                Button {
                    photoVM.showPermissionAlert = true
                } label: {
                    Text(str.Manage)
                        .foregroundStyle(.blue)
                }
                .confirmationDialog("", isPresented: $photoVM.showPermissionAlert, titleVisibility: .visible) {
                    
                    Button(str.SelectMorePhotosorvideos) {
                        if let rootController = getTopViewController() {
                            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: rootController)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                photoVM.fetchImages()
                            }
                        }
                    }
                    Button(str.ChangeSettings) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    Button(str.Cancel, role: .cancel) { }
                }
            }
            .padding(.horizontal,10)
        }
    }
}

#Preview {
    PhotosView()
}
