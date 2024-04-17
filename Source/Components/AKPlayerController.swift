//
//  AKPlayerController.swift
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

import Foundation
import AVFoundation
import Combine

open class AKPlayerController: AKPlayerControllerProtocol {
    
    // MARK: - Properties
    
    open private(set) var player: AVPlayer
    
    open var state: AKPlayerState { return controller.state }
    
    open var defaultRate: AKPlaybackRate {
        get { return AKPlaybackRate(rate: player.defaultRate) }
        set { player.defaultRate = newValue.rate }
    }
    
    open var rate: AKPlaybackRate {
        get { return AKPlaybackRate(rate: player.rate) }
        set {
            if newValue.rate == 0 { pause() }
            else { play(at: newValue) }
        }
    }
    
    open private(set) var currentMedia: AKPlayable?
    
    open var currentItem: AVPlayerItem? { return player.currentItem }
    
    open var currentItemDuration: CMTime { return currentItem?.duration ?? .indefinite }
    
    open var currentTime: CMTime { player.currentTime() }
    
    open var remainingTime: CMTime? {
        guard currentItemDuration.isValid else { return nil }
        return CMTimeSubtract(currentItemDuration, currentTime)
    }
    
    open var autoPlay: Bool {
        return (controller as? AKLoadedState)?.autoPlay ?? false
        || (controller as? AKLoadingState)?.autoPlay ?? false
        || (controller as? AKBufferingState)?.autoPlay ?? false
        || (controller as? AKWaitingForNetworkState)?.autoPlay ?? false
    }
    
    open var isSeeking: Bool {
        return playerSeekingThroughMediaService.isSeeking
    }
    
    open var seekPosition: AKSeekPosition? {
        return playerSeekingThroughMediaService.seekPosition
    }
    
    open var volume: Float {
        get { return player.volume }
        set { player.volume = newValue }
    }
    
    open var isMuted: Bool {
        get { return player.isMuted }
        set { player.isMuted = newValue }
    }
    
    open var error: AKPlayerError? { return (controller as? AKFailedState)?.error }
    
    public private(set) var configuration: AKPlayerConfigurationProtocol
    
    open private(set) var controller: AKPlayerStateControllerProtocol {
        get { return _controller }
        set {
            let oldState: AKPlayerState = _controller?.state ?? .idle
            beforeStateChange(with: newValue.state)
            _controller = newValue
            controller.didChangeState()
            afterStateChange(with: oldState)
            delegate?.playerController(self, didChangeStateTo: controller.state)
        }
    }
    
    private var _controller: AKPlayerStateControllerProtocol!
    
    open weak var delegate: AKPlayerControllerDelegate?
    
    public var playerSeekingThroughMediaService: AKPlayerSeekingThroughMediaServiceProtocol
    
    public var networkStatusMonitor: AKNetworkStatusMonitorProtocol
    
    private var playerPlaybackTimeObserver: AKPlayerPlaybackTimeObserverProtocol
    
    private var playerWaitingBehaviorObserver: AKPlayerWaitingBehaviorObserverProtocol
    
    private var playerRateObserver: AKPlayerRateObserverProtocol
    
    private var playerAudioBehaviorObserver: AKPlayerAudioBehaviorObserverProtocol
    
    private var playerReadinessObserver: AKPlayerReadinessObserverProtocol
    
    private var cancellables : Set<AnyCancellable> = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(player: AVPlayer,
                configuration: AKPlayerConfigurationProtocol) {
        self.player = player
        self.configuration = configuration
        
        playerRateObserver = AKPlayerRateObserver(with: player)
        playerReadinessObserver = AKPlayerReadinessObserver(with: player)
        playerPlaybackTimeObserver = AKPlayerPlaybackTimeObserver(with: player)
        playerWaitingBehaviorObserver = AKPlayerWaitingBehaviorObserver(with: player)
        playerAudioBehaviorObserver = AKPlayerAudioBehaviorObserver(with: player)
        playerSeekingThroughMediaService = AKPlayerSeekingThroughMediaService(with: player)
        networkStatusMonitor = AKNetworkStatusMonitor()
        
        playerRateObserver.delegate = self
        playerReadinessObserver.delegate = self
        playerPlaybackTimeObserver.delegate = self
        playerWaitingBehaviorObserver.delegate = self
        playerAudioBehaviorObserver.delegate = self
    }
    
