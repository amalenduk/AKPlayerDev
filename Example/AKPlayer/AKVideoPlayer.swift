//
//  AKVideoPlayer.swift
//  AKPlayer_Example
//
//  Copyright (c) 2020 Amalendu Kar
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import AVFoundation
import AKPlayer

open class AKVideoPlayer: UIView {
    
    // MARK:- UIElements
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var playerView: AKPlayerView!
    @IBOutlet private weak var controlView: AKVideoPlayerControlView!
    
    // MARK:- Variables
    
    open private(set) var player: AKPlayer!
    
    public let configuration = AKPlayerConfiguration()
    
    open var playbackRate: AKPlaybackRate {
        get { player.rate }
        set { player.rate = newValue }
    }
    
    open var hasPendingSeeks: Bool = false
    
    weak var delegate: AKPlayerDelegate? {
        didSet {
            player.delegate = delegate
        }
    }
    
    // MARK: Lifecycle
    
    // Custom initializers go here
    
    // MARK: View Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // MARK: Layout
    
    let avplayer = AVPlayer()
    
    // MARK: Additional Helpers
    
    /// Called by both `init(frame: CGRect)` and `init?(coder: NSCoder)`,
    open func commonInit() {
        Bundle.main.loadNibNamed("AKVideoPlayer", owner: self, options: nil)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(contentView)
        controlView.delegate = self
        setupPlayer()
        addObserbers()
    }
    
    private func setupPlayer() {
        player = AKPlayer(player: avplayer, configuration: configuration)
        playerView.playerLayer.player = player.player
        player.delegate = self
        try? player.prepare()
    }
    
    private func addObserbers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterInBackground(_ :)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterInForeground(_ :)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // MARK: - Obserbers
    
    @objc func didEnterInBackground(_ notification: Notification) {
        playerView.player = nil
    }
    
    @objc func didEnterInForeground(_ notification: Notification) {
        playerView.player = player.player
    }
}

// MARK: - AKPlayerCommand

extension AKVideoPlayer: AKPlayerCommandsProtocol {
    
    public func load(media: AKPlayable) {
        player.load(media: media)
    }
    
    public func load(media: AKPlayable, autoPlay: Bool) {
        player.load(media: media, autoPlay: autoPlay)
    }
    
    public func load(media: AKPlayable, autoPlay: Bool, at position: CMTime) {
        player.load(media: media, autoPlay: autoPlay, at: position)
    }
    
    public func load(media: AKPlayable, autoPlay: Bool, at position: Double) {
        player.load(media: media, autoPlay: autoPlay, at: position)
    }
    
    public func play() {
        player.play()
    }
    
    public func play(at rate: AKPlaybackRate) {
        
    }
    
    public func pause() {
        player.pause()
    }
    
    public func togglePlayPause() {
        player.togglePlayPause()
    }
    
    public func stop() {
        player.stop()
    }
    
    public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: @escaping (Bool) -> Void) {
        player.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
    }
    
    public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
        player.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
    }
    
    public func seek(to time: CMTime, completionHandler: @escaping (Bool) -> Void) {
        player.seek(to: time, completionHandler: completionHandler)
    }
    
    public func seek(to time: CMTime) {
        player.seek(to: time)
    }
    
    public func seek(to time: Double, completionHandler: @escaping (Bool) -> Void) {
        player.seek(to: time, completionHandler: completionHandler)
    }
    
    public func seek(to time: Double) {
        player.seek(to: time)
    }
    
    public func seek(to date: Date, completionHandler: @escaping (Bool) -> Void) {
        player.seek(to: date, completionHandler: completionHandler)
    }
    
    public func seek(to date: Date) {
        player.seek(to: date)
    }
    
    public func seek(toOffset offset: Double) {
        player.seek(to: offset)
    }
    
    public func seek(toOffset offset: Double, completionHandler: @escaping (Bool) -> Void) {
        player.seek(to: offset, completionHandler: completionHandler)
    }
    
    public func seek(toPercentage percentage: Double, completionHandler: @escaping (Bool) -> Void) {
        player.seek(toPercentage: percentage, completionHandler: completionHandler)
    }
    
    public func seek(toPercentage percentage: Double) {
        player.seek(toPercentage: percentage)
    }
    
    public func step(by count: Int) {
        player.step(by: count)
    }
    
    public func fastForward() {
        player.fastForward()
    }
    
    public func fastForward(at rate: AKPlaybackRate) {
        player.fastForward(at: rate)
    }
    
    public func rewind() {
        player.rewind()
    }
    
    public func rewind(at rate: AKPlaybackRate) {
        player.rewind(at: rate)
    }
}

