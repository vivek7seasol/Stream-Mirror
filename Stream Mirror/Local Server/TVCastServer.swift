//
//  WebServer.swift
//  Screen Mirroring Casting
//
//  Created by iOS Developer on 16/09/2025.
//


import Foundation
import ConnectSDK
import Combine
import Network

class TVCastServer: ObservableObject {
    static let shared = TVCastServer()
    private var webServer: GCDWebServer?
    @Published var serverURL: URL?
    @Published var isConnectedToNetwork: Bool = true
    private var monitor: NWPathMonitor?
    private var monitorQueue: DispatchQueue?
    
    init() {
        startNetworkMonitoring()
    }

    private func startNetworkMonitoring() {
        monitor = NWPathMonitor()
        monitorQueue = DispatchQueue(label: "NetworkMonitorQueue")
        
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnectedToNetwork = path.status == .satisfied
                
                if self?.isConnectedToNetwork == true {
                    if self?.webServer == nil {
                        self?.setupServer()
                    }
                } else {
                    print("No network connection. Server cannot start.")
                }
            }
        }
        
        monitor?.start(queue: monitorQueue!)
    }
    
    private func setupServer() {
        guard isConnectedToNetwork else {
            print("Cannot start the server without network connection.")
            return
        }
        
        if webServer == nil {
            webServer = GCDWebServer()
            
            webServer?.addHandler(forMethod: "GET", pathRegex: "/view/.*", request: GCDWebServerRequest.self) { request in
                guard let requestPath = request?.path else { return GCDWebServerErrorResponse(statusCode: 400) }
                
                // Extract the filename (e.g., DD86744B...jpg)
                let fileName = (requestPath as NSString).lastPathComponent
                
                // Construct the actual image path that the server already handles
                let imageURL = "/files/\(fileName)"
                
                // Create the HTML wrapper
                let htmlContent = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body { margin: 0; background-color: black; display: flex; justify-content: center; align-items: center; height: 100vh; overflow: hidden; }
                        img { max-width: 100%; max-height: 100%; object-fit: contain; }
                    </style>
                </head>
                <body>
                    <img src="\(imageURL)">
                </body>
                </html>
                """
                
                return GCDWebServerDataResponse(html: htmlContent)
            }
            
            webServer?.addHandler(forMethod: "POST", path: "/upload", request: GCDWebServerDataRequest.self) { request in
                if let dataRequest = request as? GCDWebServerDataRequest {
                    let contentType = request?.contentType ?? "application/octet-stream"
                    let fileExtension: String
                    
                    if contentType.contains("image") {
                        fileExtension = ".jpg"
                    } else if contentType.contains("video") {
                        fileExtension = ".mp4"
                    } else {
                        fileExtension = ".dat"
                    }
                    
                    let fileName = UUID().uuidString + fileExtension
                    let filePath = NSTemporaryDirectory().appending(fileName)
                    do {
                        try dataRequest.data.write(to: URL(fileURLWithPath: filePath))
                        print("File uploaded to: \(filePath)")
                        let fileURL = self.webServer?.serverURL!.appendingPathComponent("files/\(fileName)").absoluteString
                        return GCDWebServerDataResponse(text: fileURL)
                    } catch {
                        print("Error saving file: \(error)")
                        return GCDWebServerErrorResponse(statusCode: 500)
                    }
                }
                return GCDWebServerErrorResponse(statusCode: 400)
            }
            
            webServer?.addHandler(forMethod: "GET", pathRegex: "/files/.*", request: GCDWebServerRequest.self) { request in
                do {
                    let fileManager = FileManager.default
                    let filePath = NSTemporaryDirectory().appending((request?.path.replacingOccurrences(of: "/files/", with: ""))!)
                    let mediaURL = URL(fileURLWithPath: filePath)
                    
                    let fileData = try Data(contentsOf: mediaURL)
                    let contentType = self.determineContentType(for: mediaURL.pathExtension)
                    
                    // Handle HTTP Range requests
                    if let rangeHeader = request?.headers["Range"] {
                        let rangePrefix = "bytes="
                        if (rangeHeader as AnyObject).hasPrefix(rangePrefix) {
                            let range = (rangeHeader as AnyObject).replacingOccurrences(of: rangePrefix, with: "")
                            let rangeParts = range.split(separator: "-")
                            if let start = Int(rangeParts[0]), start < fileData.count {
                                let end: Int
                                if rangeParts.count > 1, let endPart = Int(rangeParts[1]) {
                                    end = endPart
                                } else {
                                    end = fileData.count - 1
                                }
                                
                                if start <= end && end < fileData.count {
                                    let length = end - start + 1
                                    let dataSlice = fileData.subdata(in: start..<start + length)
                                    let contentRange = "bytes \(start)-\(end)/\(fileData.count)"
                                    let response = GCDWebServerDataResponse(data: dataSlice, contentType: contentType)
                                    response?.setValue(contentRange, forAdditionalHeader: "Content-Range")
                                    response?.setValue("bytes", forAdditionalHeader: "Accept-Ranges")
                                    response?.statusCode = 206  // Partial Content
                                    return response
                                }
                            }
                        }
                    }
                    
                    // If no range header, serve full file
                    return GCDWebServerDataResponse(data: fileData, contentType: contentType)
                    
                } catch {
                    print("Error reading file data: \(error)")
                    return GCDWebServerResponse(statusCode: 500)
                }
            }
            
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

    private func determineContentType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "mp4":
            return "video/mp4"
        default:
            return "application/octet-stream"
        }
    }

    deinit {
        webServer?.stop()
    }
}