    deinit {
        print("AKPlayerController: Deinit called from the AKPlayerController ✌🏼")
        stopPlayerObservers()
    }
    
    // MARK: - Commands
    
    open func load(media: AKPlayable) {
        if !state.isIdle
            && !state.isStopped
            && !state.isFailed {
            stop()
        }
        currentMedia = media
        
        controller.load(media: media)
    }
    
    open func load(media: AKPlayable,
                   autoPlay: Bool) {
        if !state.isIdle
            && !state.isStopped
            && !state.isFailed {
            stop()
        }
        currentMedia = media
        
        controller.load(media: media,
                        autoPlay: autoPlay)
    }
    
    open func load(media: AKPlayable,
                   autoPlay: Bool,
                   at position: CMTime) {
        if !state.isIdle
            && !state.isStopped
            && !state.isFailed {
            stop()
        }
        currentMedia = media
        
        controller.load(media: media,
                        autoPlay: autoPlay,
                        at: position)
    }
    
    open func load(media: AKPlayable,
                   autoPlay: Bool,
                   at position: Double) {
        if !state.isIdle
            && !state.isStopped
            && !state.isFailed {
            stop()
        }
        currentMedia = media
        
        controller.load(media: media,
                        autoPlay: autoPlay,
                        at: position)
    }
    
    open func play() {
        controller.play()
    }
    
    open func play(at rate: AKPlaybackRate) {
        controller.play(at: rate)
    }
    
    open func pause() {
        controller.pause()
    }
    
    open func togglePlayPause() {
        controller.togglePlayPause()
    }
    
    open func stop() {
        controller.stop()
    }
    
