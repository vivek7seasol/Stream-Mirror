//
//  broadCastPickerVM.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 07/05/26.
//

import Foundation
import ReplayKit
import SwiftUI

struct BroadcastPickerViewModel: UIViewRepresentable {
    let preferredExtension: String
    @Binding var startBroadcast: Bool
    @Binding var stopBroadcast: Bool

    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: .zero)
        picker.preferredExtension = AppStrings.appExtensionPackageName
        picker.showsMicrophoneButton = false
        picker.isHidden = true
        context.coordinator.pickerView = picker
        return picker
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {
        if startBroadcast {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                context.coordinator.startBroadcast() // ✅ ye toggle hai - start bhi stop bhi
                startBroadcast = false
            }
        }
        // stopBroadcast wala block hata do - zarurat nahi
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        weak var pickerView: RPSystemBroadcastPickerView?

        func startBroadcast() {
            guard let picker = pickerView else { return }
            for subview in picker.subviews {
                if let button = subview as? UIButton {
                    button.sendActions(for: .touchUpInside)
                    break
                }
            }
        }

        func stopBroadcast() {  // 👈 same button tap = toggle stop
            RPScreenRecorder.shared().stopCapture { error in
                if let error = error {
                    print("❌ Stop error: \(error)")
                } else {
                    print("✅ Mirroring stopped")
                }
            }
        }
    }
}

