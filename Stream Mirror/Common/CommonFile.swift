//
//  CommonFile.swift
//  ShadowKit
//
//  Created by Vivek Rakholiya on 23/05/26.
//

import Foundation
import SwiftUI

var str = StringFile()

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

func isIpad() -> Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}

// Language change hone par naya object banao
func onLanguageChanged() {
    str = StringFile() // purana automatically remove, naya assign
    NotificationCenter.default.post(name: .languageChanged, object: nil)
}

func attributedText(
    fullText: String,
    coloredText: String,
    defaultColor: Color = .white,
    highlightColor: Color = .blue,
    font: Font = .system(size: 16)
) -> Text {
    
    let localizedFullText = NSLocalizedString(fullText, comment: "")
    let localizedColoredText = coloredText
    
    // Debug
    print("Full Text: \(localizedFullText)")
    print("Colored Text: \(localizedColoredText)")
    print("Contains: \(localizedFullText.contains(localizedColoredText))")
    
    // Normalize karo Unicode issues ke liye
    let normalizedFull = localizedFullText.precomposedStringWithCanonicalMapping
    let normalizedColored = localizedColoredText.precomposedStringWithCanonicalMapping
    
    guard let range = normalizedFull.range(
        of: normalizedColored,
        options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
        locale: Locale.current
    ) else {
        print("❌ Range not found - Color change nahi hoga")
        return Text(localizedFullText)
            .font(font)
            .foregroundColor(defaultColor)
    }
    
    print("✅ Range found - Color change hoga")
    
    let beforeText = String(normalizedFull[..<range.lowerBound])
    let highlightedPart = String(normalizedFull[range])
    let afterText = String(normalizedFull[range.upperBound...])
    
    return
        Text(beforeText)
        .font(font)
        .foregroundColor(defaultColor)
    +
        Text(highlightedPart)
        .font(font)
        .foregroundColor(highlightColor)
    +
        Text(afterText)
        .font(font)
        .foregroundColor(defaultColor)
}


struct SessionKeys {
    static var language = "language"
    static var intro1 = "intro1"
    static var intro2 = "intro2"
    static var intro3 = "intro3"
    static let appLanguage = "appLanguage"
    static var isPro = "isPro"
    static var interAdId = "interAdId"
    static var afterClick = "afterClick"
    
    static var isPasswordOn = "isPasswordOn"
    static var isPasswordSet = "isPasswordSet"
    
    //Manage App openAD
    static let isHomeOpened = "isHomeOpened"
}

struct placeholderView: View {
    var image: String
    var title: String
    var title2: String
    var isTitle2: Bool
    var height: CGFloat = 120
    var width: CGFloat = 120
    var body: some View {
        VStack(spacing: 10) {
            
            Image(image)
                .resizable()
                .frame(width: isIpad() ? width + 20 : width, height: isIpad() ? height + 20 : height)
            
            VStack(alignment:.center,spacing: 5) {
                Text(title)
                    .font(.system(size: isIpad() ? 22 : 16))
                    .foregroundStyle(.white)
                
                if isTitle2 {
                    Text(title2)
                        .font(.system(size: isIpad() ? 18 : 12))
                        .foregroundStyle(AppColor.textColor)
                        .padding(.horizontal,15)
                        .lineLimit(nil)
                }
            }
        }
        .multilineTextAlignment(.center)
    }
}


struct GlassCardModifier: ViewModifier {
    
    var cornerRadius: CGFloat = 30
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(.white.opacity(0.10))
                .cornerRadius(cornerRadius)
                .glassEffect(
                    .clear.interactive(),
                    in: RoundedRectangle(cornerRadius: cornerRadius)
                )
        } else {
            content
//                .background(Blur())
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct CustomCorner: SwiftUI.Shape {
    
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

func showToastAtCenter(message: String, duration: TimeInterval = 3.0) {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = scene.windows.first,
          let view = window.rootViewController?.view else { return }
    
    view.showToastAtCenter(message: message, duration: duration)
}

func showToastAtTop(message: String, duration: TimeInterval = 3.0) {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = scene.windows.first,
          let view = window.rootViewController?.view else { return }
    
    view.showToastAtTop(message: message, duration: duration)
}


struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterialLight
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // ✅ iPad ke liye zaroori hai
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView() // ya koi specific view
            popover.sourceRect = CGRect(
                x: UIScreen.main.bounds.midX,
                y: UIScreen.main.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

func shareContent(_ text: String) {
    
    let activityVC = UIActivityViewController(
        activityItems: [text],
        applicationActivities: nil
    )
    
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let root = scene.windows.first?.rootViewController else {
        return
    }
    
    root.present(activityVC, animated: true)
}

class AppSession {
    static let shared = AppSession()

    var hasShownPremium = false
    var hasShownRateAlert = false
}

func haptic(){
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    impactMed.impactOccurred()
}
