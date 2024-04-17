//
//  AKBufferingState.swift
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
import Combine

public class AKBufferingState: AKPlayerStateControllerProtocol  {
    
    // MARK: - Properties
    
    unowned public let playerController: AKPlayerControllerProtocol
    
    public let state: AKPlayerState = .buffering
    
    private var rate: AKPlaybackRate?
    
    public private(set) var autoPlay: Bool
    
    private var stateToNavigateAfterBuffering: AKPlayerState
    
    private var timer: Timer?
    
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    private var playerItemBufferingStatusObserver: AKPlayerItemBufferingStatusObserverProtocol!
    
    private var playerItemNotificationsObserver: AKPlayerItemNotificationsObserverProtocol!
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol,
                autoPlay: Bool = false,
                rate: AKPlaybackRate? = nil,
                stateToNavigateAfterBuffering: AKPlayerState? = nil) {
        self.stateToNavigateAfterBuffering = stateToNavigateAfterBuffering ?? playerController.state
        self.playerController = playerController
        self.autoPlay = autoPlay
        self.rate = rate
        
        playerItemBufferingStatusObserver = AKPlayerItemBufferingStatusObserver(with: playerController.currentMedia!.playerItem!)
        playerItemNotificationsObserver = AKPlayerItemNotificationsObserver(playerItem: playerController.currentMedia!.playerItem!)
    }
    
    deinit {
        cancellables.forEach({$0.cancel()})
    }
    
    public func didChangeState() {
        if playerController.player.timeControlStatus == .playing
            || playerController.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            playerController.player.pause()
        }
        
        startPlayerItemBufferingStatusObserver()
        startPlayerItemNotificationsObserver()
        startBufferTimeoutWatcher()
        observeNetworkChanges()
    }
    
    // MARK: - Commands
    
    public func load(media: AKPlayable) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media)
        change(controller)
    }
    
    public func load(media: AKPlayable,
                     autoPlay: Bool) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay)
        change(controller)
    }
    
    public func load(media: AKPlayable,
                     autoPlay: Bool,
                     at position: CMTime) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: position)
        change(controller)
    }
    
    public func load(media: AKPlayable,
                     autoPlay: Bool,
                     at position: Double) {
        let time = CMTime(seconds: position,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: time)
        change(controller)
    }
    
    public func play() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .alreadyTryingToPlay)
    }
    
    public func play(at rate: AKPlaybackRate) {
        self.rate = rate
    }
    
    public func pause() {
        stateToNavigateAfterBuffering = stateToNavigateAfterBuffering == .stopped ? .stopped : .paused
    }
    
    public func togglePlayPause() {
        pause()
    }
    
    public func stop() {
        let controller = AKStoppedState(playerController: playerController,
                                        seekToZero: true)
        change(controller)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.playerSeekingThroughMediaService.seek(to: time,
                                                               toleranceBefore: toleranceBefore,
                                                               toleranceAfter: toleranceAfter,
                                                               completionHandler: completionHandler)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime) {
        playerController.playerSeekingThroughMediaService.seek(to: time,
                                                               toleranceBefore: toleranceBefore,
                                                               toleranceAfter: toleranceAfter)
    }
    
    public func seek(to time: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.playerSeekingThroughMediaService.seek(to: time,
                                                               completionHandler: completionHandler)
    }
    
    public func seek(to time: CMTime) {
        playerController.playerSeekingThroughMediaService.seek(to: time)
    }
    
    public func seek(to time: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        let time = CMTime(seconds: time,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        playerController.playerSeekingThroughMediaService.seek(to: time,
                                                               completionHandler: completionHandler)
    }
    
    public func seek(to time: Double) {
        let time = CMTime(seconds: time,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        playerController.playerSeekingThroughMediaService.seek(to: time)
    }
    
    public func seek(to date: Date,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.playerSeekingThroughMediaService.seek(to: date,
                                                               completionHandler: completionHandler)
    }
    
    public func seek(to date: Date) {
        playerController.playerSeekingThroughMediaService.seek(to: date)
    }
    
    public func seek(toOffset offset: Double) {
        let time = playerController.currentTime.seconds + offset
        seek(to: time)
    }
    
    public func seek(toOffset offset: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        let time = playerController.currentTime.seconds + offset
        seek(to: time,
             completionHandler: completionHandler)
    }
    
    public func seek(toPercentage percentage: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        let time = (playerController.currentItem?.duration.seconds ?? 0) * (percentage / 100)
        seek(to: time,
             completionHandler: completionHandler)
    }
    
    public func seek(toPercentage percentage: Double) {
        let time = (playerController.currentItem?.duration.seconds ?? 0) * (percentage / 100)
        seek(to: time)
    }
    
    public func step(by count: Int) {
        playerController.currentItem!.step(byCount: count)
    }
    
    public func fastForward() {
        play(at: playerController.configuration.fastForwardRate)
    }
    
    public func fastForward(at rate: AKPlaybackRate) {
        play(at: rate)
    }
    
    public func rewind(){
        play(at: playerController.configuration.rewindRate)
    }
    
    public func rewind(at rate: AKPlaybackRate) {
        play(at: rate)
    }
    
    // MARK: - Additional Helper Functions
    
    private func startPlayerItemNotificationsObserver() {
        playerItemNotificationsObserver.delegate = self
        playerItemNotificationsObserver.startObserving()
    }
    
    private func startPlayerItemBufferingStatusObserver() {
        playerItemBufferingStatusObserver.delegate = self
        playerItemBufferingStatusObserver.startObserving(with: playerController.configuration.bufferObservingTimeout,
                                                         bufferObservingTimeInterval: playerController.configuration.bufferObservingTimeInterval)
    }
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        cancellables.forEach({ $0.cancel() })
        
        timer?.invalidate()
        timer = nil
        
        playerItemBufferingStatusObserver.stopObserving()
        playerController.change(controller)
    }
    
    private func startBufferTimeoutWatcher() {
        var remainingTime: TimeInterval = playerController.configuration.bufferObservingTimeout
        
        timer = Timer.scheduledTimer(withTimeInterval: playerController.configuration.bufferObservingTimeInterval,
                                     repeats: true,
                                     block: { [unowned self] (_) in
            guard timer?.isValid ?? false else { return }
            remainingTime -= playerController.configuration.bufferObservingTimeInterval
            
            if remainingTime <= 0 {
                let controller = AKWaitingForNetworkState(playerController: playerController,
                                                          autoPlay: autoPlay,
                                                          rate: rate,
                                                          stateToNavigateAfterBuffering: stateToNavigateAfterBuffering)
                change(controller)
            } else {
                if autoPlay {
                    startPlayingIfPossible()
                } else {
                    changeToPreviousState()
                }
            }
        })
    }
    
    private func changeToPreviousState() {
        guard !playerController.isSeeking
                && (playerController.currentItem?.isPlaybackBufferFull ?? false
                    || playerController.currentItem?.isPlaybackLikelyToKeepUp ?? false) else { return }
        
        switch stateToNavigateAfterBuffering {
        case .loaded:
            let controller = AKLoadedState(playerController: playerController,
                                           rate: rate)
            return change(controller)
        case .paused:
            let controller = AKPausedState(playerController: playerController)
            return change(controller)
        case .stopped:
            let controller = AKStoppedState(playerController: playerController,
                                            seekToZero: false)
            return change(controller)
        default: break
        }
    }
    
    private func startPlayingIfPossible() {
        guard (playerController.currentItem!.isPlaybackBufferFull
               || playerController.currentItem!.isPlaybackLikelyToKeepUp)
                && !playerController.isSeeking else { return }
        
        let controller = AKPlayingState(playerController: playerController,
                                        rate: rate)
        change(controller)
    }
    
    private func observeNetworkChanges() {
        playerController.networkStatusMonitor.networkStatusPublisher
            .receive(on: RunLoop.main)
            .prepend(playerController.networkStatusMonitor.currentNetworkStatus)
            .sink { [unowned self] status in
                if !(status == .satisfied) {
                    let controller = AKWaitingForNetworkState(playerController: playerController,
                                                              autoPlay: autoPlay,
                                                              rate: rate,
                                                              stateToNavigateAfterBuffering: stateToNavigateAfterBuffering)
                    change(controller)
                }
            }
            .store(in: &cancellables)
    }
    
}

