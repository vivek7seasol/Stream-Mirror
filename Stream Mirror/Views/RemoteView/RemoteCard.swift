//
//  RemoteCard.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 15/06/26.
//

import SwiftUI
import ConnectSDK

struct ControlBtn: View {
    
    @Binding var selectedType: ControlType
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            ForEach(ControlType.allCases, id: \.self) { type in
                
                Button {
                    
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedType = type
                    }
                    
                } label: {
                    
                    ZStack {
                        
                        if selectedType == type {
                            
                            Capsule()
                                .fill(.white.opacity(0.10))
                                .frame(width: 100)
                        }
                        
                        Image(type.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: isIpad() ? 36 : 26,
                                height: isIpad() ? 36 : 26
                            )
                            .foregroundStyle(selectedType == type ? .white : AppColor.textColor)
                    }
                    .frame(maxWidth: isIpad() ? 0 : .infinity)
                    .padding(.horizontal, isIpad() ? 50 : 0)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: isIpad() ? 70 : 50)
        .background(.white.opacity(0.10))
        .modifier(GlassCardModifier(cornerRadius: isIpad() ? 35 : 25))
        .clipShape(RoundedRectangle(cornerRadius: isIpad() ? 35 : 25))
    }
}

struct controlTypeCard: View {
    
    let upAction: () -> Void
    let downAction: () -> Void
    let leftAction: () -> Void
    let rightAction: () -> Void
    let okAction: () -> Void
    
    // Ek hi value se square banega
    private var cardSize: CGFloat {
        min(DeviceHelper.width * 0.55, DeviceHelper.height * 0.25)
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: isIpad() ? 60 : 30) {
                Button { leftAction() } label: {
                    Image("left")
                        .resizable()
                        .foregroundStyle(.white)
                        .frame(width: isIpad() ? 16 : 8, height: isIpad() ? 28 : 14)
                }
                .buttonStyle(.plain)
                
                VStack(spacing: isIpad() ? 60 : 30) {
                    Button { upAction() } label: {
                        Image("up")
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: isIpad() ? 28 : 14, height: isIpad() ? 16 : 8)
                    }
                    .buttonStyle(.plain)
                    
                    Button { okAction() } label: {
                        ZStack {
                            Text("OK")
                                .font(.system(size: isIpad() ? 26 : 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: isIpad() ? 100 : 84, height: isIpad() ? 100 : 84)
                        .background(AppColor.textColor.opacity(0.50))
                        .cornerRadius(isIpad() ? 50 : 42)
                    }
                    .buttonStyle(.plain)
                    
                    Button { downAction() } label: {
                        Image("down")
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: isIpad() ? 28 : 14, height: isIpad() ? 16 : 8)
                    }
                    .buttonStyle(.plain)
                }
                
                Button { rightAction() } label: {
                    Image("right")
                        .resizable()
                        .foregroundStyle(.white)
                        .frame(width: isIpad() ? 16 : 8, height: isIpad() ? 28 : 14)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: isIpad() ? cardSize + 50 : cardSize, height: isIpad() ? cardSize + 30 : cardSize)
        .background(.white.opacity(0.10))
        .modifier(GlassCardModifier(cornerRadius: 50))
        .clipShape(RoundedRectangle(cornerRadius: 50))
    }
}

struct touchPadView: View {
    
    @ObservedObject var viewModel: RemoteControlViewModel
    
    // MARK: - Touchpad Actions
    var onSwipeUp: () -> Void = {}
    var onSwipeDown: () -> Void = {}
    var onSwipeLeft: () -> Void = {}
    var onSwipeRight: () -> Void = {}
    var onTap: () -> Void = {}
    
    private let minimumSwipeDistance: CGFloat = 30
    
