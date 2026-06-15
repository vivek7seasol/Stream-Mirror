//
//  RemoteCard.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 15/06/26.
//

import SwiftUI

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
                                .padding(6)
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
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: isIpad() ? 70 : 50)
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
            HStack(spacing: isIpad() ? 60 : 20) {
                Button { leftAction() } label: {
                    Image("left")
                        .resizable()
                        .foregroundStyle(.white)
                        .frame(width: isIpad() ? 16 : 8, height: isIpad() ? 28 : 14)
                }
                .buttonStyle(.plain)

                VStack(spacing: isIpad() ? 60 : 20) {
                    Button { upAction() } label: {
                        Image("up")
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: isIpad() ? 30 : 24, height: isIpad() ? 30 : 24)
                    }
                    .buttonStyle(.plain)
                    
                    Button { okAction() } label: {
                        ZStack {
                            Text("OK")
                                .font(.system(size: isIpad() ? 26 : 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: isIpad() ? 90 : 84, height: isIpad() ? 90 : 84)
                        .background(AppColor.textColor.opacity(0.50))
                        .cornerRadius(isIpad() ? 45 : 42)
                    }
                    .buttonStyle(.plain)
                    
                    Button { downAction() } label: {
                        Image("down")
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: isIpad() ? 30 : 24, height: isIpad() ? 30 : 24)
                    }
                    .buttonStyle(.plain)
                }
                
                Button { rightAction() } label: {
                    Image("right")
                        .resizable()
                        .foregroundStyle(.white)
                        .frame(width: isIpad() ? 30 : 24, height: isIpad() ? 30 : 24)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: isIpad() ? cardSize + 20 : cardSize, height: isIpad() ? cardSize + 20 : cardSize)
        .modifier(GlassCardModifier(cornerRadius: 50))
        .clipShape(RoundedRectangle(cornerRadius: 50))
    }
}

struct touchPadView: View {

    @StateObject private var viewModel = RemoteControlViewModel()

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
        .frame(maxWidth: isIpad() ? DeviceHelper.width * 0.55 : .infinity, minHeight: cardHeight)
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

    @StateObject private var viewModel = RemoteControlViewModel()

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
        .frame(maxWidth: isIpad() ? DeviceHelper.width * 0.55 : .infinity, minHeight: cardHeight)
        .modifier(GlassCardModifier(cornerRadius: 50))
        .clipShape(RoundedRectangle(cornerRadius: 50))
        .padding(.horizontal, 15)

        .onTapGesture {
            onMouseTap()
        }

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

                    if abs(dx) > 2 || abs(dy) > 2 {

                        viewModel.isDragging = true

                        onMouseMove(dx, dy, dt)

                        viewModel.lastPoint = currentPoint
                        viewModel.lastTime = currentTime
                    }
                }
                .onEnded { _ in

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {

                        viewModel.lastPoint = .zero
                        viewModel.lastTime = 0
                        viewModel.isDragging = false
                    }
                }
        )
    }
}

struct KeyboardView: View {

    @StateObject private var viewModel = RemoteControlViewModel()

    @FocusState private var isKeyboardFocused: Bool
    @Binding var text: String
    private var cardHeight: CGFloat {
        min(DeviceHelper.width * 0.55, DeviceHelper.height * 0.25)
    }
    var body: some View {
        ZStack {
            VStack(spacing: 15) {

                ZStack(alignment: .topLeading) {

                    if text.isEmpty {
                        Text(str.StartTypingHere)
                            .foregroundStyle(AppColor.textColor.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $text)
                        .focused($isKeyboardFocused)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(.white)
                        .font(.system(size: 16))
                        .padding(8)
                }
                .frame(height: isIpad() ? 180 : 140)
            }
        }
        .frame(maxWidth: isIpad() ? DeviceHelper.width * 0.55 : .infinity, minHeight: cardHeight)
        .modifier(GlassCardModifier(cornerRadius: 50))
        .clipShape(RoundedRectangle(cornerRadius: 50))
        .padding(.horizontal, 15)
        .onAppear {
            isKeyboardFocused = true
        }
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
                Image(systemName: image1)
                    .foregroundStyle(.white)
                    .frame(width: isIpad() ? 34 : 28,height:  isIpad() ? 34 : 28)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                
                Image(systemName: image2)
                    .foregroundStyle(.white)
                    .frame(width: isIpad() ? 34 : 28,height:  isIpad() ? 34 : 28)
            }
        }
        .frame(width:isIpad() ? 80 : 66)
        .padding(.vertical,10)
        .modifier(GlassCardModifier(cornerRadius: isIpad() ? 40 : 33))
        .clipShape(RoundedRectangle(cornerRadius: isIpad() ? 40 : 33))
    }
}
