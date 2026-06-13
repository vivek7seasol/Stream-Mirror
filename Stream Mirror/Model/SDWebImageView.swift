//
//  SDWebImageView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import Foundation
import SDWebImage
import SwiftUI

struct SDWebImageView: UIViewRepresentable {
    
    let url: String
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.sd_setImage(
            with: URL(string: url),
            placeholderImage: UIImage(named: "imagePH"),
            options: [.highPriority, .retryFailed]
        ) { image, error, _, _ in
            if error != nil || image == nil {
                // ✅ Failure pe bhi placeholder
                DispatchQueue.main.async {
                    uiView.image = UIImage(systemName: "photo")
                    uiView.tintColor = .gray
                    uiView.contentMode = .center
                }
            }
        }
    }
}
