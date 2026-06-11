//
//  DeviceListCard.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 10/06/26.
//

import SwiftUI
import Lottie

struct DeviceListBG: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color("#222222"),
                Color("#1A1A1A"),
                Color("#111111")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        LinearGradient(
            colors: [
                Color("F53BDC").opacity(0.25),
                Color("#1A1A1A").opacity(0),
                Color("#111111").opacity(0)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .ignoresSafeArea()
        
    }
}

enum deviceStatus {
    case connected,connecting,notConnected
    
    var localizedTitle: String {
        switch self {
        case .notConnected:
            return NSLocalizedString(str.NotConnected, comment: "")
            
        case .connecting:
            return NSLocalizedString(str.connecting, comment: "")
            
        case .connected:
            return NSLocalizedString(str.Connected, comment: "")
        }
    }
}


struct DeviceListingRow: View {
    
    var deviceName: String
    var status: deviceStatus
    
    var body: some View {
        ZStack {
            HStack {
                Image("device")
                    .resizable()
                    .frame(width: isIpad() ? 70 : 50, height: isIpad() ? 70 : 50)
                
                VStack(alignment:.leading,spacing: 5) {
                    Text(deviceName)
                        .font(.system(size: 16,weight: .medium))
                        .foregroundStyle(.white)
                    
                    Text(status.localizedTitle)
                        .font(.system(size: isIpad() ? 18 : 12))
                        .foregroundStyle(status == .connected ? Color("#34C759") : AppColor.textColor)
                }
                
                Spacer()
                
                if status == .connected {
                    Image("connect")
                        .resizable()
                        .frame(width: isIpad() ? 18 : 14, height: isIpad() ? 18 : 14)
                } else if status == .connecting {
                    LottieFile2(animationFileName: MyLottieFiles.connecting, loopMode: .loop)
                        .frame(width: isIpad() ? 50 :  35, height: isIpad() ? 50 :  35)
                        .rotationEffect(.degrees(0))
                } else {
                    Image(systemName: "chevron.right")
                        .frame(width: 20,height: 20)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal,15)
        }
        .frame(maxWidth: .infinity)
        .frame(height: isIpad() ? 80 : 60)
        .modifier(GlassCardModifier(cornerRadius: 20))
        .padding(.horizontal,15)
    }
}

struct stepCard: View {
    var body: some View {
        ZStack {
            VStack(alignment:.leading,spacing: 8) {
                Text(str.HowtoConnect)
                    .font(.system(size: 16,weight: .medium))
                    .foregroundStyle(.white)
                
                Divider()
                
                HStack {
                    ZStack {
                        Text("1")
                            .font(.system(size: 14,weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 26,height: 26)
                    .background(.white.opacity(0.10))
                    .cornerRadius(12)
                    
                    Text(str.Keepbothdevicesconnected)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
                
                HStack {
                    ZStack {
                        Text("2")
                            .font(.system(size: 14,weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 26,height: 26)
                    .background(.white.opacity(0.10))
                    .cornerRadius(12)
                    
                    Text(str.TurnofanyVPNorproxyconnections)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
                
                HStack {
                    ZStack {
                        Text("3")
                            .font(.system(size: 14,weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 26,height: 26)
                    .background(.white.opacity(0.10))
                    .cornerRadius(12)
                    
                    Text(str.RestartyourTVandtryagain)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical,15)
        .modifier(GlassCardModifier(cornerRadius: 20))
        .padding(.horizontal,15)
    }
}


struct PopupCard: View {

    let image: String
    let title: String
    let subtitle: String
    let btnTitle: String

    let btnAction: () -> Void
    let closeAction: () -> Void

    var body: some View {
        VStack {

            singleButtonCard(image: "close") {
                closeAction()
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            .padding(.trailing)

            Image(image)
                .resizable()
                .frame(width: 150, height: 110)

            VStack(spacing: 5) {
                Text(title)
                Text(subtitle)
            }

            commonButtonFile(text: btnTitle) {
                btnAction()
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.black)
        .clipShape(
            CustomCorner(
                corners: [.topLeft, .topRight],
                radius: 40
            )
        )
    }
}


#Preview {
    PopupCard(image: "WIFI", title: "Turn On Wi-Fi", subtitle: "Find and connect to available devices.", btnTitle: "Turn On Wi-Fi", btnAction: {}, closeAction: {})
//    DeviceListingRow(deviceName: "Samsung QLED 8K", status: .connecting)
}
