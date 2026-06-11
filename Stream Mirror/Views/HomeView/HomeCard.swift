//
//  HomeCard.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

struct connectDeviceCard: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            
            ZStack {
                HStack {
                    Image("link")
                        .resizable()
                        .frame(width: isIpad() ? 20 : 16, height: isIpad() ? 20 : 16)
                    
                    Text(str.Connecttodevice)
                        .font(.system(size: isIpad() ? 18 : 12))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                }
                .padding(.horizontal,15)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 50 : 44)
            .modifier(GlassCardModifier(cornerRadius: isIpad() ? 25 : 22))
            .padding(.horizontal,20)
        }
        .buttonStyle(.plain)
    }
}

struct firstCard: View {
    
    let mirrorAction: () -> Void
    let YTAction: () -> Void
    let FileAction: () -> Void
    
    var body: some View {
        HStack(spacing:15) {
            Button {
                mirrorAction()
            } label: {
                ZStack {
                    VStack(alignment:.leading,spacing: 5) {
                        Text(str.MirrorScreen)
                            .font(.system(size: isIpad() ? 22 : 16,weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.top)
                        
                        Text(str.RealtimescreenMirroring)
                            .font(.system(size: isIpad() ? 18 : 12))
                            .foregroundStyle(.white.opacity(0.70))
                        
                        Image("mirror")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: isIpad() ? 230 : 210)
                .gradientBackground(colors: [Color("#00D9F8"),Color("#6733FF")],start: .topLeading,end: .bottomTrailing,cornerRadius: 25)
            }
            .buttonStyle(.plain)
            
            VStack(spacing:15) {
                Button {
                    YTAction()
                } label: {
                    ZStack {
                        VStack(alignment:.leading,spacing: 5) {
                            Text(str.Youtube)
                                .font(.system(size: isIpad() ? 22 : 16,weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.top)
                            HStack(alignment:.top) {
                                Text(str.Enjoyvideosanytime)
                                    .font(.system(size: isIpad() ? 18 : 12))
                                    .foregroundStyle(.white.opacity(0.70))
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image("yt")
                                    .resizable()
                                    .scaledToFit()
                                    .offset(x:10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isIpad() ? 120 : 100)
                    .gradientBackground(colors: [Color("#FF716E"),Color("#E82725")],start: .topLeading,end: .bottomTrailing,cornerRadius: 25)
                }
                .buttonStyle(.plain)
                
                Button {
                    FileAction()
                } label: {
                    ZStack {
                        VStack(alignment:.leading,spacing: 5) {
                            Text(str.FileLibrary)
                                .font(.system(size: isIpad() ? 22 : 16,weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.top)
                            HStack(alignment:.top) {
                                Text(str.Allfilesinoneplace)
                                    .font(.system(size: isIpad() ? 18 : 12))
                                    .foregroundStyle(.white.opacity(0.70))
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image("file")
                                    .resizable()
                                    .scaledToFit()
                                    .offset(x:10)
                            }
                            
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isIpad() ? 120 : 100)
                    .gradientBackground(colors: [Color("#FFB235"),Color("#FF7406")],start: .topLeading,end: .bottomTrailing,cornerRadius: 25)
                }
                .buttonStyle(.plain)
            }

        }
        .padding(.horizontal,15)
        .padding(.vertical,15)
    }
}

struct castingCard: View {
    
    let title: String
    let image: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack {
                Image(image)
                    .resizable()
                    .frame(width: isIpad() ? 58 : 54,height: isIpad() ? 58 : 54)
                
                Text(title)
                    .font(.system(size: isIpad() ? 18 : 12,weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    connectDeviceCard(action: {})
}
