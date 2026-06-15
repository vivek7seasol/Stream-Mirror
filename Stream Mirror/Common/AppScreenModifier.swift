//
//  AppScreenModifier.swift
//  UtilityBox
//
//  Created by Vivek Rakholiya on 05/06/26.
//

import Foundation
import SwiftUI

struct AppScreenModifier<PresentedView: View>: ViewModifier {

    var isPresented: Binding<Bool>?
    let destination: (() -> PresentedView)?

    func body(content: Content) -> some View {
        ZStack {
            Image("AppBG")
                .resizable()
                .ignoresSafeArea()

            content
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(
            isPresented: isPresented ?? .constant(false)
        ) {
            if let destination {
                destination()
            }
        }
    }
}

extension View {

    func appScreen() -> some View {
        modifier(
            AppScreenModifier<EmptyView>(
                isPresented: nil,
                destination: nil
            )
        )
    }

    func appScreen<PresentedView: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder destination: @escaping () -> PresentedView
    ) -> some View {

        modifier(
            AppScreenModifier(
                isPresented: isPresented,
                destination: destination
            )
        )
    }
}
