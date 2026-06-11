//
//  ModelYoutube.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import Foundation

struct YouTubeAPIResponse: Codable {
    let title: String?
    let channelTitle: String?
    let thumbnail: [YouTubeThumbnail]?
    let formats: [YouTubeFormat]?
}

struct YouTubeThumbnail: Codable {
    let url: String?
}

struct YouTubeFormat: Codable {
    let itag: Int?
    let url: String?
}
