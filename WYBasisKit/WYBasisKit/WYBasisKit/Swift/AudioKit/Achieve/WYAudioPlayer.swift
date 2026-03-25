//
//  WYAudioPlayer.swift
//  WYBasisKit
//
//  Created by guanren on 2026/3/23.
//

import Foundation
import AVFoundation

internal final class WYAudioPlayer: NSObject {
    weak var kit: WYAudioKit?
    
    private var player: AVPlayer?
    private var displayLink: CADisplayLink?
    private var timeObserver: Any?
    private(set) var isPlaying: Bool = false
    private(set) var isPaused: Bool = false
    private var currentURL: URL?
    
    func playPlayback(url: URL? = nil) {
        let playURL = url ?? kit?.currentRecordFileURL
        guard let u = playURL else { return }
        currentURL = u
        
        let item = AVPlayerItem(url: u)
        player = AVPlayer(playerItem: item)
        player?.rate = kit?.playbackRate ?? 1.0
        player?.play()
        isPlaying = true
        isPaused = false
        setupDisplayLink()
        setupTimeObserver()
        
        DispatchQueue.main.async {
            self.kit?.delegate?.wy_audioPlayerStateDidChanged?(audioKit: self.kit!, state: .start)
            self.kit?.audioPlayer = self.player
        }
    }
    
    func playStreamingRemoteAudio(remoteUrl: URL, rate: Float = 1.0, success: @escaping (URL) -> Void, failed: @escaping (Error?) -> Void) {
        currentURL = remoteUrl
        let item = AVPlayerItem(url: remoteUrl)
        player = AVPlayer(playerItem: item)
        player?.rate = rate
        player?.play()
        isPlaying = true
        setupDisplayLink()
        setupTimeObserver()
        
        DispatchQueue.main.async {
            success(remoteUrl)
            self.kit?.delegate?.wy_audioPlayerStateDidChanged?(audioKit: self.kit!, state: .start)
        }
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateProgress() {
        guard let p = player, let item = p.currentItem else { return }
        let current = CMTimeGetSeconds(item.currentTime())
        let duration = CMTimeGetSeconds(item.duration)
        let progress = duration > 0 ? current / duration : 0
        DispatchQueue.main.async {
            self.kit?.delegate?.wy_audioPlayerTimeUpdated?(audioKit: self.kit!, localUrl: self.currentURL ?? URL(fileURLWithPath: ""), currentTime: current, duration: duration, progress: progress)
        }
    }
    
    private func setupTimeObserver() {
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    func pausePlayback() {
        player?.pause()
        isPaused = true
        displayLink?.invalidate()
        displayLink = nil
        DispatchQueue.main.async {
            self.kit?.delegate?.wy_audioPlayerStateDidChanged?(audioKit: self.kit!, state: .pause)
        }
    }
    
    func resumePlayback() {
        player?.play()
        isPaused = false
        setupDisplayLink()
        DispatchQueue.main.async {
            self.kit?.delegate?.wy_audioPlayerStateDidChanged?(audioKit: self.kit!, state: .resume)
        }
    }
    
    func stopPlayback() {
        player?.pause()
        player?.seek(to: .zero)
        displayLink?.invalidate()
        displayLink = nil
        if let obs = timeObserver { player?.removeTimeObserver(obs) }
        timeObserver = nil
        isPlaying = false
        isPaused = false
        DispatchQueue.main.async {
            self.kit?.delegate?.wy_audioPlayerStateDidChanged?(audioKit: self.kit!, state: .stop)
        }
    }
    
    func seekPlayback(time: TimeInterval) {
        let cmTime = CMTime(seconds: max(0, min(time, player?.currentItem?.duration.seconds ?? 0)), preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    var playbackRate: Float {
        get { player?.rate ?? 1.0 }
        set { player?.rate = newValue }
    }
    
    func releaseResources() {
        stopPlayback()
        player = nil
    }
}
