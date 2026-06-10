//
//  ConnectedTVs.swift
//  TV Remote
//
//  Created by iOS Developer on 25/08/2025.
//


import Foundation


class ConnectedTVs {
    static let shared = ConnectedTVs()
    private let key = "TVIPs"

    func saveIP(_ ip: String) {
        var ips = getAllIPs()
        guard !ips.contains(ip) else { return }
        ips.append(ip)
        UserDefaults.standard.set(ips, forKey: key)
    }

    func isIPKnown(_ ip: String) -> Bool {
        return getAllIPs().contains(ip)
    }

    private func getAllIPs() -> [String] {
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }
}
