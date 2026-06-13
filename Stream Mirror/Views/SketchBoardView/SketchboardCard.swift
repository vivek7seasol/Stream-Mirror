//
//  SketchboardCard.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI

struct DrawingListRow: View {

    var thumbnail: UIImage
    var fileName: String
    var fileSize: String

    var shareAction: () -> Void
    var deleteAction: () -> Void
    var buttonAction: () -> Void

    var body: some View {

        Button {
            buttonAction()
        } label: {

            ZStack(alignment: .topTrailing) {

                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .clipped()

                Menu {

                    Button {
                        shareAction()
                    } label: {
                        Label(
                            "Share",
                            systemImage: "square.and.arrow.up"
                        )
                    }

                    Button(role: .destructive) {
                        deleteAction()
                    } label: {
                        Label(
                            "Delete",
                            systemImage: "trash"
                        )
                    }

                } label: {

                    Image("more")
                        .resizable()
                        .frame(width: isIpad() ? 20 : 14, height: isIpad() ? 20 : 14)
                        .frame(width: isIpad() ? 30 : 24, height: isIpad() ? 30 : 24)
                        .clipShape(Circle())
                        .modifier(GlassCardModifier(cornerRadius: isIpad() ? 15 : 12))
                }
                .padding(.trailing,15)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 165)
            .modifier(
                GlassCardModifier(
                    cornerRadius: 30
                )
            )
        }
        .buttonStyle(.plain)
    }
}
