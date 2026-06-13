//
//  IPTVCard.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI

struct IPTVChannelCard: View {
    
    var image: String
    var title: String
    var isURLImage: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            
            ZStack {
                VStack {
                    if isURLImage {
                        
                        AsyncImage(url: URL(string: image)) { phase in
                            
                            switch phase {
                                
                            case .success(let loadedImage):
                                
                                loadedImage
                                    .resizable()
                                    .scaledToFit()
                                
                            default:
                                
                                Image("channel")
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .frame(width: isIpad() ? 70 : 50, height: isIpad() ? 70 : 50)
                    }
                    
                    Text(title)
                        .font(.system(size: 14,weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal,3)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 130 : 110)
            .modifier(GlassCardModifier(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}


struct catCountryCard: View {
    
    let title: String
    let channel: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                HStack {
                    VStack(alignment:.leading,spacing: 5) {
                        Text(title)
                            .font(.system(size: isIpad() ? 22 : 16,weight: .medium))
                            .foregroundStyle(.white)
                        
                        Text(channel + " " + str.Channels)
                            .font(.system(size: 12))
                            .foregroundStyle(AppColor.textColor)
                    }
                    Spacer()
                    
                    Image("next")
                        .resizable()
                        .frame(width: isIpad() ? 30 : 20,height: isIpad() ? 30 : 20)
                }
                .padding(.horizontal,15)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 70 : 60)
            .modifier(GlassCardModifier(cornerRadius: 20))
            .padding(.horizontal,15)
        }

    }
}
