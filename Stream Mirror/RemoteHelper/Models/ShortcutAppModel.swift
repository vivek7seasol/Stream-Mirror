//
//  ShortcutAppModel.swift
//  TV Remote
//
//  Created by iOS Developer on 25/08/2025.
//


import Foundation

struct ShortcutAppModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let image: String
    let url: String
    let tvApp: TVApp
}
