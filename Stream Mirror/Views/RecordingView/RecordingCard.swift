//
//  RecordingCard.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//
import SwiftUI
import AVKit

struct VideoPlayerView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {

        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: url)
        controller.player?.play()

        return controller
    }

    func updateUIViewController(
        _ uiViewController: AVPlayerViewController,
        context: Context
    ) {}
}
struct RecordingLisRow: View {
    
    var image: String
    var fileName: String
    var fileSize: String
    var shareAction: () -> Void
    var deleteAction: () -> Void
    var buttonAction: (() -> Void)
    
    var body: some View {
        Button {
            buttonAction()
        } label: {
            
            ZStack {
                
                HStack {
                    Image(image)
                        .resizable()
                        .frame(width: isIpad() ? 55 : 45,height: isIpad() ? 55 : 45)
                    
                    VStack(alignment:.leading,spacing: 5) {
                        Text(fileName)
                            .font(.system(size: isIpad() ? 22 : 16,weight: .medium))
                            .foregroundStyle(.white)
                        
                        Text(fileSize)
                            .font(.system(size: isIpad() ? 18 : 12))
                            .foregroundStyle(AppColor.textColor)
                    }
                    Spacer()
                    Menu {

                        Button {

                            shareAction()   // Share Action

                        } label: {

                            Label(
                                "Share".localized,
                                systemImage: "square.and.arrow.up"
                            )
                        }

                        Button(role: .destructive) {

                            deleteAction()   // Delete Action

                        } label: {

                            Label(
                                "Delete".localized,
                                systemImage: "trash"
                            )
                        }

                    } label: {

                        Image("more")
                            .resizable()
                            .frame(width: isIpad() ? 30 : 20, height: isIpad() ? 30 : 20)
                            .foregroundStyle(AppColor.textColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 75 : 65)
            .modifier(GlassCardModifier(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}


struct RecordingSettingCard: View {

    let image: String
    let title: String
    var isToggle: Bool = true

    @Binding var isOn: Bool

    var action: (() -> Void)? = nil

    var body: some View {

        Button {
            action?()
        } label: {

            HStack(spacing: 15) {

                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isIpad() ? 60 : 50,
                           height: isIpad() ? 60 : 50)

                Text(title)
                    .font(.system(size: isIpad() ? 22 : 16,
                                  weight: .medium))
                    .foregroundStyle(.white)

                Spacer()

                if isToggle {

                    Toggle("", isOn: $isOn)
                        .labelsHidden()

                } else {

                    Image("next")
                        .resizable()
                        .frame(width: isIpad() ? 26 : 20,
                               height: isIpad() ? 26 : 20)
                }
            }
            .padding(.horizontal, 15)
            .frame(height: isIpad() ? 90 : 70)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
