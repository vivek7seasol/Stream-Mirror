//
//  SetTimerView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI

struct SetTimerView: View {

    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @Binding var selectedSeconds: Int
    var onStart: (() -> Void)?
    @State private var seconds = ""
    @State private var selectedPreset: Int? = 7
    @State private var showValidationError = false
    private var enteredSeconds: Int? {
        Int(seconds)
    }
    
    var body: some View {

        ZStack {

            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                VStack(spacing: isIpad() ? 40 : 20) {

                    // Close Button
                    HStack {

                        Spacer()

                        singleButtonCard(image: "close") {

                            withAnimation(.spring()) {
                                isPresented = false
                            }
                        }
                    }

                    // Title
                    VStack(spacing: 8) {

                        Text(str.SetTimer)
                            .font(.system(size: isIpad() ? 28 : 20, weight: .semibold))
                            .foregroundColor(.white)

                        Text(str.SetTimer2)
                            .font(.system(size: isIpad() ? 20 : 12))
                            .foregroundColor(AppColor.textColor)
                            .multilineTextAlignment(.center)
                    }

                    // Quick Presets
                    VStack(alignment: .leading, spacing: 14) {

                        HStack(spacing: 8) {

                            Rectangle()
                                .fill(.white)
                                .frame(width: isIpad() ? 7 : 4, height: isIpad() ? 30 : 20)
                                .cornerRadius(10)

                            Text(str.QuickPresets)
                                .font(.system(size: isIpad() ? 28 : 22, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        HStack(spacing: 12) {

                            presetButton(
                                "7 Seconds",
                                selected: selectedPreset == 7
                            ) {
                                selectedPreset = 7
                                seconds = "7"
                            }

                            presetButton(
                                "10 Seconds",
                                selected: selectedPreset == 10
                            ) {
                                selectedPreset = 10
                                seconds = "10"
                            }
                        }
                    }

                    // Enter Seconds
                    VStack(alignment: .leading, spacing: 14) {

                        HStack(spacing: 8) {

                            Rectangle()
                                .fill(.white)
                                .frame(width: isIpad() ? 7 : 4, height: isIpad() ? 30 : 20)
                                .cornerRadius(10)

                            Text(str.EnterSeconds)
                                .font(.system(size: isIpad() ? 28 : 22, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        HStack {

                            TextField(
                                "E.g. 15",
                                text: $seconds
                            )
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .onChange(of: seconds) { value in

                                if let intValue = Int(value) {
                                    showValidationError = !(5...30).contains(intValue)
                                } else {
                                    showValidationError = false
                                }
                            }

                            Text("Sec")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 18)
                        .frame(height: isIpad() ? 60 : 52)
                        .background(.white.opacity(0.08))
                        .overlay {
                            Capsule()
                                .stroke(
                                    .white.opacity(0.15),
                                    lineWidth: 1
                                )
                        }
                        .clipShape(Capsule())

                        HStack(spacing: 6) {

                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: isIpad() ? 18 : 12))

                            Text(str.Minimum5secondsrequired)
                                .font(.system(size: isIpad() ? 20 : 12))
                                .foregroundColor(
                                    showValidationError ? .red : .white.opacity(0.7)
                                )
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    
                    commonButtonFile(text: str.StartTimer) {
                        
                        let value = Int(seconds) ?? selectedPreset ?? 7

                        guard value >= 5 && value <= 30 else {

                            withAnimation {
                                showValidationError = true
                            }

                            return
                        }

                        showValidationError = false

                        selectedSeconds = value

                        onStart?()

                        isPresented = false

                    }
                    .padding(.bottom,40)
                }
                .padding( isIpad() ? 30 : 24)
                .background(
                    DeviceListBG()
                    
                )
                .clipShape(
                    CustomCorner(
                        corners: [.topLeft, .topRight],
                        radius: 40
                    )
                )
                .offset(y:60)
            }
            
        }
        
    }

    @ViewBuilder
    private func presetButton(
        _ title: String,
        selected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {

        Button {

            action()

        } label: {

            Text(title)
                .font(.system(size: isIpad() ? 24 : 16, weight: .medium))
                .foregroundColor(selected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: isIpad() ? 58 : 48)
                .background(
                    selected
                    ? AnyView(
                        Capsule()
                            .fill(.white)
                    )
                    : AnyView(
                        Capsule()
                            .fill(.white.opacity(0.08))
                            .overlay {
                                Capsule()
                                    .stroke(
                                        .white.opacity(0.15),
                                        lineWidth: 1
                                    )
                            }
                    )
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SetTimerView(isPresented: .constant(false), selectedSeconds: .constant(0))
}
