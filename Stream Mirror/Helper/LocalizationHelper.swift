//
//  LocalizationHelper.swift
//  AlarmClock
//
//  Created by Sumit zalavadiya on 17/09/25.
//

import Foundation

class LocalizationHelper {
    static let shared = LocalizationHelper()
    private var bundle: Bundle? = nil
    
    private init() { }
    
    func setLanguage(code: String) {
        UserDefaults.standard.set(code, forKey: "appLanguage")
        UserDefaults.standard.synchronize()
        
        if let path = Bundle.main.path(forResource: code, ofType: "lproj") {
            bundle = Bundle(path: path)
        } else {
            bundle = Bundle.main
        }
    }
    
    func localizedString(for key: String) -> String {
        return bundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
}

extension String {
    var localized: String {
        return LocalizationHelper.shared.localizedString(for: self)
    }
}
