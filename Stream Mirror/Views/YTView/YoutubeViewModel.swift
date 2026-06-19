//
//  YoutubeViewModel.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import Foundation
import SwiftUI
import Combine
internal import WebKit
import AVFoundation

class YoutubeViewModel: NSObject, ObservableObject {
    
    @Published var webView: WKWebView = {
        
        let config = WKWebViewConfiguration()
        
        // Disable default video controller
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        if #available(iOS 10.0, *) {
            config.allowsPictureInPictureMediaPlayback = false
        }
        
        let webView = WKWebView(frame: .zero, configuration: config)
        
        webView.scrollView.bounces = false
        
        return webView
    }()
    private var navObservations: [NSKeyValueObservation] = []
    @Published var isLoading: Bool = false
    
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    
    @Published var currentVideoURL: URL? = nil
    @Published var videoList: [VideoResolution] = []
    @Published var isCastReady: Bool = false
    @Published var showConnectionView = false
    @Published var showPreview = false
    @Published var showDeviceList = false
    
    @Published var player: AVPlayer?
    @Published var selectedVideo: VideoResolution?
    
    override init() {
            super.init()
            setupNavigationObservers()
        }
    
    private func setupNavigationObservers() {
            let backObs = webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.canGoBack = webView.canGoBack
                }
            }
            
            let forwardObs = webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.canGoForward = webView.canGoForward
                }
            }
            
            navObservations = [backObs, forwardObs]
        }
        
        deinit {
            navObservations.removeAll() // ✅ Cleanup
        }
    
    func loadHome() {
        guard let url = URL(string: "https://www.youtube.com/") else { return }
        
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        webView.load(URLRequest(url: url))
    }
    
    // MARK: - URL se Video ID nikalo → API call karo
    func processAndFetchVideoDetails(from url: URL) {
        let urlString = url.absoluteString
        
        guard let videoID = urlString.extractYoutubeId() else {
            print("❌ Video ID extract nahi hua")
            DispatchQueue.main.async {
                self.videoList = []
                self.isCastReady = false
            }
            return
        }
        
        loadYouTubeVideo(videoID: videoID)
    }
    
    // MARK: - RapidAPI call — SwiftyJSON ke bina
    func loadYouTubeVideo(videoID: String) {
        DispatchQueue.main.async {
            self.videoList.removeAll()
            self.isCastReady = false
        }
        
        let urlString = "https://yt-api.p.rapidapi.com/dl?id=\(videoID)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("yt-api.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue("1656db373cmsh36dd76bfd7a6dfap1067d8jsn1810bbf77054", forHTTPHeaderField: "x-rapidapi-key")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ API se data nahi aaya")
                return
            }
            
            do {
                let response = try JSONDecoder().decode(YouTubeAPIResponse.self, from: data)
                
                let thumbURL = response.thumbnail?.last?.url ?? ""
                let title = response.title ?? ""
                let channelTitle = response.channelTitle ?? ""
                
                var newList: [VideoResolution] = []
                
                for format in response.formats ?? [] {
                    let itag = format.itag ?? 0
                    
                    if (itag == 18 || itag == 398),
                       !(format.url ?? "").isEmpty {
                        let video = VideoResolution(
                            id: UUID().uuidString,
                            videoName: title,
                            videoURL: format.url ?? "",
                            videothumImage: thumbURL,
                            videoAuthor: channelTitle,
                            videoResolution: itag == 18 ? "360p" : "480p"
                        )
                        newList.append(video)
                    }
                }
                
                DispatchQueue.main.async {
                    self.videoList = newList
                    self.isCastReady = newList.count > 0
                    print("✅ Video list ready: \(newList.count) videos")
                }
                
            } catch {
                print("❌ JSON decode error: \(error)")
            }
            
        }.resume()
    }
    
    // MARK: - WebView mein YouTube video pause karo
    func pauseYouTubeInWebView() {
        let script = """
        var videos = document.getElementsByTagName("video");
        for (var i = 0; i < videos.length; i++) {
            videos.item(i).pause();
        };
        """
        webView.evaluateJavaScript(script) { _, _ in }
    }
    
    func loadSearchOrURL(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else { return }
        
        var finalURL: String
        
        if trimmed.contains(".") && !trimmed.contains(" ") {
            if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                finalURL = trimmed
            } else {
                finalURL = "https://\(trimmed)"
            }
        } else {
            let query = trimmed.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ) ?? ""
            
            finalURL = "https://www.google.com/search?q=\(query)"
        }
        
        guard let url = URL(string: finalURL) else { return }
        
        webView.load(URLRequest(url: url))
        
    }
    
    func preparePlayer() {
        guard let videoURL = selectedVideo?.videoURL,
              let url = URL(string: videoURL) else {
            print("❌ URL missing — selectedVideo: \(String(describing: selectedVideo))")
            return
        }
        print("✅ URL: \(url.absoluteString)")
        
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        
        // Status check
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("🎬 Status: \(item.status.rawValue) | Error: \(String(describing: item.error))")
        }
    }
    
    func updateNavigationState() {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
}