    // controlTypeCard jaisi hi height
    private var cardHeight: CGFloat {
        min(DeviceHelper.width * 0.55, DeviceHelper.height * 0.25)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                Image("touchpad2")
                    .resizable()
                    .frame(
                        width: isIpad() ? 80 : 60,
                        height: isIpad() ? 80 : 60
                    )
                
                Text(str.SmoothTouchNavigation)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColor.textColor)
            }
        }
        .frame(maxWidth: isIpad() ? DeviceHelper.width * 0.55 : .infinity, minHeight: isIpad() ? cardHeight + 30 : cardHeight)
        .background(.white.opacity(0.10))
        .modifier(GlassCardModifier(cornerRadius: 50))
        .clipShape(RoundedRectangle(cornerRadius: 50))
        .padding(.horizontal, 15)
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture(minimumDistance: minimumSwipeDistance)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        if horizontalAmount > 0 {
                            onSwipeRight()
                        } else {
                            onSwipeLeft()
                        }
                    } else {
                        if verticalAmount > 0 {
                            onSwipeDown()
                        } else {
                            onSwipeUp()
                        }
                    }
                }
        )
    }
}

struct mouseView: View {
    
    @ObservedObject var viewModel: RemoteControlViewModel
    
    var onMouseMove: (_ dx: CGFloat, _ dy: CGFloat, _ dt: TimeInterval) -> Void = { _, _, _ in }
    var onMouseTap: () -> Void = {}
    private var cardHeight: CGFloat {
        min(DeviceHelper.width * 0.55, DeviceHelper.height * 0.25)
    }
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                Image("mouse2")
                    .resizable()
                    .frame(
                        width: isIpad() ? 80 : 60,
                        height: isIpad() ? 80 : 60
                    )
                
                Text(str.SmoothCursorControl)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColor.textColor)
            }
        }
        .frame(maxWidth: isIpad() ? DeviceHelper.width * 0.55 : .infinity, minHeight: isIpad() ? cardHeight + 30 : cardHeight)
        .background(.white.opacity(0.10))
        .modifier(GlassCardModifier(cornerRadius: 50))
        .clipShape(RoundedRectangle(cornerRadius: 50))
        .padding(.horizontal, 15)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    
                    let currentPoint = value.location
                    let currentTime = Date().timeIntervalSince1970
                    
                    if viewModel.lastPoint == .zero {
                        viewModel.lastPoint = currentPoint
                        viewModel.lastTime = currentTime
                        return
                    }
                    
                    let dx = currentPoint.x - viewModel.lastPoint.x
                    let dy = currentPoint.y - viewModel.lastPoint.y
                    let dt = currentTime - viewModel.lastTime
                    
                    if abs(dx) > 0.5 || abs(dy) > 0.5 {
                        
                        viewModel.isDragging = true
                        
                        onMouseMove(dx, dy, dt)
                        
                        viewModel.lastPoint = currentPoint
                        viewModel.lastTime = currentTime
                    }
                }
                .onEnded { value in
                    
                    let translation = value.translation
                    
                    // Tap detect
                    if abs(translation.width) < 5 &&
                        abs(translation.height) < 5 {
                        
                        onMouseTap()
                    }
                    
                    viewModel.lastPoint = .zero
                    viewModel.lastTime = 0
                    viewModel.isDragging = false
                }
        )
    }
}

struct KeyboardView: View {
    
    @ObservedObject var viewModel: RemoteControlViewModel
    @ObservedObject var TVRemoteVM: RemoteViewModel
    
    @FocusState private var isKeyboardFocused: Bool
    @Binding var text: String
    private var cardHeight: CGFloat {
        min(DeviceHelper.width * 0.55, DeviceHelper.height * 0.25)
    }
    
