//
//  WebServerManager.swift
//  Screen Mirroring Casting
//
//  Created by iOS Developer on 16/09/2025.
//


import Foundation
import ConnectSDK
import Combine
import Network

class TVMirrorServer: ObservableObject {
    static let shared = TVMirrorServer()
    private var webServer: GCDWebServer?
    private var latestImage: Data?
    private let bufferLock = NSLock()
    private let maxBufferSize: Int = 6 * 111 * 240 * 2
    @Published var isMirroringActive: Bool = false
    
    @Published var isConnectedToNetwork: Bool = true
    @Published var serverURL: URL? {
        didSet {
            saveServerURLToUserDefaults(url: serverURL)
        }
    }
    
    private var monitor: NWPathMonitor?
    private var monitorQueue: DispatchQueue?
    
    init() {
        startNetworkMonitoring()
        loadServerURLFromUserDefaults()
    }
    
    private func startNetworkMonitoring() {
        monitor = NWPathMonitor()
        monitorQueue = DispatchQueue(label: "NetworkMonitorQueue")
        
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnectedToNetwork = path.status == .satisfied
                
                if self?.isConnectedToNetwork == true {
                    if self?.webServer == nil {
                        self?.startServer()
                    }
                } else {
                    print("No network connection. Server cannot start.")
                }
            }
        }
        
        monitor?.start(queue: monitorQueue!)
    }
    
    func startServer() {
        guard isConnectedToNetwork else {
            print("Cannot start the server without network connection.")
            return
        }
        
        if webServer == nil {
            webServer = GCDWebServer()
            
            webServer?.addHandler(forMethod: "GET", path: "/", request: GCDWebServerRequest.self, processBlock: { request in
                return GCDWebServerDataResponse(html: """
                <html>
                    <head>
                        <style>
                            body {
                                margin: 0;
                                padding: 0;
                                display: flex;
                                justify-content: center;
                                align-items: center;
                                height: 100vh;
                                background-color: #000; /* Optional: Black background */
                            }
                            #stream {
                                max-width: 100%;
                                max-height: 100%;
                            }
                        </style>
                    </head>
                    <body>
                        <div>
                            <img id="stream" src="" />
                        </div>
                        <script>
                            const img = document.getElementById('stream');
                            let oldBlobUrl = '';
                
                            const updateImage = () => {
                                fetch('/stream')
                                    .then(response => {
                                        if (response.status === 204) {
                                            return null; // No content
                                        }
                                        return response.blob();
                                    })
                                    .then(blob => {
                                        if (blob) {
                                            const newBlobUrl = URL.createObjectURL(blob);
                                            img.src = newBlobUrl;
                                            if (oldBlobUrl) {
                                                URL.revokeObjectURL(oldBlobUrl);
                                            }
                                            oldBlobUrl = newBlobUrl;
                                        }
                                        setTimeout(updateImage, 30); // Adjusted interval
                                    })
                                    .catch(error => console.error('Error fetching image:', error));
                            };
                            updateImage();
                        </script>
                    </body>
                </html>
                """)
            })
            
            webServer?.addHandler(forMethod: "GET", path: "/stream", request: GCDWebServerRequest.self, processBlock: { request in
                self.bufferLock.lock()
                let response: GCDWebServerDataResponse
                if let imageData = self.latestImage {
                    response = GCDWebServerDataResponse(data: imageData, contentType: "image/jpeg")
                    self.latestImage = nil
                } else {
                    response = GCDWebServerDataResponse(statusCode: 204)
                }
                self.bufferLock.unlock()
                return response
            })
            
            webServer?.addHandler(forMethod: "POST", path: "/", request: GCDWebServerDataRequest.self, processBlock: { request in
                if let dataRequest = request as? GCDWebServerDataRequest {
                    self.bufferLock.lock()
                    let newData = dataRequest.data
                    if newData?.count ?? 1 <= self.maxBufferSize {
                        self.latestImage = newData
                    } else {
                        print("Received data size exceeds buffer capacity. Discarding the data.")
                    }
                    self.bufferLock.unlock()
                }
                return GCDWebServerDataResponse(statusCode: 200)
            })
            
            do {
                try webServer?.start(options: [
                    GCDWebServerOption_AutomaticallySuspendInBackground: false
                ])
                if let serverURL = webServer?.serverURL {
                    self.serverURL = serverURL
                    print("Server started at \(serverURL)")
                }
            } catch {
                print("Error starting server: \(error)")
            }
        }
    }

    func stopServer() {
        webServer?.stop()
        print("Server stopped")
    }
    
    private func saveServerURLToUserDefaults(url: URL?) {
        guard let userDefaults = UserDefaults(suiteName: AppStrings.groupID) else { return }
        
        if let url = url {
            userDefaults.set(url.absoluteString, forKey: AppStrings.serverUrlKey)
        } else {
            userDefaults.removeObject(forKey: AppStrings.serverUrlKey)
        }
        
        userDefaults.synchronize()
    }

    private func loadServerURLFromUserDefaults() {
        guard let userDefaults = UserDefaults(suiteName: AppStrings.groupID) else { return }
        
        if let urlString = userDefaults.string(forKey: AppStrings.serverUrlKey),
           let url = URL(string: urlString) {
            self.serverURL = url
            print("Getting the IP from UserDefaults (App Group): \(urlString)")
        }
    }
}