extension String {
    func extractYoutubeId() -> String? {
        let pattern = #"(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)"#
        if let matchRange = self.range(of: pattern, options: .regularExpression) {
            return String(self[matchRange])
        } else {
            return .none
        }
    }
}


struct YoutubePreview: UIViewRepresentable {

    @Binding var webView: WKWebView
    @Binding var isLoading: Bool

    var viewModel: YoutubeViewModel
    var onVideoDetected: ((URL?) -> Void)?

    func makeUIView(context: Context) -> WKWebView {

        webView.navigationDelegate = context.coordinator

        context.coordinator.onVideoDetected = onVideoDetected
        context.coordinator.viewModel = viewModel

        webView.addObserver(
            context.coordinator,
            forKeyPath: "URL",
            options: [.new],
            context: nil
        )

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.removeObserver(coordinator, forKeyPath: "URL")
    }

    class Coordinator: NSObject, WKNavigationDelegate {

        var parent: YoutubePreview
        var onVideoDetected: ((URL?) -> Void)?
        weak var viewModel: YoutubeViewModel?

        init(_ parent: YoutubePreview) {
            self.parent = parent
        }

        override func observeValue(
            forKeyPath keyPath: String?,
            of object: Any?,
            change: [NSKeyValueChangeKey : Any]?,
            context: UnsafeMutableRawPointer?
        ) {

            guard keyPath == "URL",
                  let webView = object as? WKWebView,
                  let url = webView.url else { return }

            DispatchQueue.main.async {

                self.viewModel?.updateNavigationState()

                if self.isValidYouTubeVideo(url: url) {
                    self.onVideoDetected?(url)
                } else {
                    self.onVideoDetected?(nil)
                }
            }
        }

        func webView(_ webView: WKWebView,
                     didStartProvisionalNavigation navigation: WKNavigation!) {

            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView,
                     didFinish navigation: WKNavigation!) {

            DispatchQueue.main.async {
                self.parent.isLoading = false
            }

            injectBlockingJS(webView)
        }

        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {

            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.viewModel?.updateNavigationState()
            }
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {

            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.viewModel?.updateNavigationState()
            }
        }

        private func isValidYouTubeVideo(url: URL) -> Bool {

            guard let host = url.host else { return false }

            return host.contains("youtube.com") &&
            (url.absoluteString.contains("watch") ||
             url.absoluteString.contains("shorts"))
        }

        private func injectBlockingJS(_ webView: WKWebView) {

            let js = """
            document.addEventListener('fullscreenchange', function() {
                if (document.fullscreenElement) {
                    document.exitFullscreen();
                }
            });
            """

            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

class VideoResolution: NSObject {

  var id = String()
  var videoName =  String()
  var videoURL = String()
  var videothumImage  = String()
  var videoAuthor = String()
  var videoResolution = String()
  
  override init() {
    
  }
  
  init(id:String,videoName:String,videoURL:String,videothumImage:String,videoAuthor:String,videoResolution:String) {
    self.id = id
    self.videoName = videoName
    self.videoURL = videoURL
    self.videothumImage = videothumImage
    self.videoAuthor = videoAuthor
    self.videoResolution = videoResolution
  }
}
