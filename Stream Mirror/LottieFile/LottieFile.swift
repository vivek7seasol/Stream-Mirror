//
//  Lottie.swift
//  Snaptube
//
//  Created by Ronik Hirpara on 15/09/25.
//

import Foundation
import Lottie
import SwiftUI


struct MyLottieView: UIViewRepresentable {
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
struct MyLottieView2: UIViewRepresentable {
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


struct MyLottie {
    static var Splashlottie = "Splashlottie"
    static var Cast = "Cast"
    static var Loading = "Loading"
    static var music_wave = "music_wave"
    static var Signal = "Signal"
    static var cast_to_tv = "cast_to_tv"
}
