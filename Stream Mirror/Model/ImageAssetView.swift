//
//  ImageAssetView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import Foundation
import SwiftUI
internal import Photos

struct ImageAssetView: View {
    
    let asset: PHAsset
    var isVideo: Bool = false
    @State private var image: UIImage? = nil
    @State private var requestID: PHImageRequestID?
    
    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
                ProgressView()
            }
            
            if isVideo {
                Image("play")
                    .resizable()
                    .frame(width: isIpad() ? 30 : 20, height: isIpad() ? 30 : 20)
                    .frame(width: isIpad() ? 44 : 34, height: isIpad() ? 44 : 34)
                    .modifier(GlassCardModifier(cornerRadius: isIpad() ? 22 : 17))
                    .clipShape(RoundedRectangle(cornerRadius: isIpad() ? 22 : 17))
            }
        }
        .clipped()
        .id(asset.localIdentifier)
        .onAppear {
            loadImage()
        }
        .onChange(of: asset.localIdentifier) { _ in
            image = nil
            loadImage()
        }
        .onDisappear {
            if let requestID {
                PHImageManager.default().cancelImageRequest(requestID)
            }
        }
    }
    
    func loadImage() {
        if let requestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        
        image = nil
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        
        requestID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 300, height: 300),
            contentMode: .aspectFill,
            options: options
        ) { img, _ in
            DispatchQueue.main.async {
                self.image = img
            }
        }
    }
}
