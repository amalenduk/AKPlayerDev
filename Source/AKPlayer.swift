//
//  AKPlayer.swift
//  AKPlayer
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

import AVFoundation

open class AKPlayer: NSObject, AKPlayerProtocol, AKPlayerCommandProtocol {
    
    // MARK: - Properties
    
    open var currentMedia: AKPlayable? {
        return manager.currentMedia
    }
    
    open var currentItem: AVPlayerItem? {
        return manager.currentItem
    }
    
    open var currentTime: CMTime {
        return manager.currentTime
    }
    
    open var duration: CMTime? {
        return manager.duration
    }
    
    open var state: AKPlayerState {
        return manager.state
    }
    
    open var rate: AKPlaybackRate {
        get { return manager.rate }
        set { manager.rate = newValue }
    }
    
    open var volume: Float {
        get { return manager.volume }
        set { manager.volume = newValue }
    }
    
    open var isMuted: Bool {
        get { return manager.isMuted }
        set { manager.isMuted = newValue }
    }
    
    open var isPlaying: Bool {
        get { return manager.isPlaying }
    }
    
    open var isSeeking: Bool {
        get { return manager.isSeeking }
    }
    
    open var error: Error? {
        return manager.error
    }
    
    open var remoteCommands: [AKRemoteCommand] {
        get { return manager.remoteCommands }
        set { manager.remoteCommands = newValue }
    }
    
    public let player: AVPlayer
    
    private var manager: AKPlayerManager
    
    open weak var delegate: AKPlayerDelegate?
    
    // MARK: - Init
    
    public init(player: AVPlayer = AVPlayer(),
                plugins: [AKPlayerPlugin] = [],
                configuration: AKPlayerConfiguration = AKPlayerDefaultConfiguration(),
                audioSessionService: AKAudioSessionServiceable = AKAudioSessionService(),
                remoteCommandController: AKRemoteCommandController = AKRemoteCommandController()) {
        self.player = player
        manager = AKPlayerManager(player: player,
                                  plugins: plugins,
                                  configuration: configuration,
                                  audioSessionService: audioSessionService,
                                  remoteCommandController: remoteCommandController)
        super.init()
        manager.delegate = self
    }
    
    deinit {
        print("AKPlayer: Deinit called from the AKPLayer ✌🏼")
    }
    
    open func prepare() {
        manager.prepare()
    }
    
    // MARK: - Commands
    
    open func load(media: AKPlayable) {
        manager.load(media: media)
    }
    
    open func load(media: AKPlayable,
                   autoPlay: Bool) {
        manager.load(media: media,
                     autoPlay: autoPlay)
    }
    
    open func load(media: AKPlayable,
                   autoPlay: Bool,
                   at position: CMTime) {
        manager.load(media: media,
                     autoPlay: autoPlay,
                     at: position)
    }
    
    open func load(media: AKPlayable,
                   autoPlay: Bool,
                   at position: Double) {
        manager.load(media: media,
                     autoPlay: autoPlay,
                     at: position)
    }
    
    open func play() {
        manager.play()
    }
    
    open func pause() {
        manager.pause()
    }
    
    open func togglePlayPause() {
        manager.togglePlayPause()
    }
    
    open func stop() {
        manager.stop()
    }
    
    open func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: @escaping (Bool) -> Void) {
        manager.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
    }
    
    open func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
        manager.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
    }
    
    open func seek(to time: CMTime,
                   completionHandler: @escaping (Bool) -> Void) {
        manager.seek(to: time,
                     completionHandler: completionHandler)
    }
    
    open func seek(to time: CMTime) {
        manager.seek(to: time)
    }
    
    open func seek(to time: Double,
                   completionHandler: @escaping (Bool) -> Void) {
        manager.seek(to: time,
                     completionHandler: completionHandler)
    }
    
    open func seek(to time: Double) {
        manager.seek(to: time)
    }
    
    open func seek(to date: Date, completionHandler: @escaping (Bool) -> Void) {
        manager.seek(to: date, completionHandler: completionHandler)
    }
    
    open func seek(to date: Date) {
        manager.seek(to: date)
    }
    
    open func seek(offset: Double) {
        manager.seek(offset: offset)
    }
    
    open func seek(offset: Double,
                   completionHandler: @escaping (Bool) -> Void) {
        manager.seek(offset: offset,
                     completionHandler: completionHandler)
    }
    
    open func seek(toPercentage value: Double,
                   completionHandler: @escaping (Bool) -> Void) {
        manager.seek(toPercentage: value,
                     completionHandler: completionHandler)
    }
    
    open func seek(toPercentage value: Double) {
        manager.seek(toPercentage: value)
    }
    
    open func step(byCount stepCount: Int) {
        manager.step(byCount: stepCount)
    }
    
    open func setNowPlayingMetadata() {
        manager.setNowPlayingMetadata()
    }
    
    open func setNowPlayingPlaybackInfo() {
        manager.setNowPlayingPlaybackInfo()
    }
}

// MARK: - AKPlayerManageableDelegate

extension AKPlayer: AKPlayerManagerDelegate {
    
    public func playerManager(didStateChange state: AKPlayerState) {
        delegate?.akPlayer(self, didChangeState: state)
    }
    
    public func playerManager(didCurrentMediaChange media: AKPlayable) {
        delegate?.akPlayer(self, didChangeCurrentMedia: media)
    }
    
    public func playerManager(didPlaybackRateChange playbackRate: AKPlaybackRate) {
        delegate?.akPlayer(self, didChangePlaybackRate: playbackRate)
    }
    
    public func playerManager(didCurrentTimeChange currentTime: CMTime) {
        delegate?.akPlayer(self, didChangeCurrentTime: currentTime)
    }
    
    public func playerManager(didItemDurationChange itemDuration: CMTime) {
        delegate?.akPlayer(self, didChangeItemDuration: itemDuration)
    }
    
    public func playerManager(didItemPlayToEndTime endTime: CMTime) {
        delegate?.akPlayer(self, didItemPlayToEndTime: endTime)
    }
    
    public func playerManager(didVolumeChange volume: Float, isMuted: Bool) {
        delegate?.akPlayer(self, didChangeVolume: volume, isMuted: isMuted)
    }
    
    public func playerManager(unavailableAction reason: AKPlayerUnavailableActionReason) {
        delegate?.akPlayer(self, unavailableAction: reason)
    }
    
    public func playerManager(didFailedWith error: AKPlayerError) {
        delegate?.akPlayer(self, didFailedWith: error)
    }
}
