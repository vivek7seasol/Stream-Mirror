//
//  IPTVModel.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 08/05/26.
//

import Foundation

struct IPTVCountryModelElement: Codable, Hashable {
    let countryCodes: String?
    let country: String?
    let flag: String?
    let channels: [Channel]?
}

typealias IPTVCountryModel = [IPTVCountryModelElement]


struct IPTVCategoryModelElement: Codable, Hashable {
    let category: String?
    let channels: [Channel]?
}

// MARK: - Channel
struct Channel: Codable, Hashable {
    let name: String?
    let logo: String?
    let url: String?
}

typealias IPTVCategoryModel = [IPTVCategoryModelElement]

