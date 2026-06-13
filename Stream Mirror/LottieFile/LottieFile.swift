//
//  Lottie.swift
//  Snaptube
//
//  Created by Ronik Hirpara on 15/09/25.
//

import Foundation
import Lottie
import SwiftUI


struct LottieFile: UIViewRepresentable {
    var animationFileName: String
    let loopMode: LottieLoopMode
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        let animationView = LottieAnimationView(name: animationFileName)
        animationView.loopMode = loopMode
        animationView.play()
        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        return containerView
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}


struct LottieFile2: UIViewRepresentable {
    var animationFileName: String
    let loopMode: LottieLoopMode
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        let animationView = LottieAnimationView(name: animationFileName)
        animationView.loopMode = loopMode
        animationView.play()
        animationView.contentMode = .scaleAspectFill
        animationView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        return containerView
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}


struct MyLottieFiles {
    static var Splash = "Splash"
    static var connecting = "connecting"
    static var Cast = "Cast"
    static var Cast2 = "Cast2"
    static var WifiTv = "Wifi Tv"
    
}
