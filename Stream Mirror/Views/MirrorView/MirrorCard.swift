//
//  MirrorCard.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import SwiftUI

struct MirrorCard: View {

    let image: String
    let title: String
    let title2: String

    @Binding var isOn: Bool

    var body: some View {

        ZStack {
            
            HStack(spacing: 10) {
                
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isIpad() ? 60 : 50,height: isIpad() ? 60 : 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(title2)
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.textColor)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }
            .padding(.horizontal, 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical,15)
        .modifier(GlassCardModifier(cornerRadius: 28))
        .padding(.horizontal, 15)
    }
}

enum QualityType: String, CaseIterable {
    case optimized = "Optimized"
    case balanced = "Balanced"
    case best = "Best"
}

struct QualityCard: View {

    @Binding var selectedQuality: QualityType

    var body: some View {

        HStack(spacing: 0) {

            ForEach(QualityType.allCases, id: \.self) { quality in

                Button {

                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedQuality = quality
                    }

                    if let userDefaults = UserDefaults(
                        suiteName: AppStrings.groupID
                    ) {

                        switch quality {

                        case .optimized:
                            userDefaults.set("Low", forKey: "selectedQuality")

                        case .balanced:
                            userDefaults.set("Medium", forKey: "selectedQuality")

                        case .best:
                            userDefaults.set("High", forKey: "selectedQuality")
                        }
                    }

                } label: {

                    Text(quality.rawValue)
                        .font(.system(size: isIpad() ? 20 : 16,
                                      weight: .medium))
                        .foregroundColor(
                            selectedQuality == quality
                            ? .black
                            : .white
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: isIpad() ? 70 : 55)
                        .background {

                            if selectedQuality == quality {

                                Capsule()
                                    .fill(.white)
                                    .padding(4)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth:.infinity)
        .frame(height: isIpad() ? 70 : 55)
        .background(.white.opacity(0.10))
        .modifier(
            GlassCardModifier(
                cornerRadius: isIpad() ? 35 : 28
            )
        )
//        .padding(.horizontal, 15)
    }
}
