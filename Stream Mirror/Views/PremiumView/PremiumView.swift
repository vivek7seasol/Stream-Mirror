//
//  PremiumView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 16/06/26.
//

import SwiftUI
import StoreKit

struct PremiumView: View {
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var proVM = PremiumViewModel()
    
    var body: some View {
        ZStack {
            VStack(spacing:10) {
                HStack(alignment: .top) {
                    
                    Button {
                        proVM.restore()
                    } label: {
                        ZStack {
                            Text("Restore")
                                .font(.system(size: isIpad() ? 18 : 12))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 15)
                        .frame(height: isIpad() ? 50 : 30)
                        .modifier(GlassCardModifier(cornerRadius: isIpad() ? 25 : 15))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer(minLength: 0)
                    
                    Image("premium2")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: isIpad() ? 140 : 120,
                            height: isIpad() ? 120 : 100
                        )
                    
                    Spacer(minLength: 85)
                    
                    singleButtonCard(image: "close") {
                        dismiss()
                    }
                }
                .padding(.horizontal, 15)
                
                ScrollView(.vertical,showsIndicators: false) {
                    VStack(spacing:10) {
                        attributedText(fullText: "Unlock Premium Mirroring", coloredText: "Premium",defaultColor: .white,highlightColor: Color("#FFCC3D"),font: .system(size: isIpad() ? 32 : 24,weight: .bold))
                        
                        Text("Enjoy seamless casting without limits.")
                            .font(.system(size: isIpad() ? 20 : 14))
                            .foregroundStyle(AppColor.textColor)
                        
                        ZStack(alignment: .topTrailing) {

                            RoundedRectangle(cornerRadius: 35)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color("#FFCC3D"), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 2
                                )
                                

                            // Top-right premium icon
                            Image("diamond")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .offset(x: 13, y: -18)

                            VStack(spacing: 18) {

                                Text("Premium Features")
                                    .font(.system(size: isIpad() ? 32 : 26, weight: .bold))
                                    .foregroundColor(.white)

                                featureRow("Unlimited Screen Mirroring")
                                featureRow("Smart TV Controller")
                                featureRow("Wireless TV Casting")
                                featureRow("Ad-Free Experience")
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 30)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 15)
                        
                        VStack(spacing: 10) {
                            
                            ForEach(proVM.products, id: \.productIdentifier) { product in
                                
                                planCard(
                                    lbl1: product.localizedPrice,
                                    lbl2: getSubtitle(product.productIdentifier),
                                    isSelected: proVM.selectedProduct?.productIdentifier == product.productIdentifier,
                                    showBestValue: product.productIdentifier == Products.smart_view_lifeTime.rawValue
                                ) {
                                    proVM.selectedProduct = product
                                }
                            }
                        }
                        
                        commonButtonFile(text: "Subscribe Now") {
                            proVM.makePurchase()
                        }
                        .padding(.horizontal,15)
                        .padding(.bottom,15)
                        
                        VStack(spacing:8) {
                            HStack {
                                Divider()
                                    .frame(width: isIpad() ? 7 :4,height: isIpad() ? 26 : 22)
                                    .background(.white)
                                    .cornerRadius(15)
                                
                                Text("Pre Paid Plan")
                                    .font(.system(size: isIpad() ? 24 : 18,weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity,alignment: .leading)
                            
                            
                            Text("Subscription options are available only through the App Store. Payment will be charged to your Apple ID account once your subscription starts. Subscriptions renew automatically at the same price and duration unless canceled at least 24 hours before the current period ends. You can manage or cancel your subscription anytime in your Apple ID account settings. By subscribing, you agree to our Privacy Policy and Terms.")
                                .font(.system(size: isIpad() ? 20 : 14))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal,15)
                        
                        VStack(alignment:.leading,spacing: 8) {
                            HStack {
                                Divider()
                                    .frame(width: isIpad() ? 7 :4,height: isIpad() ? 26 : 22)
                                    .background(.white)
                                    .cornerRadius(15)
                                
                                Text("How to manage my subscription?")
                                    .font(.system(size: isIpad() ? 24 : 18,weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity,alignment: .leading)
                            
                            VStack(alignment:.leading,spacing: 8) {
                                Text("1. Open the Settings app on your device.")
                                Text("2. Tap your name at the top.")
                                Text("3. Tap Subscriptions.")
                                Text("4. Tap the subscription that you want to manage.")
                            }
                            .font(.system(size: isIpad() ? 20 : 14))
                            .foregroundStyle(.white)
                        }
                        .padding(.horizontal,15)
                        .padding(.vertical,15)
                    }
                }
                
                HStack(spacing:25) {
                    Button {
                        openUrlInSafari(strUrl: TEARMS)
                    } label: {
                        Text("Terms of use")
                            .font(.system(size: isIpad() ? 20 : 14,weight: .medium))
                            .foregroundStyle(AppColor.textColor)
                    }
                    Divider()
                        .background(AppColor.textColor)
                        .frame(width: isIpad() ? 2 : 1,height: isIpad() ? 30 : 20)
                    Button {
                        openUrlInSafari(strUrl: PRIVACYPOLICY)
                    } label: {
                        Text("Privacy policy")
                            .font(.system(size: isIpad() ? 20 : 14,weight: .medium))
                            .foregroundStyle(AppColor.textColor)
                    }
                    Divider()
                        .background(AppColor.textColor)
                        .frame(width: isIpad() ? 2 : 1,height: isIpad() ? 30 : 20)
                    Button {
                        openUrlInSafari(strUrl: EULA)
                    } label: {
                        Text("Eula")
                            .font(.system(size: isIpad() ? 20 : 14,weight: .medium))
                            .foregroundStyle(AppColor.textColor)
                    }
                }
                
                .padding(.horizontal)
                .padding(.bottom,2)
            }
        }
        .appScreen()
        .onAppear {
            proVM.fetchInAppProduct()
        }
        .alert(proVM.alertMessage, isPresented: $proVM.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    @ViewBuilder
    func featureRow(_ title: String) -> some View {
        HStack(spacing: 18) {
            
            Image(systemName: "checkmark")
                .font(.system(size: isIpad() ? 25 : 20, weight: .medium))
                .foregroundStyle(.white)
            
            Text(title)
                .font(.system(size: isIpad() ? 26 : 18, weight: .regular))
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
    
    func openUrlInSafari(strUrl: String) {
        guard let url = URL(string: strUrl) else {
            debugPrint("❌ URL invalid")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            debugPrint("❌ System can't open this URL!")
        }
    }
}

struct planCard: View {
    
    var lbl1: String
    var lbl2: String
    var isSelected: Bool = true
    var showBestValue: Bool = false
    
    var action: () -> Void
    
    var body: some View {
        
        Button {
            action()
        } label: {
            ZStack {
                HStack {
                    Image(isSelected ? "select" : "deselect")
                        .resizable()
                        .frame(width: isIpad() ? 26 : 20,height: isIpad() ? 26 : 20)
                    
                    HStack {
                        Text(lbl1 + "/")
                            .font(.system(size: isIpad() ? 26 : 18,weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text(lbl2)
                            .font(.system(size: isIpad() ? 24 : 16))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    
                    if showBestValue {
                        ZStack {
                            Text("BEST")
                                .font(.system(size: isIpad() ? 20 : 14, weight: .medium))
                                .foregroundStyle(AppColor.textColor2)
                        }
                        .padding(.horizontal,20)
                        .frame(height: isIpad() ? 50 : 30)
                        .gradientBackground(colors: [Color("#FFC81E"),Color("#E87F24")],start: .topLeading,end: .bottomTrailing,cornerRadius: isIpad() ? 25: 15)
                    }
                }
                .padding(.horizontal,15)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isIpad() ? 80 : 60)
            .modifier(GlassCardModifier(cornerRadius: 16))
            .padding(.horizontal,15)
        }
        .buttonStyle(.plain)
        
    }
}

extension PremiumView {
    
    func getSubtitle(_ id: String) -> String {
        
        switch id {
            
        case Products.smart_view_monthly.rawValue:
            return "Monthly Plan"
            
        case Products.smart_view_yearly.rawValue:
            return "Yearly Plan"
            
        case Products.smart_view_lifeTime.rawValue:
            return "Lifetime Plan"
            
        default:
            return ""
        }
    }
    
}

extension SKProduct {
    
    var localizedPrice: String {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        
        return formatter.string(from: price) ?? ""
    }
}

#Preview {
    PremiumView()
}