    private var editorHeight: CGFloat {
        isIpad() ? cardHeight + 30 : cardHeight
    }
    var body: some View {
        
        ZStack(alignment: .topLeading) {
            
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .foregroundColor(.white)
                .font(.system(size: 16))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .onChange(of: text) { newValue in
                    viewModel.handleTextInput(
                        newValue,
                        tvVM: TVRemoteVM
                    )
                }
                .padding(.horizontal, 15)
            
            if text.isEmpty {
                Text(str.StartTypingHere)
                    .foregroundColor(AppColor.textColor)
                    .font(.system(size: 16))
                    .padding(.leading, 18)
                    .padding(.top, 18)
                    .allowsHitTesting(false)
                    .padding(.horizontal, 15)
            }
            
        }
        .frame(
            maxWidth: isIpad() ? DeviceHelper.width * 0.55 : .infinity,
            minHeight: editorHeight,
            maxHeight: editorHeight
        )
        .background(.white.opacity(0.10))
        .modifier(GlassCardModifier(cornerRadius: 50))
        .clipShape(RoundedRectangle(cornerRadius: 50))
        .padding(.horizontal, 15)
    }
}

struct VolChButtonCard: View {
    
    let image1: String
    let image2: String
    let title: String
    let action1: () -> Void
    let action2: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing:isIpad() ? 35 : 25) {
                Button {
                    action1()
                } label: {
                    ZStack {
                        Image(systemName: image1)
                            .foregroundStyle(.white)
                            .frame(width: isIpad() ? 34 : 28,height:  isIpad() ? 34 : 28)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                
                Button {
                    action2()
                } label: {
                    ZStack {
                        Image(systemName: image2)
                            .foregroundStyle(.white)
                            .frame(width: isIpad() ? 34 : 28,height:  isIpad() ? 34 : 28)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width:isIpad() ? 80 : 66)
        .padding(.vertical,15)
        .background(.white.opacity(0.10))
        .modifier(GlassCardModifier(cornerRadius: isIpad() ? 40 : 33))
        .clipShape(RoundedRectangle(cornerRadius: isIpad() ? 40 : 33))
    }
}

struct ChannelView: View {
    
    @Binding var isPresented: Bool
    var onChannelSelected: (TVApps) -> Void
    let channels: [(image: String, title: String, app: TVApps)] = [
        ("Youtube2", "Youtube",.youtube),
        ("Netflix", "Netflix",.netflix),
        ("Prime", "Prime",.prime),
        ("Spotify", "Spotify",.spotify),
        ("Disney", "Disney",.disney),
        ("Paramount", "Paramount",.paramount)
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        
        ZStack {
            
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 0) {
                
                Spacer()
                
                VStack(spacing: 20) {
                    
                    // Drag Indicator
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(width: 70, height: 6)
                        .padding(.top)
                    
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
                        
                        Text("Select Channel")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Choose a channel to start watching.")
                            .font(.system(size: 12))
                            .foregroundColor(AppColor.textColor)
                    }
                    
                    // Channel Grid
                    LazyVGrid(columns: columns, spacing: 15) {
                        
                        ForEach(channels.indices, id: \.self) { index in
                            
                            ChannelCard(
                                image: channels[index].0,
                                title: channels[index].1
                            ) {
                                onChannelSelected(channels[index].app)
                                withAnimation(.spring()) {
                                    isPresented = false
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .background(
                    DeviceListBG()
                )
                .clipShape(
                    CustomCorner(
                        corners: [.topLeft, .topRight],
                        radius: 40
                    )
                )
                //                .offset(y: 60)
            }
        }
    }
}
struct ChannelCard: View {
    
    let image: String
    let title: String
    var action: () -> Void
    
    var body: some View {
        
        Button {
            action()
        } label: {
            ZStack {
                HStack(spacing: 5) {
                    
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: isIpad() ? 45 : 30, height: isIpad() ? 45 : 30)
                        .clipShape(Circle())
                    
                    Text(title)
                        .font(.system(size: isIpad() ? 22 : 16))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
            }
            .padding(.horizontal, 15)
            .frame(height: isIpad() ? 75 : 55)
            .modifier(GlassCardModifier(cornerRadius: isIpad() ? 37.5 : 27.5))
        }
        .buttonStyle(.plain)
    }
}

struct NumberPadView: View {
    
    @Binding var isPresented: Bool

       var onNumberTap: (String) -> Void
       var onClear: () -> Void
       var onDone: (String) -> Void

       @State private var enteredNumber = ""
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        
        ZStack {
            
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 0) {
                
                Spacer()
                
                VStack(spacing: 15) {
                    
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(width: 70, height: 6)
                        .padding(.top)
                    
                    HStack {
                        
                        Spacer()
                        
                        singleButtonCard(image: "close") {
                            isPresented = false
                        }
                    }
                    
                    ZStack {
                        
                        Text(enteredNumber)
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isIpad() ? 90 : 70)
                    .modifier(GlassCardModifier(cornerRadius: 20))
                    .padding(.horizontal,15)
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        
                        ForEach(1...9, id: \.self) { number in
                            
                            NumberKey(title: "\(number)") {

                                enteredNumber += "\(number)"

                                onNumberTap("\(number)")
                            }
                        }
                        
                        NumberKey(title: "✕") {

                            if !enteredNumber.isEmpty {
                                enteredNumber.removeLast()
                            }

                            onClear()
                        }
                        
                        NumberKey(title: "0") {
                            enteredNumber += "0"
                        }
                        
                        NumberKey(title: "✓") {

                            onDone(enteredNumber)

                            isPresented = false
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
                .background(DeviceListBG())
                .clipShape(
                    CustomCorner(
                        corners: [.topLeft, .topRight],
                        radius: 40
                    )
                )
            }
        }
    }
}

struct NumberKey: View {
    
    let title: String
    var action: () -> Void
    
    var body: some View {
        
        Button(action: action) {
            
            Text(title)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
                .frame(width: isIpad() ? 110 : 90, height: isIpad() ? 90 : 70)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.08))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        }
                )
                .modifier(GlassCardModifier(cornerRadius: 20))
                .padding(.horizontal,15)
        }
        .buttonStyle(.plain)
    }
}

struct TVInputItem: Identifiable {
    let id = UUID()
    let title: String
    let image: String
    let action: () -> Void
}

struct TVInputSourceView: View {

    @Binding var isPresented: Bool
    @ObservedObject var TVRemoteVM: RemoteViewModel

    var body: some View {

        ZStack {

            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 0) {

                Spacer()

                VStack {

                    Capsule()
                        .fill(.gray.opacity(0.5))
                        .frame(width: 50, height: 5)
                        .padding(.top, 10)

                    HStack {

                        Spacer()

                        Text("Select TV Input Source")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        singleButtonCard(image: "close") {
                            isPresented = false
                        }
                    }
                    .padding()

                    if TVRemoteVM.lgPorts.isEmpty {
                        Spacer()
                        placeholderView(image: "PortPH", title: str.noPortFound, title2: "", isTitle2: false)
                        Spacer()
                    } else {
                        
                        ScrollView(showsIndicators: false) {
                            
                            VStack(spacing: 14) {
                                
                                ForEach(TVRemoteVM.lgPorts, id: \.id) { port in
                                    
                                    Button {
                                        
                                        TVRemoteVM.switchToLGPort(port)
                                        
                                        isPresented = false
                                        
                                    } label: {
                                        let idLower = port.id?.lowercased() ?? ""
                                        HStack {
                                            
                                            ZStack {
                                                Circle()
                                                    .fill(.white.opacity(0.08))
                                                    .frame(width: 44, height: 44)
                                                
                                                Image(idLower.contains("hdmi") ? "hdmi" : "AV2")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 22, height: 22)
                                            }
                                            
                                            Text(port.name ?? "Unknown")
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.white)
                                        }
                                        .padding()
                                        .frame(height: 70)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(.ultraThinMaterial)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .background(DeviceListBG())
                .clipShape(
                    CustomCorner(
                        corners: [.topLeft, .topRight],
                        radius: 40
                    )
                )
            }
        }
    }
}
