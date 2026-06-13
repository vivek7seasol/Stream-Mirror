//
//  ShareSheet.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 13/06/26.
//

import Foundation
import UIKit
import SwiftUI

struct DrawingShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
