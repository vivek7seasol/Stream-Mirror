//
//  TabbarView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI

struct TabbarView: View {
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            Group {
                if selectedTab == 0 {
                    HomeView()
                } else if selectedTab == 1 {
                    RemoteView()
                } else if selectedTab == 2 {
                    RecordingView()
                } else {
                    SettingView()
                }
            }
            
            HStack {
                tabItem(index: 0, icon: "Home", title: str.Home)
                tabItem(index: 1, icon: "Remote", title: str.Remote)
                tabItem(index: 2, icon: "Recoding", title: str.Recoding)
                tabItem(index: 3, icon: "Settings", title: str.Settings)
            }
            .padding(.bottom,15)
            .padding(.horizontal, 15)
            .gradientBackground(colors: [
                Color("#222222"),
                Color("#111111")
            ],start: .topLeading,end: .bottomTrailing)
            .modifier(GlassCardModifier(cornerRadius: 20))
            .offset(y:10)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    func tabItem(index: Int, icon: String, title: String) -> some View {
        Button {
            selectedTab = index
        } label: {
            ZStack {
                VStack(spacing: 6) {
                    
                    if selectedTab == index {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.white)
                    } else {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(AppColor.textColor)
                    }
                    
                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                    
                }
                .foregroundColor(selectedTab == index ? .white : AppColor.textColor)
            }
            .padding()
            .background(
                    selectedTab == index ?
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    : LinearGradient(
                        colors: [.clear, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            .overlay(alignment: .top) {
                if selectedTab == index {
                    Rectangle()
                        .fill(.white) 
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        
        
    }
}

#Preview {
    TabbarView()
}