// MARK: - AKPlayerDelegate

// MARK: - AKVideoPlayerControlViewDelegate

extension AKVideoPlayer: AKVideoPlayerControlViewDelegate {
    
    func controlView(_ view: AKVideoPlayerControlView, didTapPlaybackButton button: AKPlaybackButton) {
        switch player.state {
        case .playing, .buffering, .loading, .waitingForNetwork:
            player.pause()
        case .idle, .failed:
            player.play()
        case .loaded, .paused, .stopped:
            player.play()
        }
    }
    
    func controlView(_ view: AKVideoPlayerControlView, progressSlider slider: UISlider, didChanged value: Float) {
        if let duration = player.currentItem?.duration, duration.isValid, duration.isNumeric {
            controlView.setCurrentTime(CMTime(seconds: ((duration.seconds * Double(slider.value)) / 100), preferredTimescale: configuration.preferredTimeScale))
        }
    }
    
    func controlView(_ view: AKVideoPlayerControlView, progressSlider slider: UISlider, didStartTrackingWith value: Float) { }
    
    func controlView(_ view: AKVideoPlayerControlView, progressSlider slider: UISlider, didEndTrackingWith value: Float) {
        hasPendingSeeks = true
        seek(toPercentage: Double(slider.value)) { _ in
            self.hasPendingSeeks = false
        }
    }
}

// MARK: - AKPlayerDelegate

extension AKVideoPlayer: AKPlayerDelegate {
    
    public func akPlayer(_ player: AKPlayer, didChangeStateTo state: AKPlayerState) {
        switch state {
        case .idle:
            controlView.progressSlider(false)
            controlView.setPlaybackState(.paused)
        case .loading:
            controlView.progressSlider(false)
            controlView.setPlaybackState(.playing)
        case .loaded:
            controlView.progressSlider(true)
            if let currentItemDuration = player.currentItemDuration {
                controlView.setDuration(currentItemDuration)
            }
            controlView.setPlaybackState(.paused)
        case .buffering:
            controlView.progressSlider(true)
            controlView.setPlaybackState(.playing)
        case .paused:
            controlView.progressSlider(true)
            controlView.setPlaybackState(.paused)
        case .playing:
            controlView.progressSlider(true)
            controlView.setPlaybackState(.playing)
        case .stopped:
            controlView.progressSlider(true)
            controlView.setPlaybackState(.stopped)
        case .waitingForNetwork:
            controlView.progressSlider(true)
            controlView.setPlaybackState(.playing)
        case .failed:
            controlView.progressSlider(false)
            controlView.setPlaybackState(.failed)
        }
        
        controlView.changedPlayerState(state)
    }
    
    public func akPlayer(_ player: AKPlayer, didChangeMediaTo media: AKPlayable) {
        controlView.resetControlls()
    }
    
    public func akPlayer(_ player: AKPlayer, didChangePlaybackRateTo newRate: AKPlaybackRate, from oldRate: AKPlaybackRate) {}
    public func akPlayer(_ player: AKPlayer, didChangeCurrentTimeTo currentTime: CMTime, for media: AKPlayable) {
        if !hasPendingSeeks {
            if !controlView.progressSlider.isTracking {
                controlView.setCurrentTime(currentTime)
            }
            controlView.setSliderProgress(currentTime, itemDuration: player.currentItemDuration)
        }
    }
    public func akPlayer(_ player: AKPlayer, playerItemDidReachEnd endTime: CMTime, for media: AKPlayable) {}
    public func akPlayer(_ player: AKPlayer, didChangeVolumeTo volume: Float) {}
    public func akPlayer(_ player: AKPlayer, didChangeMutedStatusTo isMuted: Bool) {}
    public func akPlayer(_ player: AKPlayer, unavailableActionWith reason: AKPlayerUnavailableCommandReason) {}
    public func akPlayer(_ player: AKPlayer, didFailWith error: AKPlayerError) {}
}
