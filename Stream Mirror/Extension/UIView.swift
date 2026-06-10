//
//  View+Extension.swift
//  CastFlow
//
//  Created by Sumit zalavadiya on 14/04/26.
//

import Foundation
import SwiftUI
import Toast_Swift

extension View {
    
    func gradientBackground(
        colors: [Color] = [.white , .white],
        start: UnitPoint = .leading,
        end: UnitPoint = .trailing,
        cornerRadius: CGFloat = 22
    ) -> some View {
        self
            .background(
                LinearGradient(colors: colors, startPoint: start, endPoint: end)
            )
            .cornerRadius(cornerRadius)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

extension UIView {
    
    public func showToastAtCenter(message: String, duration: TimeInterval = 3.0) {
        var style = ToastStyle()
        style.messageColor = .white
        style.backgroundColor = .black
        self.makeToast(message, duration: duration, position: .center, style: style)
    }
    
    public func showToastAtTop(message: String, duration: TimeInterval = 3.0) {
        var style = ToastStyle()
        style.messageColor = .black
        style.backgroundColor = .white
        self.makeToast(message, duration: duration, position: .top, style: style)
    }
    
}

extension View {
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

extension UIApplication {
    
    func endEditing() {
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
