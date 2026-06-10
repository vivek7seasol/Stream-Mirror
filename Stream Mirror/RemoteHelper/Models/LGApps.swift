//
//  LGApps.swift
//  TV Remote
//
//  Created by iOS Developer on 18/01/2026.
//


import Foundation

struct LGApps: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let imageName: String
    let url: String
    
    init(name: String, imageName: String, url: String) {
        self.id = UUID()
        self.name = name
        self.imageName = imageName
        self.url = url
    }
}
