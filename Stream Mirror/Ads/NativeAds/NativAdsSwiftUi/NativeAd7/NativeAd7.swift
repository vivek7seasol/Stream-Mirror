//
//  NativeAd3.swift
//  Screen Mirroring Casting
//
//  Created by Ronik Hirpara on 17/10/25.
//

import Foundation
import ShimmerSwift
import SwiftUI


struct NativeAd7: View {
    @StateObject private var nativeViewModel = NativeAdViewModel()
    @AppStorage(SessionKeys.isPro) var isPro = false
    @State var hasLoadedOnce = false

    var body: some View {
        VStack {
            if !isPro {
                if let _ = nativeViewModel.nativeAd {
                    NativeAd7Container(nativeViewModel: nativeViewModel)
                        .frame(height: isIpad() ? 220 : 190)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(8)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.3), value: nativeViewModel.nativeAd)
                } else if nativeViewModel.didFailToLoad {
                    Color.clear
                        .frame(height: 0)
                        .animation(.easeOut(duration: 0.3), value: nativeViewModel.didFailToLoad)
                } else {
                    ShimmerPlaceholderView()
                        .frame(height: isIpad() ? 220 : 190)
                        .padding(.horizontal, 8)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: nativeViewModel.nativeAd)
                }
            }
        }
        .onAppear {
            if !hasLoadedOnce {
                nativeViewModel.refreshAd()
                hasLoadedOnce = true
            }
        }
    }
}



//struct NativeAd7: View {
//    @StateObject private var nativeViewModel = NativeAdViewModel()
//    @AppStorage(SessionKeys.isPro) var isPro = false
//
//    var body: some View {
//        VStack {
//            if !isPro {
//                if let _ = nativeViewModel.nativeAd {
//                    NativeAd7Container(nativeViewModel: nativeViewModel)
//                        .frame(height: 190)
//                        .background(Color.white.opacity(0.5))
//                } else {
//                    ShimmerPlaceholderView()
//                        .frame(height: 190)
//                        .padding(.horizontal, 8)
//                }
//            }
//        }
//        .onAppear {
//            nativeViewModel.refreshAd()
//        }
//    }
//}

struct ShimmerPlaceholderView: UIViewRepresentable {
    func makeUIView(context: Context) -> ShimmeringView {
        let shimmerView = ShimmeringView()
        shimmerView.frame = .zero
        shimmerView.isShimmering = true
        
        // Create a content UIView (could be skeleton UI: e.g., gray boxes)
        let content = UIView()
        content.backgroundColor = .black
        content.alpha = 0.1
        content.layer.cornerRadius = 8
        
        shimmerView.contentView = content
        
        return shimmerView
    }

    func updateUIView(_ uiView: ShimmeringView, context: Context) {
        // nothing dynamic for now
    }
}




private struct NativeAd7Container: UIViewRepresentable {
    typealias UIViewType = GoogleNativeAdsCustomeView7
    
    @ObservedObject var nativeViewModel: NativeAdViewModel
    
    func makeUIView(context: Context) -> GoogleNativeAdsCustomeView7 {
        return GoogleNativeAdsCustomeView7.instanceFromNib() as! GoogleNativeAdsCustomeView7
    }
    
    func updateUIView(_ nativeAdView: GoogleNativeAdsCustomeView7, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else { return }
        
        nativeAdView.nativeAd = nativeAd
        nativeAdView.setup()
    }
}

