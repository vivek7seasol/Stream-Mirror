//
//  ModelSearchImage.swift
//  UtilityBox
//
//  Created by Vivek Rakholiya on 08/06/26.
//

import Foundation

struct ModelFindImage: Codable {
    let resultCount: Int?
    let pageCount: Int
    let pageSize: Int?
    let page: Int
    let results: [SearchImage]
    
    enum CodingKeys: String, CodingKey {
        case resultCount = "result_count"
        case pageCount = "page_count"
        case pageSize = "page_size"
        case page
        case results
    }
}

struct SearchImage: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let title: String?
    let thumbnail: String?
    let url: String?
    let creator: String?
}
