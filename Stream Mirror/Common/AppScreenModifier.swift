//
//  AppScreenModifier.swift
//  UtilityBox
//
//  Created by Vivek Rakholiya on 05/06/26.
//

import Foundation
import SwiftUI

struct AppScreenModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        ZStack {
//            AppColor.AppBGColor
            Image("AppBG")
                .resizable()
                .ignoresSafeArea()
            
            content
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension View {
    func appScreen() -> some View {
        modifier(AppScreenModifier())
    }
}
