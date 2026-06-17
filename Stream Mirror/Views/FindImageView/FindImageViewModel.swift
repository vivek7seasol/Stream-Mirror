//
//  SearchImageViewModel.swift
//  UtilityBox
//
//  Created by Vivek Rakholiya on 08/06/26.
//

import Foundation
import Combine
import UIKit

class FindImageViewModel: ObservableObject {
 
    @Published var showConnectionView = false
    @Published var isLoading = false
    @Published var totalPages: Int = 1
    @Published var images: [SearchImage] = []
    @Published var errorMessage: String?
    @Published var showPreview = false
    @Published var showFavImage = false
    @Published var isFirstAppear = true
    @Published var showDeviceList = false
    @Published var hasSearched = false
    
    @Published var selectedURL : String?
    @Published var cachedImages: [String: UIImage] = [:]
    @Published var searchTask: DispatchWorkItem?
    
    @Published var showPhotoCasting = false
    @Published var selectedIndex = 0
    @Published var selectedImageURLs: [String] = []
    
    private var currentPage = 1
    private var isLoadingMore = false
    private var currentQuery = ""
    
    func clearResults() {
        images.removeAll()
        currentPage = 1
        totalPages = 1
        currentQuery = ""
        errorMessage = nil
        isLoading = false
        isLoadingMore = false
    }
    
    func searchOnlineImages(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            hasSearched = false
            clearResults()
            return
        }

        currentQuery = trimmedQuery
        currentPage = 1
        totalPages = 1
        images.removeAll()

        fetchOnlineImages(query: trimmedQuery, page: 1)
    }
    
    func loadMoreIfNeeded(currentItem: SearchImage) {
        guard !isLoadingMore,
              currentPage < totalPages,
              currentItem.id == images.last?.id,
              !currentQuery.isEmpty else { return }
        
        currentPage += 1
        fetchOnlineImages(query: currentQuery, page: currentPage)
    }
    
    private func fetchOnlineImages(query: String, page: Int) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.openverse.org/v1/images/?q=\(encodedQuery)&page=\(page)") else {
            errorMessage = "Invalid search query"
            return
        }
        
        isLoading = true
        isLoadingMore = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }
            
            Task { @MainActor in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.isLoadingMore = false
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data found"
                    self.isLoading = false
                    self.isLoadingMore = false
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(ModelFindImage.self, from: data)

                    if page == 1 {
                        self.images = result.results

                        // 👇 Yaha set karo
                        self.hasSearched = true
                    } else {
                        self.images.append(contentsOf: result.results)
                    }

                    self.totalPages = result.pageCount
                    self.currentPage = result.page
                    self.isLoading = false
                    self.isLoadingMore = false
                } catch {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.isLoadingMore = false
                }
            }
        }.resume()
    }
}
