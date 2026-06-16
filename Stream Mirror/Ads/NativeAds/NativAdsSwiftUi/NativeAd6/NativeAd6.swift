//
//  NativeAd6.swift
//  Screen Mirroring Casting
//
//  Created by Ronik Hirpara on 18/10/25.
//

import Foundation
import SwiftUI

struct NativeAd6: View {
    @StateObject private var nativeViewModel = NativeAdViewModel()
    @AppStorage(SessionKeys.isPro) var isPro = false
    @State var hasLoadedOnce = false

    var body: some View {
        VStack{
            if !isPro{
                if let _ = nativeViewModel.smallNativeAd {
                    NativeAd6Container(nativeViewModel: nativeViewModel)
                        .frame(height: isIpad() ? 110 : 82)
                        .background(Color.white.opacity(0.5))
                }else if nativeViewModel.didFailToSmallLoad {
                    Color.clear
                        .frame(height: 0)
                        .animation(.easeOut(duration: 0.3), value: nativeViewModel.didFailToSmallLoad)
                }  else {
                    ShimmerPlaceholderView()
                        .frame(height: isIpad() ? 110 : 82)
                        .padding(.horizontal, 8)
                }
            }
        }
            .onAppear {
                if !hasLoadedOnce {
                    nativeViewModel.refreshSmallNative()
                    hasLoadedOnce = true
                }
            }
    }
    
    private func refreshAd() {
        nativeViewModel.refreshSmallNative()
    }
}

private struct NativeAd6Container: UIViewRepresentable {
    typealias UIViewType = GoogleNativeAdsCustomeView6
    
    @ObservedObject var nativeViewModel: NativeAdViewModel
    
    func makeUIView(context: Context) -> GoogleNativeAdsCustomeView6 {
        return GoogleNativeAdsCustomeView6.instanceFromNib() as! GoogleNativeAdsCustomeView6
    }
    
    func updateUIView(_ nativeAdView: GoogleNativeAdsCustomeView6, context: Context) {
        guard let nativeAd = nativeViewModel.smallNativeAd else { return }
        
        nativeAdView.nativeAd = nativeAd
        nativeAdView.setup()
    }
}
