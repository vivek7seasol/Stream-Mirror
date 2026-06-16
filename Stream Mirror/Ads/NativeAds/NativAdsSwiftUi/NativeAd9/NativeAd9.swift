//
//  NativeAd9.swift
//  Screen Mirroring Casting
//
//  Created by Parthiv Akbari on 17/10/25.
//

import Foundation
import ShimmerSwift
import SwiftUI

struct NativeAd9: View {
    @StateObject private var nativeViewModel = NativeAdViewModel()
    @AppStorage(SessionKeys.isPro) var isPro = false
    @State var hasLoadedOnce = false
    
    var body: some View {
        VStack {
            if !isPro {
                if let _ = nativeViewModel.secondNativeAd {
                    NativeAd9Container(nativeViewModel: nativeViewModel)
                        .frame(height: 190)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(8)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.3), value: nativeViewModel.secondNativeAd)
                } else if nativeViewModel.didFailToSecondLoad {
                    Color.clear
                        .frame(height: 0)
                        .animation(.easeOut(duration: 0.3), value: nativeViewModel.didFailToSecondLoad)
                } else {
                    ShimmerPlaceholderView()
                        .frame(height: 190)
                        .padding(.horizontal, 8)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: nativeViewModel.secondNativeAd)
                }
            }
        }
        .onAppear {
            if !hasLoadedOnce {
                nativeViewModel.refreshSecondNative()
                hasLoadedOnce = true
            }
        }
    }
}

private struct NativeAd9Container: UIViewRepresentable {
    typealias UIViewType = GoogleNativeAdsCustomeView9
    
    @ObservedObject var nativeViewModel: NativeAdViewModel
    
    func makeUIView(context: Context) -> GoogleNativeAdsCustomeView9 {
        return GoogleNativeAdsCustomeView9.instanceFromNib() as! GoogleNativeAdsCustomeView9
    }
    
    func updateUIView(_ nativeAdView: GoogleNativeAdsCustomeView9, context: Context) {
        guard let nativeAd = nativeViewModel.secondNativeAd else { return }
        
        nativeAdView.nativeAd = nativeAd
        nativeAdView.setup()
    }
}

