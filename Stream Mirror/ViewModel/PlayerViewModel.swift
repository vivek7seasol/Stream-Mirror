//
//  PlayerViewModel.swift
//  Stream Mirror
//
//  Created by Vivek Rakholiya on 11/06/26.
//

import Foundation
import Foundation
import AVFoundation
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {

    // MARK: - Published
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var totalDuration: Double = 1
    @Published var sliderValue: Double = 0
    @Published var isDragging = false

    // MARK: - Properties
    @Published private(set) var player: AVPlayer?

    private var timeObserver: Any?
    private var durationTask: Task<Void, Never>?

    // MARK: - Setup
    func setup(with player: AVPlayer) {

        cleanup()

        self.player = player

        player.play()
        isPlaying = true

        durationTask = Task {
            await loadDuration()
        }

        let interval = CMTime(seconds: 0.25,
                              preferredTimescale: 600)

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in

            guard let self else { return }

            let secs = CMTimeGetSeconds(time)

            guard secs.isFinite else { return }

            self.currentTime = secs

            if !self.isDragging {
                self.sliderValue = secs
            }

            self.isPlaying =
            player.timeControlStatus == .playing

            if self.totalDuration <= 1,
               let duration = player.currentItem?.duration {

                let dSecs = CMTimeGetSeconds(duration)

                if dSecs.isFinite && dSecs > 1 {
                    self.totalDuration = dSecs
                }
            }
        }
    }

    // MARK: - Cleanup
    func cleanup() {

        durationTask?.cancel()

        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        player?.pause()

        currentTime = 0
        sliderValue = 0
        isPlaying = false
    }

    // MARK: - Controls
    func togglePlayPause() {

        guard let player else { return }

        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seekTo(seconds: Double) {

        let target = CMTime(
            seconds: seconds,
            preferredTimescale: 600
        )

        player?.seek(
            to: target,
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak self] _ in
            self?.currentTime = seconds
        }
    }

    func seekForward(seconds: Double = 10) {

        let newTime = min(
            currentTime + seconds,
            totalDuration
        )

        sliderValue = newTime
        seekTo(seconds: newTime)
    }

    func seekBackward(seconds: Double = 10) {

        let newTime = max(
            currentTime - seconds,
            0
        )

        sliderValue = newTime
        seekTo(seconds: newTime)
    }

    // MARK: - Duration
    private func loadDuration() async {

        guard let item = player?.currentItem else { return }

        let directDuration =
        CMTimeGetSeconds(item.asset.duration)

        if directDuration.isFinite &&
            directDuration > 1 {

            totalDuration = directDuration
            return
        }

        guard let asset = item.asset as? AVURLAsset else {
            return
        }

        do {

            let duration = try await asset.load(.duration)
            let secs = CMTimeGetSeconds(duration)

            if secs.isFinite && secs > 1 {
                totalDuration = secs
            }

        } catch {

            print("Duration load failed:", error)
        }
    }

    // MARK: - Formatter
    func formatTime(_ seconds: Double) -> String {

        guard seconds.isFinite,
              seconds >= 0 else {
            return "00:00"
        }

        let total = Int(seconds)

        return String(
            format: "%02d:%02d",
            total / 60,
            total % 60
        )
    }
}