// MARK: - AKPlayerItemBufferingStatusObserverDelegate

extension AKBufferingState: AKPlayerItemBufferingStatusObserverDelegate {
    
    public func playerItemBufferingStatusObserver(_ observer: AKPlayerItemBufferingStatusObserverProtocol,
                                                  didChangePlaybackLikelyToKeepUpStatusTo isPlaybackLikelyToKeepUp: Bool,
                                                  for playerItem: AVPlayerItem) {
        if autoPlay {
            startPlayingIfPossible()
        } else {
            changeToPreviousState()
        }
    }
    
    public func playerItemBufferingStatusObserver(_ observer: AKPlayerItemBufferingStatusObserverProtocol,
                                                  didChangePlaybackBufferFullStatusTo isPlaybackBufferFull: Bool,
                                                  for playerItem: AVPlayerItem) {
        if autoPlay {
            startPlayingIfPossible()
        } else {
            changeToPreviousState()
        }
    }
}

// MARK: - AKPlayerItemNotificationsObserverDelegate

extension AKBufferingState: AKPlayerItemNotificationsObserverDelegate {
    
    public func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                                didFailToPlayToEndTimeWith error: AKPlayerError,
                                                for playerItem: AVPlayerItem) {
        
        guard error.underlyingError is URLError else {
            let controller = AKFailedState(playerController: playerController,
                                           error: .itemFailedToPlayToEndTime)
            return change(controller)
        }
        
        let controller = AKWaitingForNetworkState(playerController: playerController,
                                                  autoPlay: autoPlay,
                                                  rate: rate,
                                                  stateToNavigateAfterBuffering: stateToNavigateAfterBuffering)
        change(controller)
    }
}
