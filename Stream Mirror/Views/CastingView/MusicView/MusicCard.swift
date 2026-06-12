//
//  MusicCard.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI
internal import MediaPlayer

struct MusicRow: View {
    
    var artwork: MPMediaItemArtwork?
    var musicName: String
    var artistName: String
    var totalDuration: String
    var imgLike: String
    var onLikeTap: (() -> Void)?
    var imgPlayPause: String
    var onPlayPauseTap: (() -> Void)?
    var showPlayPause: Bool = false
    
    var body: some View {
        ZStack {
            HStack(spacing:15) {
                Image(uiImage: artwork?.image(
                    at: CGSize(width: isIpad() ? 70 : 50, height: isIpad() ? 70 : 50)
                ) ?? UIImage(named: "MusicPH")!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: isIpad() ? 70 : 50, height: isIpad() ? 70 : 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment:.leading,spacing: 5) {
                    Text(musicName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(artistName)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColor.textColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                
                singleButtonCard(image: imgLike) {
                    onLikeTap?()
                }
                if showPlayPause {
                    singleButtonCard(image: imgPlayPause) {
                        onPlayPauseTap?()
                    }
                }
            }
            .padding(.horizontal,15)
        }
        .frame(maxWidth: .infinity)
        .frame(height: isIpad() ? 120 : 80)
        .modifier(GlassCardModifier(cornerRadius: 20))
    }
}
