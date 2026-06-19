//
//  IPTVVM.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 08/05/26.
//

import Foundation
import SwiftUI
import Combine

enum selectedType {
    case country,category
}

class IPTVViewModel: ObservableObject {
    @Published var categories: [IPTVCategoryModelElement] = []
    @Published var countries: [IPTVCountryModelElement] = []
    @Published var isLoadings = false
    @Published var isDataLoaded = false
    @Published var selectedType: selectedType = .country
    @Published var selectedChannels: [Channel] = []
    @Published var selectedTitle: String = ""
    @Published var showChannelList = false
    @Published var showDeviceList = false
    @Published var text: String = ""
    
    func fetchIPTVCategory() async {
        
        if let cached = getIPTVCategory() {
            await MainActor.run {
                self.categories = cached
            }
            return
        }
        
        if getIPTVCategory() != nil{
            self.categories = getIPTVCategory() ?? []
            self.isDataLoaded = true
            return
        }
        
        
        guard let url = URL(string: iptvCategoryApi) else {
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                
                return
            }
            
            let categories = try JSONDecoder().decode(IPTVCategoryModel.self, from: data)
            
            await MainActor.run {
                setIPTVCategory(datum: categories)
                self.categories = categories
                self.isDataLoaded = true
            }
            
        } catch {
            await MainActor.run {
                self.isDataLoaded = true
            }
        }
    }
    
    func fetchIPTVCountry() async {
        
        if let cached = getIPTVCountry() {
            await MainActor.run {
                self.countries = cached
            }
            return
        }
        
        if getIPTVCountry() != nil{
            self.countries = getIPTVCountry() ?? []
            self.isDataLoaded = true
            return
        }
        
        guard let url = URL(string: iptvCountryApi) else {
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return
            }
            
            let countries = try JSONDecoder().decode(IPTVCountryModel.self, from: data)
            
            await MainActor.run {
                setIPTVCountry(datum: countries)
                self.countries = countries
                self.isDataLoaded = true
            }
        } catch {
            await MainActor.run {
                self.isDataLoaded = true
            }
        }
    }
    
    func setIPTVCategory(datum: [IPTVCategoryModelElement]) {
        do {
            let data = try JSONEncoder().encode(datum)
            UserDefaults.standard.set(data, forKey: "IPTV_Cat_Data")
            UserDefaults.standard.synchronize()
        } catch let error {
            print("❌ Error saving splash data:", error.localizedDescription)
        }
    }
    
    func getIPTVCategory() -> [IPTVCategoryModelElement]? {
        if let data = UserDefaults.standard.data(forKey: "IPTV_Cat_Data") {
            if let loaded = try? JSONDecoder().decode([IPTVCategoryModelElement].self, from: data) {
                return loaded
            }
        }
        return nil
    }
    
    func setIPTVCountry(datum: [IPTVCountryModelElement]) {
        do {
            let data = try JSONEncoder().encode(datum)
            UserDefaults.standard.set(data, forKey: "IPTV_Country_Data")
            UserDefaults.standard.synchronize()
        } catch let error {
            print("❌ Error saving splash data:", error.localizedDescription)
        }
    }
    
    func getIPTVCountry() -> [IPTVCountryModelElement]? {
        if let data = UserDefaults.standard.data(forKey: "IPTV_Country_Data") {
            if let loaded = try? JSONDecoder().decode([IPTVCountryModelElement].self, from: data) {
                return loaded
            }
        }
        return nil
    }
}

var iptvCategoryApi: String = "https://d2is1ss4hhk4uk.cloudfront.net/iptv/iptv_grouped_by_category.json"
var iptvCountryApi: String = "https://d2is1ss4hhk4uk.cloudfront.net/iptv/iptv_grouped_by_country.json"
