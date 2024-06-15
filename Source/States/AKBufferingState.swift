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
    
    private var targetSeek: AKSeek?
    
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol,
                autoPlay: Bool = false,
                rate: AKPlaybackRate? = nil,
                stateToNavigateAfterBuffering: AKPlayerState? = nil) {
        self.stateToNavigateAfterBuffering = stateToNavigateAfterBuffering ?? playerController.state
        self.playerController = playerController
        self.autoPlay = autoPlay
        self.rate = rate
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    public func didChangeState() {
        startObservingPlayerStatus()
        if let targetSeek {
            playerController.playerSeekingThroughMediaService.seek(to: targetSeek)
        }
        
        if !(playerController.player.timeControlStatus == .paused) {
            playerController.player.pause()
        }
        
        startObservingPlayerItemBufferingStatus()
        startObservingPlayerItemNotifications()
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
        if autoPlay {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .alreadyTryingToPlay)
        } else {
            self.autoPlay = true
        }
    }
    
    public func play(at rate: AKPlaybackRate) {
        guard playerController.currentMedia!.canPlay(at: rate) else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .canNotPlayAtSpecifiedRate)
            return
        }
        self.rate = rate
        autoPlay = true
    }
    
    public func pause() {
        let controller = AKPausedState(playerController: playerController)
        change(controller)
    }
    
    public func togglePlayPause() {
        if autoPlay {
            pause()
        } else {
            play()
        }
    }
    
    public func stop() {
        let controller = AKStoppedState(playerController: playerController)
        change(controller)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        targetSeek = AKSeek(position: .time(time),
                            toleranceBefore: toleranceBefore,
                            toleranceAfter: toleranceAfter,
                            completionHandler: completionHandler)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime) {
        targetSeek = AKSeek(position: .time(time),
                            toleranceBefore: toleranceBefore,
                            toleranceAfter: toleranceAfter)
    }
    
    public func seek(to time: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        targetSeek = AKSeek(position: .time(time),
                            completionHandler: completionHandler)
    }
    
    public func seek(to time: CMTime) {
        targetSeek = AKSeek(position: .time(time))
    }
    
    public func seek(to time: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        let time = CMTime(seconds: time,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        targetSeek = AKSeek(position: .time(time),
                            completionHandler: completionHandler)
    }
    
    public func seek(to time: Double) {
        let time = CMTime(seconds: time,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        targetSeek = AKSeek(position: .time(time))
    }
    
    public func seek(to date: Date,
                     completionHandler: @escaping (Bool) -> Void) {
        targetSeek = AKSeek(position: .date(date),
                            completionHandler: completionHandler)
    }
    
    public func seek(to date: Date) {
        targetSeek = AKSeek(position: .date(date))
    }
    
    public func seek(toOffset offset: Double) {
        let time = CMTimeAdd(playerController.currentTime,
                             CMTimeMakeWithSeconds(offset, preferredTimescale: playerController.configuration.preferredTimeScale))
        seek(to: time)
    }
    
    public func seek(toOffset offset: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        let time = CMTimeAdd(playerController.currentTime,
                             CMTimeMakeWithSeconds(offset, preferredTimescale: playerController.configuration.preferredTimeScale))
        seek(to: time,
             completionHandler: completionHandler)
    }
    
    public func seek(toPercentage percentage: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        let time = CMTimeGetSeconds(playerController.currentItem!.duration) * (percentage / 100)
        seek(to: time,
             completionHandler: completionHandler)
    }
    
    public func seek(toPercentage percentage: Double) {
        let time = CMTimeGetSeconds(playerController.currentItem!.duration) * (percentage / 100)
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
    
    private func startObservingPlayerStatus() {
        playerController.playerStatusPublisher
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [unowned self] status in
                guard status == .failed else { return }
                let controller = AKFailedState(playerController: playerController,
                                               error: .playerCanNoLongerPlay(error: playerController.player.error))
                change(controller)
            }.store(in: &cancellables)
        
        playerController.playerTimeControlStatusPublisher
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [unowned self] timeControlStatus in
                guard timeControlStatus == .paused,
                      playerController.player.currentItem == nil else { return }
                stop()
            }.store(in: &cancellables)
    }
    
    private func startObservingPlayerItemNotifications() {
        playerController.currentMedia!.failedToPlayToEndTimePublisher
            .sink { [weak self] error in
                guard let self else { return }
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
            }.store(in: &cancellables)
    }
    
    private func startObservingPlayerItemBufferingStatus() {
        playerController.currentMedia!.playbackLikelyToKeepUpPublisher
            .prepend(playerController.currentMedia!.isPlaybackLikelyToKeepUp)
            .sink(receiveValue: { [unowned self] isPlaybackLikelyToKeepUp in
                if autoPlay {
                    startPlayingIfPossible()
                } else {
                    changeToPreviousState()
                }
            })
            .store(in: &cancellables)
        
        playerController.currentMedia!.playbackBufferFullPublisher
            .prepend(playerController.currentMedia!.isPlaybackBufferFull)
            .sink(receiveValue: { [unowned self] isPlaybackBufferFull in
                if autoPlay {
                    startPlayingIfPossible()
                } else {
                    changeToPreviousState()
                }
            })
            .store(in: &cancellables)
    }
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        cancellables.forEach({$0.cancel()})
        cancellables.removeAll()
        
        timer?.invalidate()
        timer = nil
        
        playerController.change(controller)
    }
    
    private func startBufferTimeoutWatcher() {
        var remainingTime: TimeInterval = playerController.configuration.bufferObservingTimeout
        
        timer = Timer.scheduledTimer(withTimeInterval: playerController.configuration.bufferObservingTimeInterval,
                                     repeats: true,
                                     block: { [weak self] (_) in
            guard let self,
                  timer?.isValid ?? false else { return }
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
                && (playerController.currentMedia!.isPlaybackBufferFull
                    || playerController.currentMedia!.isPlaybackLikelyToKeepUp) else { return }
        
        switch stateToNavigateAfterBuffering {
        case .loaded:
            let controller = AKLoadedState(playerController: playerController,
                                           rate: rate)
            return change(controller)
        case .paused:
            let controller = AKPausedState(playerController: playerController)
            return change(controller)
        default: break
        }
    }
    
    private func canPlay() -> Bool {
        guard !playerController.isSeeking
                && (playerController.currentMedia!.isPlaybackBufferFull
                    || playerController.currentMedia!.isPlaybackLikelyToKeepUp) else { return false }
        return true
    }
    
    private func startPlayingIfPossible() {
        let controller = AKPlayingState(playerController: playerController,
                                        rate: rate)
        change(controller)
    }
    
    private func observeNetworkChanges() {
        playerController.networkStatusMonitor.networkStatusPublisher
            .receive(on: RunLoop.main)
            .prepend(playerController.networkStatusMonitor.currentNetworkStatus)
            .sink { [weak self] status in
                guard let self else { return }
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
