//
//  PhotoCastingView.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 12/06/26.
//

import SwiftUI
internal import Photos

enum SelectedQuality: Int, CaseIterable {
    case basic = 0
    case normal = 1
    case enhanced = 2

    var title: String {
        switch self {
        case .basic: return "Basic"
        case .normal: return "Normal"
        case .enhanced: return "Enhanced"
        }
    }
}

struct PhotoCastingView: View {
    
    @EnvironmentObject var commonVM: CommonConnectionViewModel
    @EnvironmentObject var TVRemoteVM: RemoteViewModel
    
    @State private var quality: SelectedQuality = .basic
    @State private var showTimerView: Bool = false
    @State private var currentIndex: Int = 0
    @State private var slideTimer: Timer?
    @State private var timerSeconds: Int = 7
    @State private var isPlaying = false
    
    let images: [UIImage]
    var assets: [PHAsset] = []
    var imageURLs: [String] = []
    var selectedIndex: Int
    @State private var currentImage: UIImage?
    
    var body: some View {
        
        ZStack {
            
            VStack {
                
                CommonStatusView(
                    title: str.Photo,
                    onCast: {}
                )
                
                ZStack {
                    Group {
                        
                        if let currentImage {
                            
                            Image(uiImage: currentImage)
                                .resizable()
                                .scaledToFit()
                            
                        } else if imageURLs.indices.contains(currentIndex) {
                            
                            AsyncImage(
                                url: URL(string: imageURLs[currentIndex])
                            ) { phase in
                                
                                switch phase {
                                    
                                case .empty:
                                    ProgressView()
                                    
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                    
                                case .failure(_):
                                    Image("photoPH")
                                        .resizable()
                                        .scaledToFit()
                                    
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            
                        } else {
                            
                            Image("photoPH")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    
                    HStack(spacing:35) {
                        
                        CircleButton(icon: "previous2", size2: 44) {
                            
                            let count =
                            !images.isEmpty
                            ? images.count
                            : !imageURLs.isEmpty
                            ? imageURLs.count
                            : assets.count
                            guard count > 0 else { return }
                            
                            currentIndex =
                            currentIndex == 0
                            ? count - 1
                            : currentIndex - 1
                            
                        }
                        
                        CircleButton(
                            icon: isPlaying ? "pause" : "play",
                            size: 28,
                            size2: 60
                        ) {

                            if isPlaying {

                                stopSlideshow()
                                isPlaying = false

                            } else {

                                showTimerView = true
                            }
                        }
                        
                        CircleButton(icon: "next2", size2: 44) {

                            let count =
                            !images.isEmpty
                            ? images.count
                            : !imageURLs.isEmpty
                            ? imageURLs.count
                            : assets.count
                            guard count > 0 else { return }

                            currentIndex =
                            (currentIndex + 1) % count

                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .clipped()
                .padding()
                
                HStack {
                    
                    Button {
                        showTimerView = true
                    } label: {
                        
                        Text(str.SetTimer)
                            .font(.system(size: isIpad() ? 18 : 12, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 15)
                            .frame(height: isIpad() ? 60 : 40)
                            .modifier(
                                GlassCardModifier(
                                    cornerRadius: isIpad() ? 30 : 20
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 0) {
                        
                        ForEach(
                            SelectedQuality.allCases,
                            id: \.self
                        ) { item in
                            
                            Button {
                                
                                withAnimation {
                                    quality = item
                                }
                                
                            } label: {
                                
                                Text(item.title)
                                    .font(.system(size:isIpad() ? 18 : 12, weight: .medium))
                                    .foregroundColor(
                                        quality == item ? AppColor.textColor2 : .white
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: isIpad() ? 60 : 40)
                                    .background {
                                        
                                        if quality == item {
                                            
                                            Capsule()
                                                .fill(.white)
                                                .padding(4)
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: isIpad() ? 60 : 40)
                    .modifier(
                        GlassCardModifier(
                            cornerRadius: isIpad() ? 30 : 20
                        )
                    )
                }
                .padding(.horizontal, 15)
            }
        }
        .appScreen()
        .onAppear {

            currentIndex = selectedIndex
            loadSelectedImage()
        }
        .onChange(of: currentIndex) { _ in
            loadSelectedImage()
        }
        .overlay {
            
            if showTimerView {
                
                SetTimerView(
                    isPresented: $showTimerView,
                    selectedSeconds: $timerSeconds
                ) {

                    startSlideshow()

                    isPlaying = true
                }
            }
        }
        .onDisappear {
            
            stopSlideshow()
        }
    }
    
    func castCurrentImage() {

        guard let currentImage else { return }

        guard let imageData = currentImage.jpegData(compressionQuality: 1.0) else {
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cast_image_\(currentIndex).jpg")

        do {

            try imageData.write(to: tempURL)

            commonVM.compressAndUploadImage(
                from: tempURL,
                mediaType: "image/jpeg",
                title: AppStrings.appName,
                des: "",
                imgHei: Int(currentImage.size.height),
                imgWid: Int(currentImage.size.width),
                selectedQuality: quality.rawValue
            )

        } catch {

            print(error.localizedDescription)
        }
    }
    
    private func startSlideshow() {

        stopSlideshow()

        isPlaying = true

        slideTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(timerSeconds),
            repeats: true
        ) { _ in

            DispatchQueue.main.async {

                let count =
                !images.isEmpty
                ? images.count
                : !imageURLs.isEmpty
                ? imageURLs.count
                : assets.count

                guard count > 0 else { return }

                currentIndex = (currentIndex + 1) % count
            }
        }
    }
    
    private func stopSlideshow() {

        slideTimer?.invalidate()
        slideTimer = nil

        isPlaying = false
    }
}

extension PhotoCastingView {
    
    private func loadSelectedImage() {

        if !images.isEmpty {

            guard images.indices.contains(currentIndex) else { return }

            currentImage = images[currentIndex]

            castCurrentImage()

            return
        }
        
        if imageURLs.indices.contains(currentIndex) {

            guard let url = URL(string: imageURLs[currentIndex]) else {
                return
            }

            URLSession.shared.dataTask(with: url) { data, _, _ in

                guard let data,
                      let image = UIImage(data: data) else {
                    return
                }

                DispatchQueue.main.async {
                    self.currentImage = image
                    self.castCurrentImage()
                }

            }.resume()

            return
        }

        guard assets.indices.contains(currentIndex) else {
            return
        }

        let asset = assets[currentIndex]

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in

            DispatchQueue.main.async {

                self.currentImage = image
                self.castCurrentImage()
            }
        }
    }
}

#Preview {
    PhotoCastingView(images: [], selectedIndex: 0)
}
