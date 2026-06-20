//
//  IntroMainView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

struct IntroItem {
    let image: String
    let image2: String
    let title: String
    let subtitle: String
    let indicator: String
}

struct IntroMainView: View {
    
    @State private var selectedTab = 0
    @State private var showTabbar: Bool = false
    @State private var dragOffset: CGFloat = 0
    @AppStorage(SessionKeys.intro3) var intro3 = false
    @StateObject private var tabBarManager = TabBarManager()
    @AppStorage(SessionKeys.isPro) var isPro = false
    
    let introItems = [
        IntroItem(image: "intro1", image2: "intro1_1", title: str.intro1, subtitle: str.intro1_1, indicator: "pager1"),
        IntroItem(image: "intro2", image2: "intro2_2", title: str.intro2, subtitle: str.intro2_2, indicator: "pager2"),
        IntroItem(image: "intro3", image2: "intro3_3", title: str.intro3, subtitle: str.intro3_3, indicator: "pager3")
    ]
    
    var body: some View {
        ZStack {
            VStack {
                Image(introItems[selectedTab].image2)
                    .resizable()
                    .scaledToFill()
                    .frame(width: isIpad() ? 88 : 66,height: isIpad() ? 88 : 66)
                
                VStack(spacing:8) {
                    Text(introItems[selectedTab].title)
                        .font(.system(size: isIpad() ? 34 : 28,weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(introItems[selectedTab].subtitle)
                        .font(.system(size: isIpad() ? 20 : 14))
                        .foregroundStyle(AppColor.textColor)
                }
                .padding(.horizontal,30)
                .frame(height: isIpad() ? 130 : 100)
                
                TabView(selection: $selectedTab) {
                    ForEach(Array(introItems.enumerated()), id: \.offset) { index, item in
                        Image(item.image)
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Image(introItems[selectedTab].indicator)
                    .resizable()
                    .frame(width: isIpad() ? 77 : 55,height: isIpad() ? 25 : 15)
                    .padding(.vertical,15)
                
                commonButtonFile(
                    text: selectedTab == introItems.count - 1 ? str.Done : str.Next
                ) {
                    if selectedTab < introItems.count - 1 {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            selectedTab += 1
                        }
                    } else {
                        intro3 = true
                        showTabbar = true
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom,10)
                
                if !isPro {
                    NativeAd6()
                        .padding(.bottom,5)
                        .padding(.horizontal,15)
                }
            }
        }
        .appScreen(disableSwipeBack: true)
        .navigationDestination(isPresented: $showTabbar) {
            TabbarView()
                .environmentObject(tabBarManager)
        }
    }
}

#Preview {
    IntroMainView()
}
