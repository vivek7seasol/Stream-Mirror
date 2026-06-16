//
//  CommonStatusView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import SwiftUI

struct CommonStatusView<Trailing: View>: View {

    @Environment(\.dismiss) var dismiss

    var onBack: (() -> Void)? = nil
    var onCast: (() -> Void) = {}
    var title: String
    var isCastingShow: Bool = true

    @ViewBuilder var trailing: Trailing

    init(
        title: String,
        onBack: (() -> Void)? = nil,
        onCast: @escaping (() -> Void) = {},
        isCastingShow: Bool = true,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.onBack = onBack
        self.onCast = onCast
        self.isCastingShow = isCastingShow
        self.trailing = trailing()
    }
    
    var body: some View {
        
        ZStack {

            Text(title)
                .font(.system(size: isIpad() ? 28 : 22, weight: .semibold))
                .foregroundStyle(.white)

            HStack {

                singleButtonCard(image: "back") {

                    if let onBack {
                        onBack()
                    } else {
                        dismiss()
                    }
                }

                Spacer()

                HStack(spacing: 10) {

                    trailing

                    if isCastingShow {
                        singleButtonCard(image: "Cast") {
                            onCast()
                        }
                    }
                }
                .frame(minWidth: 90, alignment: .trailing)
            }
        }
        .padding(.horizontal, 15)
    }
}

#Preview {
    CommonStatusView(title: "YouTube")
}
