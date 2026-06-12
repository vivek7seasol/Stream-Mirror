//
//  CastMusicVM.swift
//  ClarioMirror
//
//  Created by Vivek Rakholiya on 07/05/26.
//

import Foundation
import SwiftUI
import AVFAudio
internal import MediaPlayer
import Combine
import AVFoundation

class MusicViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var songs: [Song] = []
    @Published var playlistMusics: [Song] = []
    @Published var favorites: [Song] = []
    @Published var currentlyPlaying: Song?
    @Published var isPlaying = false
    @Published var isShuffled = false
    @Published var isLoadings = false
    @Published var isRepeat = false
    @Published var refreshID = UUID()
    @Published var currentIndex: Int = 0
    @Published var playbackProgress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var showPermissionAlert = false
    @Published var showDeviceList = false
    @Published var showFavMusicList = false
    @Published var selectedSong: Song?
    @Published var showMusiccasting = false
    @Published var showPlaceholder = false
    
    private let mediaQuery = MPMediaQuery.songs()
    private var originalSongs: [Song] = []
    private var shuffledSongs: [Song] = []
    
    // MARK: - New Music Player
    private let musicPlayer = MPMusicPlayerController.applicationMusicPlayer
    private var progressTimer: Timer?

    
    // MARK: - Setup
    private func setupMusicPlayer() {
        musicPlayer.beginGeneratingPlaybackNotifications()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStateDidChange),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemDidChange),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer
        )

        print("✅ Music player setup complete")
    }

    private func setupMediaLibraryObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(mediaLibraryDidChange),
            name: .MPMediaLibraryDidChange,
            object: nil
        )
    }

    @objc private func mediaLibraryDidChange() {
        print("📀 Media library changed — refetching songs")
        fetchMusic()
    }

    // MARK: - Authorization & Fetch
    func requestMusicAccessAndFetch() {

        let currentStatus = MPMediaLibrary.authorizationStatus()

        // Already authorized
        if currentStatus == .authorized {
            fetchMusic()
            return
        }

        MPMediaLibrary.requestAuthorization { status in

            DispatchQueue.main.async {

                switch status {

                case .authorized:

                    self.isLoadings = true

                    MPMediaLibrary.default()
                        .beginGeneratingLibraryChangeNotifications()

                    // Small delay so library becomes available instantly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {

                        self.fetchMusic()
                    }

                case .denied, .restricted:

                    self.showPermissionAlert = true
                    self.songs = []
                    self.isLoadings = false
                    self.showPlaceholder = true

                case .notDetermined:
                    break

                @unknown default:
                    break
                }
            }
        }
    }
    
    // Add these to your CastMusicViewModel
    func PreviousSong() -> Song? {
        guard let current = currentlyPlaying,
              let currentIndex = songs.firstIndex(where: { $0.id == current.id }) else {
            return nil
        }
        let previousIndex = currentIndex > 0 ? currentIndex - 1 : songs.count - 1
        return songs[previousIndex]
    }

    func NextSong() -> Song? {
        guard let current = currentlyPlaying,
              let currentIndex = songs.firstIndex(where: { $0.id == current.id }) else {
            return nil
        }
        let nextIndex = currentIndex < songs.count - 1 ? currentIndex + 1 : 0
        return songs[nextIndex]
    }

    // MARK: - Format Time
    var currentTimeString: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Shuffle / Repeat
    func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            shuffledSongs = playlistMusics.shuffled()
            if let current = currentlyPlaying,
               let index = shuffledSongs.firstIndex(where: { $0.id == current.id }) {
                currentIndex = index
            } else { currentIndex = 0 }
            print("🔀 Shuffle enabled")
        } else {
            if let current = currentlyPlaying,
               let index = originalSongs.firstIndex(where: { $0.id == current.id }) {
                currentIndex = index
            } else { currentIndex = 0 }
            print("🔀 Shuffle disabled")
        }
        refreshID = UUID()
    }

    func toggleRepeat() {
        isRepeat.toggle()
        musicPlayer.repeatMode = isRepeat ? .one : .none
        print("🔁 Repeat \(isRepeat ? "enabled" : "disabled")")
    }

    // MARK: - Set Playlist
    func setMusics(_ musics: [Song], startIndex: Int) {
        self.originalSongs = musics
        self.playlistMusics = musics
        self.currentIndex = startIndex
        playCurrentMusic()
    }

    private func playCurrentMusic() {
        let currentQueue = isShuffled ? shuffledSongs : playlistMusics
        guard currentQueue.indices.contains(currentIndex) else { return }
        play(song: currentQueue[currentIndex])
    }

    // MARK: - Favorites
    func toggleFavorite(song: Song) {
        var favs = getFavorites()
        if favs.contains(song.title) {
            favs.removeAll { $0 == song.title }
        } else {
            favs.append(song.title)
        }
        saveFavorites(favs)
        fetchFavSongs()
    }

    func isFavorite(song: Song) -> Bool {
        return getFavorites().contains(song.title)
    }

    func fetchFavSongs() {
        let favoriteTitles = getFavorites()
        favorites = playlistMusics.filter { favoriteTitles.contains($0.title) }
    }

    // MARK: - Fetch Songs
    func fetchMusic() {
        isLoadings = true
        guard let items = MPMediaQuery.songs().items, !items.isEmpty else {

            DispatchQueue.main.async {

                self.originalSongs = []
                self.songs = []
                self.playlistMusics = []

                self.isLoadings = false
                self.showPlaceholder = true
            }

            print("❌ No songs found")

            return
        }

        let fetchedSongs: [Song] = items.compactMap { item in
            guard let title = item.title else { return nil }
            let artwork = item.artwork
            return Song(
                id: UUID().uuidString,
                title: title,
                artist: item.artist ?? "Unknown Artist",
                album: item.albumTitle ?? "Unknown Album",
                duration: item.playbackDuration,
                assetURL: item.assetURL,
                artwork: artwork,
                mediaItem: item
            )
        }.sorted { $0.title < $1.title }

        DispatchQueue.main.async {

            self.originalSongs = fetchedSongs
            self.songs = fetchedSongs
            self.playlistMusics = fetchedSongs

            self.fetchFavSongs()

            self.isLoadings = false
            self.showPlaceholder = fetchedSongs.isEmpty
        }

        print("🎵 Loaded \(fetchedSongs.count) songs")
    }

    // MARK: - Playback Controls
    func play(song: Song) {
        guard let mediaItem = song.mediaItem else {
            print("❌ No MPMediaItem for \(song.title)")
            return
        }

        musicPlayer.setQueue(with: MPMediaItemCollection(items: [mediaItem]))
        musicPlayer.play()
        currentlyPlaying = song
        isPlaying = true
        startProgressTimer()
        print("▶️ Playing: \(song.title)")
    }

    func playNext() {
        let currentQueue = isShuffled ? shuffledSongs : playlistMusics
        guard !currentQueue.isEmpty else { return }

        if isRepeat {
            playCurrentMusic()
        } else {
            currentIndex = (currentIndex + 1) % currentQueue.count
            playCurrentMusic()
        }
    }

    func playPrevious() {
        let currentQueue = isShuffled ? shuffledSongs : playlistMusics
        guard !currentQueue.isEmpty else { return }
        currentIndex = (currentIndex - 1 + currentQueue.count) % currentQueue.count
        playCurrentMusic()
    }

    func pause() {
        musicPlayer.pause()
        isPlaying = false
        stopProgressTimer()
        print("⏸️ Paused")
    }

    func resume() {
        musicPlayer.play()
        isPlaying = true
        startProgressTimer()
        print("▶️ Resumed")
    }

    func stop() {
        musicPlayer.stop()
        isPlaying = false
        currentlyPlaying = nil
        playbackProgress = 0
        currentTime = 0
        stopProgressTimer()
        print("⏹️ Stopped")
    }

    func seek(to progress: Double) {
        guard let item = musicPlayer.nowPlayingItem else { return }
        let newTime = progress * item.playbackDuration
        musicPlayer.currentPlaybackTime = newTime
        currentTime = newTime
        playbackProgress = progress
    }

    // MARK: - Timer for progress
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateProgress()
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateProgress() {
        guard let item = musicPlayer.nowPlayingItem else { return }
        currentTime = musicPlayer.currentPlaybackTime
        playbackProgress = item.playbackDuration > 0
            ? currentTime / item.playbackDuration
            : 0
    }

    // MARK: - Notifications
    @objc private func playbackStateDidChange() {
        switch musicPlayer.playbackState {
        case .playing:
            isPlaying = true
            startProgressTimer()
        case .paused, .stopped, .interrupted:
            isPlaying = false
            stopProgressTimer()
        default:
            break
        }
    }

    @objc private func nowPlayingItemDidChange() {
        if let currentItem = musicPlayer.nowPlayingItem {
            currentlyPlaying = songs.first { $0.title == currentItem.title }
        } else {
            currentlyPlaying = nil
        }
    }
    
    func saveFavorites(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: "MusicFav")
    }
    
    func getFavorites() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "MusicFav") ?? []
    }
}

struct Song: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let assetURL: URL?
    let artwork: MPMediaItemArtwork?
    let mediaItem: MPMediaItem?   // ✅ NEW PROPERTY

    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Equatable
    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }
}
