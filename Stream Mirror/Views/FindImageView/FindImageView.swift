//
//  FindImageView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI

struct FindImageView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject private var imageVM = FindImageViewModel()
    @FocusState private var isSearchFocused: Bool
    @Binding var text: String
    @AppStorage(SessionKeys.isPro) var isPro = false
    @EnvironmentObject var adVm : AdCountViewModel
    @State private var showPremium = false
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(title: str.OnlineImage,onCast: {
                    imageVM.showDeviceList = true
                })
                
                ZStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .foregroundStyle(AppColor.textColor)
                            .frame(width: 18, height: 18)
                        
                        ZStack(alignment: .leading) {
                            if text.isEmpty {
                                Text(str.Search)
                                    .foregroundColor(AppColor.textColor)
                                    .padding(.leading, 2)
                            }
                            
                            TextField(str.Search, text: $text)
                                .foregroundStyle(AppColor.textColor)
                                .focused($isSearchFocused)
                                .onChange(of: text) { newValue in
                                
                                imageVM.searchTask?.cancel()
                                
                                let task = DispatchWorkItem {
                                    
                                    imageVM.searchOnlineImages(query: newValue)
                                }
                                imageVM.searchTask = task
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .frame(height: isIpad() ? 70 : 50)
                .modifier(GlassCardModifier(cornerRadius: isIpad() ? 35 : 25))
                .padding(.horizontal,15)
                .padding(.top,10)
                
                if imageVM.isLoading && imageVM.images.isEmpty {
                    
                    Spacer()
                    
                    ProgressView("Loading Images...")
                        .tint(.white)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                } else if imageVM.images.isEmpty {
                    
                    Spacer()
                    
                    placeholderView(image: "PhotoListPH", title: str.Enterkeywordstosearch, title2: "", isTitle2: false)
                    Spacer()
                    
                } else {
                    
                    ScrollView(showsIndicators: false) {
                        if !isPro {
                            NativeAd7()
                                .padding(.top,15)
                        }
                        photoGrid
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                        
                        if imageVM.isLoading && !imageVM.images.isEmpty {
                            ProgressView()
                                .padding(.bottom, 16)
                        }
                    }
                }
            }
        }
        .appScreen(isPresented: $imageVM.showDeviceList) {
            DeviceListview(isPresented: $imageVM.showDeviceList)
                .environmentObject(TVRemoteVM)
                .environmentObject(commonVM)
        }
        .onAppear {
            if imageVM.isFirstAppear {

                text = ""
                imageVM.images.removeAll()

                imageVM.isFirstAppear = false
            }
        }
        .navigationDestination(
            isPresented: $imageVM.showPhotoCasting
        ) {
            PhotoCastingView(
                images: [],
                imageURLs: imageVM.selectedImageURLs,
                selectedIndex: imageVM.selectedIndex
            )
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

extension FindImageView {
    
    var photoGrid: some View {
        
        let spacing: CGFloat = 10
        let columns: Int = 3
        
        let totalSpacing = spacing * CGFloat(columns - 1) + 32
        
        let itemWidth =
        (UIScreen.main.bounds.width - totalSpacing)
        / CGFloat(columns)
        
        return LazyVGrid(
            columns: Array(
                repeating: GridItem(
                    .flexible(),
                    spacing: spacing
                ),
                count: columns
            ),
            spacing: spacing
        ) {
            
            ForEach(imageVM.images, id: \.id) { item in

                Button {
                    if isPro {
                        TVRemoteVM.handleDeviceAction {
                            
                        } onTV: {
                            adVm.registerTap()
                            let allImageURLs = imageVM.images.compactMap {
                                $0.url ?? $0.thumbnail
                            }
                            
                            let selectedIndex = imageVM.images.firstIndex {
                                $0.id == item.id
                            } ?? 0
                            
                            imageVM.selectedIndex = selectedIndex
                            imageVM.selectedImageURLs = allImageURLs
                            imageVM.showPhotoCasting = true
                            
                        } onNoDevice: {
                            
                            imageVM.showDeviceList = true
                        }
                    } else {
                        showPremium = true
                    }

                } label: {

                    OnlineImageCardView(item: item)
                        .frame(width: itemWidth, height: itemWidth)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .onAppear {
                    // Last item dikhne par next page load karo
                    if item.id == imageVM.images.last?.id {
                        imageVM.loadMoreIfNeeded(currentItem: item)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct OnlineImageCardView: View {
    
    let item: SearchImage
        
    var body: some View {
        
        ZStack(alignment: .topTrailing) {
            
            if let thumbnail = item.thumbnail {
                
                ZStack {
                    Color.gray.opacity(0.1)
                    GeometryReader { geo in
                        SDWebImageView(url: thumbnail)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .contentShape(Rectangle())
                }
            
            } else {
                
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: "photo")
                        .foregroundStyle(.gray)
                }
            }
            
        }
        .clipped()
        .cornerRadius(12)
    }
}

#Preview {
    FindImageView(text: .constant(""))
}
