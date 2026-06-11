//
//  DeviceListviewModel.swift
//  Stream Mirror
//

import Foundation
import Network
import Combine

enum PermissionState {
    case checking
    case authorized
    case denied
}


class DeviceListViewModel: ObservableObject {

   
    @Published var permissionState: PermissionState = .checking
    @Published var showLocalNetworkPopup = false
    @Published var showNoNetworkPopup = false

    private let monitor = NWPathMonitor()
    
    private var browser: NWBrowser?

    func checkLocalNetworkPermission() {

        // Previous browser properly stop karo
        browser?.cancel()
        browser = nil

        permissionState = .checking

        let params = NWParameters()
        params.includePeerToPeer = true

        let browser = NWBrowser(
            for: .bonjour(type: "_googlecast._tcp", domain: nil),
            using: params
        )

        self.browser = browser

        browser.stateUpdateHandler = { [weak self] state in

            DispatchQueue.main.async {

                switch state {

                case .ready:
                    self?.permissionState = .authorized
                    self?.showLocalNetworkPopup = false

                    print("✅ Local Network Permission Authorized")

                case .failed(let error):

                    print("❌ Browser Failed:", error)

                    if case NWError.dns(let dnsError) = error,
                       dnsError == kDNSServiceErr_PolicyDenied {

                        self?.permissionState = .denied
                        self?.showLocalNetworkPopup = true

                        print("❌ Local Network Permission Denied")
                    }

                case .waiting(let error):

                    print("⏳ Waiting:", error)

                    if case NWError.dns(let dnsError) = error,
                       dnsError == kDNSServiceErr_PolicyDenied {

                        self?.permissionState = .denied
                        self?.showLocalNetworkPopup = true
                    }

                default:
                    break
                }
            }
        }

        browser.start(queue: DispatchQueue.global())
    }

    func stopChecking() {

        browser?.cancel()
        browser = nil

        monitor.cancel()
    }
    
    func startNetworkMonitoring() {

        monitor.pathUpdateHandler = { [weak self] path in

            DispatchQueue.main.async {

                if path.status == .satisfied {

                    self?.showNoNetworkPopup = false

                } else {

                    self?.showNoNetworkPopup = true
                }
            }
        }

        monitor.start(queue: DispatchQueue.global())
    }
    
    deinit {
        stopChecking()
    }
}
