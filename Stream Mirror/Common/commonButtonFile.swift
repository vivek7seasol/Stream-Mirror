//
//  commonButtonFile.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

struct commonButtonFile: View {
    
    var text: String
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            
            ZStack {
                Text(text)
                    .font(.system(size: isIpad() ? 22 : 16,weight: .medium))
                    .foregroundStyle(AppColor.textColor2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 70 : 50)
            .background(
                Image("btnBG")
                .resizable()
                .scaledToFill()
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct singleButtonCard: View {
    
    let image: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(image)
                .resizable()
                .frame(width: isIpad() ? 28 : 24, height: isIpad() ? 28 : 24)
                .frame(width: isIpad() ? 44 : 40, height: isIpad() ? 44 : 40)
                .modifier(GlassCardModifier(cornerRadius: isIpad() ? 22 : 20))
                .clipShape(RoundedRectangle(cornerRadius: isIpad() ? 22 : 20))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    commonButtonFile(text: str.Next, action: {})
}