    open func seek(to time: CMTime,
                   toleranceBefore: CMTime,
                   toleranceAfter: CMTime,
                   completionHandler: @escaping (Bool) -> Void) {
        let result = canSeek(to: time)
        
        if result.flag {
            controller.seek(to: time,
                            toleranceBefore: toleranceBefore,
                            toleranceAfter: toleranceAfter,
                            completionHandler: completionHandler)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func seek(to time: CMTime,
                   toleranceBefore: CMTime,
                   toleranceAfter: CMTime) {
        let result = canSeek(to: time)
        
        if result.flag {
            controller.seek(to: time,
                            toleranceBefore: toleranceBefore,
                            toleranceAfter: toleranceAfter)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func seek(to time: CMTime,
                   completionHandler: @escaping (Bool) -> Void) {
        let result = canSeek(to: time)
        
        if result.flag {
            controller.seek(to: time,
                            completionHandler: completionHandler)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func seek(to time: CMTime) {
        let result = canSeek(to: time)
        
        if result.flag {
            controller.seek(to: time)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func seek(to time: Double,
                   completionHandler: @escaping (Bool) -> Void) {
        let result = canSeek(to: CMTime(seconds: time,
                                        preferredTimescale: configuration.preferredTimeScale))
        
        if result.flag {
            controller.seek(to: time,
                            completionHandler: completionHandler)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func seek(to time: Double) {
        let result = canSeek(to: CMTime(seconds: time,
                                        preferredTimescale: configuration.preferredTimeScale))
        
        if result.flag {
            controller.seek(to: time)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func seek(to date: Date, completionHandler: @escaping (Bool) -> Void) {
        controller.seek(to: date,
                        completionHandler: completionHandler)
    }
    
    open func seek(to date: Date) {
        controller.seek(to: date)
    }
    
    open func seek(toOffset offset: Double) {
        let result = canSeek(toOffset: offset)
        
        if result.flag {
            controller.seek(toOffset: offset)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func seek(toOffset offset: Double,
                   completionHandler: @escaping (Bool) -> Void) {
        let result = canSeek(toOffset: offset)
        
        if result.flag {
            controller.seek(toOffset: offset,
                            completionHandler: completionHandler)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func seek(toPercentage percentage: Double,
                   completionHandler: @escaping (Bool) -> Void) {
        let result = canSeek(toPercentage: percentage)
        
        if result.flag {
            controller.seek(toPercentage: percentage,
                            completionHandler: completionHandler)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func seek(toPercentage percentage: Double) {
        let result = canSeek(toPercentage: percentage)
        
        if result.flag {
            controller.seek(toPercentage: percentage)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func step(by count: Int) {
        let result = canStep(by: count)
        
        if result.flag {
            controller.step(by: count)
        } else {
            unaivalableCommand(reason: result.reason!)
        }
    }
    
    open func fastForward() {
        controller.fastForward()
    }
    
    open func fastForward(at rate: AKPlaybackRate) {
        controller.fastForward(at: rate)
    }
    
    open func rewind() {
        controller.rewind()
    }
    
    open func rewind(at rate: AKPlaybackRate) {
        controller.rewind(at: rate)
    }
    
    // MARK: - Additional Helper Functions
    
    open func prepare() throws {
        controller = AKIdleState(playerController: self)
        networkStatusMonitor.startObserving()
        startPlayerObservers()
    }
    
    open func change(_ controller: AKPlayerStateControllerProtocol) {
        self.controller = controller
    }
    
    open func beforeStateChange(with newState: AKPlayerState) {
        guard !newState.isIdle else { return }
        switch newState {
        case .idle:
            break
        case .loading:
            break
        case .loaded:
            break
        case .buffering:
            break
        case .paused:
            break
        case .playing:
            break
        case .stopped:
            break
        case .waitingForNetwork:
            break
        case .failed:
            break
        }
    }
    
    open func afterStateChange(with oldState: AKPlayerState) {
        switch state {
        case .idle:
            break
        case .loading:
            break
        case .loaded:
            break
        case .buffering:
            break
        case .paused:
            break
        case .playing:
            break
        case .stopped:
            break
        case .waitingForNetwork:
            break
        case .failed:
            break
        }
    }
    
    private func startPlayerObservers() {
        playerRateObserver.startObserving()
        playerReadinessObserver.startObserving()
        playerPlaybackTimeObserver.startObservingPeriodicTime(for: configuration.getPeriodicTimeInterval())
        playerWaitingBehaviorObserver.startObserving()
        playerAudioBehaviorObserver.startObserving()
    }
    
    private func stopPlayerObservers() {
        playerRateObserver.stopObserving()
        playerReadinessObserver.stopObserving()
        playerPlaybackTimeObserver.stopObservingPeriodicTime()
        playerWaitingBehaviorObserver.stopObserving()
        playerAudioBehaviorObserver.stopObserving()
        networkStatusMonitor.stopObserving()
    }
    
    private func unaivalableCommand(reason: AKPlayerUnavailableCommandReason) {
        delegate?.playerController(self, unavailableActionWith: reason)
    }
    
    private func canSeek(to time: CMTime) -> (flag: Bool, reason: AKPlayerUnavailableCommandReason?) {
        
        guard let currentMedia = currentMedia,
              currentMedia.state.isReadyToPlay,
              state.isLoaded
                || state.isBuffering
                || state.isPlaying
                || state.isWaitingForNetwork
                || state.isPaused
                || (state.isStopped && player.currentItem != nil) else {
            if currentMedia?.state.isIdle ?? false
                || currentMedia?.state.isFailed ?? false
                || state.isIdle
                || state.isFailed {
                return (false, .loadMediaFirst)
            } else if currentMedia?.state.isAssetLoaded ?? false
                        || currentMedia?.state.isPlayerItemLoaded ?? false
                        || state.isLoading {
                return (false, .waitTillMediaLoaded)
            }
            return (false, .actionNotPermitted)
        }
        
        let result = currentMedia.canSeek(to: time)
        
        return result
    }
    
    private func canSeek(toOffset offset: Double) -> (flag: Bool, reason: AKPlayerUnavailableCommandReason?) {
        
        let time = CMTime(seconds: currentItem!.duration.seconds,
                          preferredTimescale: configuration.preferredTimeScale)
        
        let result = canSeek(to: time)
        
        return result
    }
    
    private func canSeek(toPercentage percentage: Double) -> (flag: Bool, reason: AKPlayerUnavailableCommandReason?) {
        
        let time = CMTime(seconds: (currentItem!.duration.seconds * (percentage / 100)),
                          preferredTimescale: configuration.preferredTimeScale)
        
        let result = currentMedia!.canSeek(to: time)
        
        return result
    }
    
    private func canStep(by count: Int) -> (flag: Bool, reason: AKPlayerUnavailableCommandReason?) {
        
        guard let currentMedia = currentMedia,
              currentMedia.state.isReadyToPlay,
              state.isLoaded
                || state.isBuffering
                || state.isPlaying
                || state.isWaitingForNetwork
                || state.isPaused
                || state.isStopped else {
            if currentMedia?.state.isIdle ?? false
                || currentMedia?.state.isFailed ?? false
                || state.isIdle
                || state.isFailed {
                return (false, .loadMediaFirst)
            } else if currentMedia?.state.isAssetLoaded ?? false
                        || currentMedia?.state.isPlayerItemLoaded ?? false
                        || state.isLoading {
                return (false, .waitTillMediaLoaded)
            }
            return (false, .actionNotPermitted)
        }
        
        let result = currentMedia.canStep(by: count)
        
        return (flag: result, reason: result ? nil : count.signum() == 1 ? .canNotStepForward : .canNotStepBackward)
    }
    
    private func canPlay(at rate: AKPlaybackRate) -> (flag: Bool, reason: AKPlayerUnavailableCommandReason?) {
        
        guard let currentMedia = currentMedia,
              currentMedia.state.isReadyToPlay,
              state.isLoaded
                || state.isBuffering
                || state.isPlaying
                || state.isWaitingForNetwork
                || state.isPaused
                || state.isStopped else {
            if currentMedia?.state.isIdle ?? false
                || currentMedia?.state.isFailed ?? false
                || state.isIdle
                || state.isFailed {
                return (false, .loadMediaFirst)
            } else if currentMedia?.state.isAssetLoaded ?? false
                        || currentMedia?.state.isPlayerItemLoaded ?? false
                        || state.isLoading {
                return (false, .waitTillMediaLoaded)
            }
            return (false, .actionNotPermitted)
        }
        
        let result = currentMedia.canPlay(at: rate)
        
        return (flag: result, reason: result ? nil : .canNotPlayAtSpecifiedRate)
    }
}

// MARK: - AKPlayerPlaybackTimeObserverDelegate

extension AKPlayerController: AKPlayerPlaybackTimeObserverDelegate {
    
    public func playerPlaybackTimeObserver(_ observer: AKPlayerPlaybackTimeObserverProtocol,
                                           didInvokePeriodicTimeObserverAt time: CMTime,
                                           for player: AVPlayer) {
        delegate?.playerController(self,
                                   didChangeCurrentTimeTo: time,
                                   for: currentMedia!)
    }
    
    public func playerPlaybackTimeObserver(_ observer: AKPlayerPlaybackTimeObserverProtocol,
                                           didInvokeBoundaryTimeObserverAt time: CMTime,
                                           for player: AVPlayer) {
        delegate?.playerController(self,
                                   didInvokeBoundaryTimeObserverAt: time,
                                   for: currentMedia!)
    }
}

// MARK: - AKPlayerWaitingBehaviorObserverDelegate

extension AKPlayerController: AKPlayerWaitingBehaviorObserverDelegate {
    
    public func playerWaitingBehaviorObserver(_ observer: AKPlayerWaitingBehaviorObserverProtocol,
                                              didChangeTimeControlStatusTo status: AVPlayer.TimeControlStatus,
                                              for player: AVPlayer) {
        
        switch status {
        case .paused:
            if state.isPlaying {
                pause()
            } else if state.isBuffering && player.currentItem == nil {
                stop()
            } else if state.isPaused && player.currentItem == nil {
                stop()
            } else if state.isWaitingForNetwork && player.currentItem == nil {
                stop()
            } else if state.isLoaded && player.currentItem == nil {
                stop()
            }
        case .waitingToPlayAtSpecifiedRate:
            if state.isBuffering {
                guard let reasonForWaitingToPlay = player.reasonForWaitingToPlay,
                      reasonForWaitingToPlay == .noItemToPlay else { return }
                stop()
            } else if state.isPlaying {
                guard let reasonForWaitingToPlay = player.reasonForWaitingToPlay else { return }
                switch reasonForWaitingToPlay {
                case .noItemToPlay: stop()
                case .evaluatingBufferingRate: print("evaluatingBufferingRate")
                case .interstitialEvent: print("interstitialEvent")
                case .toMinimizeStalls: print("toMinimizeStalls")
                case .waitingForCoordinatedPlayback: print("waitingForCoordinatedPlayback")
                default:
                    // TODO: - What to do
                    break
                }
            }
        case .playing:
            if state == .paused {
                guard status == .playing else {
                    if player.currentItem == nil { stop() }
                    return
                }
                play()
            } else if state == .waitingForNetwork {
                play()
            }
        @unknown default:
            assertionFailure()
        }
    }
}

// MARK: - AKPlayerRateObserverDelegate

extension AKPlayerController: AKPlayerRateObserverDelegate {
    
    public func playerRateObserver(_ observer: AKPlayerRateObserverProtocol,
                                   didChangePlaybackRateTo newRate: AKPlaybackRate,
                                   from oldRate: AKPlaybackRate,
                                   for player: AVPlayer,
                                   with reason: AVPlayer.RateDidChangeReason) {
        delegate?.playerController(self,
                                   didChangePlaybackRateTo: newRate,
                                   from: oldRate)
    }
}

// MARK: - AKPlayerAudioBehaviorObserverDelegate

extension AKPlayerController: AKPlayerAudioBehaviorObserverDelegate {
    
    public func audioBehaviorObserver(_ observer: AKPlayerAudioBehaviorObserverProtocol,
                                      didChangeVolumeTo volume: Float,
                                      for player: AVPlayer) {
        delegate?.playerController(self,
                                   didChangeVolumeTo: volume)
    }
    
    public func audioBehaviorObserver(_ observer: AKPlayerAudioBehaviorObserverProtocol,
                                      didChangeMutedStatusTo isMuted: Bool,
                                      for player: AVPlayer) {
        delegate?.playerController(self,
                                   didChangeMutedStatusTo: isMuted)
    }
}

// MARK: - AKPlayerReadinessObserverDelegate

extension AKPlayerController: AKPlayerReadinessObserverDelegate {
    
    public func playerReadinessObserver(_ observer: AKPlayerReadinessObserverProtocol,
                                        didChangeStatusTo status: AVPlayer.Status,
                                        for player: AVPlayer) {
        switch status {
        case .failed:
            stop()
            delegate?.playerController(self,
                                       didFailWith: .playerCanNoLongerPlay(error: player.error))
        default: break
        }
    }
}
