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

open class AKPlayer: NSObject, AKPlayerProtocol, AKPlayerCommand {
    
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
    open weak var playbackDelegate: AKPlaybackDelegate?
    
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
    
    open func playerManager(didStateChange state: AKPlayerState) {
        delegate?.akPlayer(self, didStateChange: state)
    }
    
    open func playerManager(didPlaybackRateChange playbackRate: AKPlaybackRate) {
        delegate?.akPlayer(self, didPlaybackRateChange: playbackRate)
    }
    
    open func playerManager(didCurrentMediaChange media: AKPlayable) {
        delegate?.akPlayer(self, didCurrentMediaChange: media)
    }
    
    open func playerManager(didCurrentTimeChange currentTime: CMTime) {
        delegate?.akPlayer(self, didCurrentTimeChange: currentTime)
    }
    
    open func playerManager(didItemDurationChange itemDuration: CMTime) {
        delegate?.akPlayer(self, didItemDurationChange: itemDuration)
    }
    
    open func playerManager(didItemPlayToEndTime endTime: CMTime) {
        delegate?.akPlayer(self, didItemPlayToEndTime: endTime)
    }
    
    open func playerManager(didVolumeChange volume: Float, isMuted: Bool) {
        delegate?.akPlayer(self, didVolumeChange: volume, isMuted: isMuted)
    }
    
    open func playerManager(unavailableAction reason: AKPlayerUnavailableActionReason) {
        delegate?.akPlayer(self, unavailableAction: reason)
    }
    
    open func playerManager(didFailedWith error: AKPlayerError) {
        delegate?.akPlayer(self, didFailedWith: error)
    }
    
    open func playerManager(didCanPlayReverseStatusChange canPlayReverse: Bool, for media: AKPlayable) {
        playbackDelegate?.akPlayback(didCanPlayReverseStatusChange: canPlayReverse, for: media)
    }
    
    open func playerManager(didCanPlayFastForwardStatusChange canPlayFastForward: Bool, for media: AKPlayable) {
        playbackDelegate?.akPlayback(didCanPlayFastForwardStatusChange: canPlayFastForward, for: media)
    }
    
    open func playerManager(didCanPlayFastReverseStatusChange canPlayFastReverse: Bool, for media: AKPlayable) {
        playbackDelegate?.akPlayback(didCanPlayFastReverseStatusChange: canPlayFastReverse, for: media)
    }
    
    open func playerManager(didCanPlaySlowForwardStatusChange canPlaySlowForward: Bool, for media: AKPlayable) {
        playbackDelegate?.akPlayback(didCanPlaySlowForwardStatusChange: canPlaySlowForward, for: media)
    }
    
    open func playerManager(didCanPlaySlowReverseStatusChange canPlaySlowReverse: Bool, for media: AKPlayable) {
        playbackDelegate?.akPlayback(didCanPlaySlowReverseStatusChange: canPlaySlowReverse, for: media)
    }
    
    open func playerManager(didCanStepForwardStatusChange canStepForward: Bool, for media: AKPlayable) {
        playbackDelegate?.akPlayback(didCanStepForwardStatusChange: canStepForward, for: media)
    }
    
    open func playerManager(didCanStepBackwardStatusChange canStepBackward: Bool, for media: AKPlayable) {
        playbackDelegate?.akPlayback(didCanStepBackwardStatusChange: canStepBackward, for: media)
    }
    
    open func playerManager(didLoadedTimeRangesChange loadedTimeRanges: [NSValue], for media: AKPlayable) {
        playbackDelegate?.akPlayback(didLoadedTimeRangesChange: loadedTimeRanges, for: media)
    }
    
    open func playerManager(didSeekableTimeRangesChange loadedTimeRanges: [NSValue], for media: AKPlayable) {
        playbackDelegate?.akPlayback(didSeekableTimeRangesChange: loadedTimeRanges, for: media)
    }
    
    open func playerManager(didChangedTracks tracks: [AVPlayerItemTrack], for media: AKPlayable) {
        playbackDelegate?.akPlayback(didChangedTracks: tracks, for: media)
    }
}
