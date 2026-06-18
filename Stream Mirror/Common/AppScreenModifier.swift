//
//  AppScreenModifier.swift
//  UtilityBox
//
//  Created by Vivek Rakholiya on 05/06/26.
//

import Foundation
import SwiftUI

struct AppScreenModifier<PresentedView: View>: ViewModifier {

    var disableSwipeBack: Bool = false
    var isPresented: Binding<Bool>?
    let destination: (() -> PresentedView)?

    func body(content: Content) -> some View {
        ZStack {
            Image("AppBG")
                .resizable()
                .ignoresSafeArea()
            
            content
        }
        .background(
            disableSwipeBack
            ? AnyView(DisableSwipeBack())
            : AnyView(EnableSwipeBack())
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(
            isPresented: isPresented ?? .constant(false)
        ) {
            if let destination {
                destination()
            }
        }
        .presentationDetents([.height(isIpad() ? 830 : 700)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(LinearGradient(colors: [Color("#222222"), Color("#1A1A1A"), Color("#111111")], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

extension View {

    func appScreen(disableSwipeBack: Bool = false) -> some View {
        modifier(
            AppScreenModifier<EmptyView>(
                disableSwipeBack: disableSwipeBack,
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
