//
//  PlayerView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import Foundation
import AVKit
import SwiftUI

struct CustomVideoPlayer: UIViewRepresentable {

    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.setPlayer(player)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.setPlayer(player)
    }
}

// MARK: - AVPlayerLayer wrapper
class PlayerUIView: UIView {
    
    private var playerLayer: AVPlayerLayer?
    
    override class var layerClass: AnyClass {
        AVPlayerLayer.self   // ✅ Layer directly = no controls at all
    }
    
    var avPlayerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    func setPlayer(_ player: AVPlayer) {
        avPlayerLayer.player = player
        avPlayerLayer.videoGravity = .resizeAspectFill
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avPlayerLayer.frame = bounds
    }
}
