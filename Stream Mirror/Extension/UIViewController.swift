//
//  UINavigationController+.swift
//  SmartRemote
//
//  Created by Sumit zalavadiya on 27/03/26.
//

import Foundation
import UIKit
import SwiftUI

final class SwipeBackDisabler: NSObject, UIGestureRecognizerDelegate {
    
    static let shared = SwipeBackDisabler()
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false // 🚫 Always block swipe
    }
}

extension UIViewController {
    
    func findNavigationController() -> UINavigationController? {
        
        if let nav = self as? UINavigationController {
            return nav
        }
        
        for child in children {
            if let nav = child.findNavigationController() {
                return nav
            }
        }
        
        return navigationController
    }
}

struct DisableSwipeBack: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        
        DispatchQueue.main.async {
            applyDisable()
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            applyDisable()
        }
    }
    
    private func applyDisable() {
        
        guard let nav = findNavigationController() else { return }
        
        // 🔥 IMPORTANT: enabled + delegate override
        nav.interactivePopGestureRecognizer?.isEnabled = true
        nav.interactivePopGestureRecognizer?.delegate = SwipeBackDisabler.shared
    }
    
    private func findNavigationController() -> UINavigationController? {
        
        let scenes = UIApplication.shared.connectedScenes
        
        guard let windowScene = scenes.first as? UIWindowScene else { return nil }
        
        return windowScene.windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController?
            .findNavigationController()
    }
}

struct EnableSwipeBack: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        
        DispatchQueue.main.async {
            applyEnable()
        }
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            applyEnable()
        }
    }
    
    func applyEnable() {
        
        guard let nav = findNavigationController() else { return }
        
        nav.interactivePopGestureRecognizer?.delegate = nil
        nav.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func findNavigationController() -> UINavigationController? {
        
        let scenes = UIApplication.shared.connectedScenes
        
        guard let windowScene = scenes.first as? UIWindowScene else { return nil }
        
        return windowScene.windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController?
            .findNavigationController()
    }
}
