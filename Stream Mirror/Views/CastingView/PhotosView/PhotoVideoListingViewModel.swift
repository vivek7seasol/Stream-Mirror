//
//  PhotoListingViewModel.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import Foundation
internal import Photos
import SwiftUI
import Combine

class PhotoVideoListingViewModel:NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    
    @Published var assets: [PHAsset] = []
    @Published var showSettingsAlert: Bool = false
    @Published var videoAssets: [PHAsset] = []
    @Published var isPremissionLimited = false
    @Published var isLoading = false
    @Published var showPlaceholder = false
    @Published var selectedIndex = 0
    @Published var showPhotoCasting = false
    @Published var showVideoCasting = false
    @Published var showDeviceList = false
    @Published var showPermissionAlert = false
    @Published var selectedVideoIndex = 0
    @Published var hasLoadedImages = false
    @Published var hasLoadedVideos = false
    
    private var isReloading = false
    
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard !isReloading else { return }
        
        isReloading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            
            self.fetchImages()
            self.fetchVideos()
            
            self.isReloading = false
        }
    }
    
    func requestPhotoAccess() {
        
        if hasLoadedImages && !assets.isEmpty {
            return
        }
        
        isLoading = true
        showPlaceholder = false
        // Pehle current status check karo — no dialog needed
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        DispatchQueue.main.async {
            switch currentStatus {
            case .authorized:
                self.isPremissionLimited = false
                self.fetchImages()
            case .limited:
                self.isPremissionLimited = true
                self.fetchImages()
            case .notDetermined:
                // Tabhi request karo jab pehli baar pucha ja raha ho
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    DispatchQueue.main.async {
                        if status == .authorized {
                            self.isPremissionLimited = false
                            self.fetchImages()

                        } else if status == .limited {
                            self.isPremissionLimited = true
                            self.fetchImages()

                        } else {
                            self.isLoading = false
                            self.showPlaceholder = true
                            self.showSettingsAlert = true
                        }
                    }
                }
            case .denied, .restricted:
                self.isLoading = false
                self.showPlaceholder = true
                self.showSettingsAlert = true
            @unknown default:
                break
            }
        }
    }
    
    func requestVideoAccess() {
        
        if hasLoadedVideos && !videoAssets.isEmpty {
                return
            }
        
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        DispatchQueue.main.async {
            switch currentStatus {
            case .authorized:
                self.isPremissionLimited = false
                self.fetchVideos()
            case .limited:
                self.isPremissionLimited = true
                self.fetchVideos()
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    DispatchQueue.main.async {
                        if status == .authorized {
                            self.isPremissionLimited = false
                            self.fetchVideos()

                        } else if status == .limited {
                            self.isPremissionLimited = true
                            self.fetchVideos()

                        } else {
                            self.isLoading = false
                            self.showPlaceholder = true
                            self.showSettingsAlert = true
                        }
                    }
                }
            case .denied, .restricted:
                self.isLoading = false
                self.showPlaceholder = true
                self.showSettingsAlert = true
            @unknown default:
                break
            }
        }
    }
    
    func fetchImages() {
        
        isLoading = true
        showPlaceholder = false
        
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.predicate = NSPredicate(
            format: "mediaType == %d",
            PHAssetMediaType.image.rawValue
        )
        
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(
                key: "creationDate",
                ascending: false
            )
        ]
        
        let fetchedAssets = PHAsset.fetchAssets(with: fetchOptions)
        
        var tempAssets: [PHAsset] = []
        
        fetchedAssets.enumerateObjects { asset, _, _ in
            tempAssets.append(asset)
        }
        
        DispatchQueue.main.async {

            let oldIDs = self.assets.map(\.localIdentifier)
            let newIDs = tempAssets.map(\.localIdentifier)

            if oldIDs != newIDs {
                self.assets = tempAssets
            }

            self.hasLoadedImages = true

            self.isLoading = false
            self.showPlaceholder = tempAssets.isEmpty
        }
    }
    
    func fetchVideos() {
        
        isLoading = true
        showPlaceholder = false
        
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.predicate = NSPredicate(
            format: "mediaType == %d",
            PHAssetMediaType.video.rawValue
        )
        
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let fetchedAssets = PHAsset.fetchAssets(with: fetchOptions)
        
        var tempAssets: [PHAsset] = []
        
        fetchedAssets.enumerateObjects { asset, _, _ in
            tempAssets.append(asset)
        }
        
        DispatchQueue.main.async {

            let oldIDs = self.videoAssets.map(\.localIdentifier)
            let newIDs = tempAssets.map(\.localIdentifier)

            if oldIDs != newIDs {
                withAnimation(.none) {
                    self.videoAssets = tempAssets
                }
            }

            self.hasLoadedVideos = true

            self.isLoading = false
            self.showPlaceholder = tempAssets.isEmpty
        }
    }
}
