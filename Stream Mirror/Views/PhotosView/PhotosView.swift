//
//  PhotosView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import SwiftUI

struct PhotosView: View {
    
    @StateObject private var photoVM = PhotoVideoListingViewModel()
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    
    var body: some View {
        ZStack {
            VStack {
                CommonStatusView(
                    title: str.Preview,
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

                    Spacer()

                } else {
                    
                    // MARK: - Photo Grid
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        
//                        photoGrid
//                            .padding(.bottom, 16)
                        
                    }
                }
                Spacer()
            }
        }
        .appScreen()
    }
}


#Preview {
    PhotosView()
}
