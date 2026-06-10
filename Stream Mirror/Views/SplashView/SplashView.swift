//
//  SplashView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI
import Lottie

struct SplashView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    @StateObject var vm = SplashViewModel()
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Image("splash")
                    .resizable()
                    .frame(width: isIpad() ? 190 :  160, height: isIpad() ? 160 :  130)
                
                Text(AppStrings.appName)
                    .font(.system(size: isIpad() ? 32 : 28, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.top,15)
                
                Spacer()
                LottieFile(animationFileName: MyLottieFiles.Splash, loopMode: .loop)
                    .frame(width: isIpad() ? 130 :  100, height: isIpad() ? 130 :  100)
                    .rotationEffect(.degrees(0))
            }
        }
        .appScreen()
        .onAppear {
            TVRemoteVM.commonViewModel = commonVM
            TVRemoteVM.configureDiscoveryIfNeeded()
            TVRemoteVM.startDiscovery()
            
            vm.requestTrackingPermission()
        }
        .navigationDestination(isPresented: $vm.navigateToHome) {
            TabbarView()
        }
        .navigationDestination(isPresented: $vm.navigateToLanguage) {
            LanguageView(isOpenFromSplash: true)
        }
        .navigationDestination(isPresented: $vm.navigateToIntro1) {
            IntroMainView()
        }
    }
}

#Preview {
    SplashView()
}
