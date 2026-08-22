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

public class AKBufferingState: AKBaseState  {
    
    // MARK: - Properties
    
    private var rate: AKPlaybackRate?
    public private(set) var autoPlay: Bool
    private var stateToNavigateAfterBuffering: AKPlayerState
    private var timer: Timer?
    private var targetSeek: AKSeek?
    
    private var subscriptions: Set<AnyCancellable> = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol,
                autoPlay: Bool = false,
                rate: AKPlaybackRate? = nil,
                stateToNavigateAfterBuffering: AKPlayerState? = nil) {
        self.stateToNavigateAfterBuffering = stateToNavigateAfterBuffering ?? playerController.state
        self.autoPlay = autoPlay
        self.rate = rate
        super.init(playerController: playerController, state: .buffering)
    }
    
    deinit {
        subscriptions.removeAll()
    }
    
    public override func processStateChange() {
        startObservingPlayerStatus()
        playerController.performPause()
        
        if let targetSeek {
            playerController.performSeek(to: targetSeek)
        }
        
        startObservingPlayerItemBufferingStatus()
        startObservingPlayerItemNotifications()
        startBufferTimeoutWatcher()
        
        if playerController.currentMedia!.isOverNetwork() {
            observeNetworkChanges()
        }
    }
    
    // MARK: - Commands
    
    public override func play() {
        if autoPlay {
            playerController.delegate?.playerController(playerController,
                                                        didEncounterUnavailableAction: .alreadyTryingToPlay)
        } else {
            self.autoPlay = true
        }
    }
    
    public override func play(at rate: AKPlaybackRate) {
        guard playerController.currentMedia!.canPlay(at: rate) else {
            playerController.delegate?.playerController(playerController,
                                                        didEncounterUnavailableAction: .canNotPlayAtSpecifiedRate)
            return
        }
        self.rate = rate
        autoPlay = true
    }
    
    public override func seek(to time: CMTime,
                              toleranceBefore: CMTime,
                              toleranceAfter: CMTime,
                              completionHandler: @escaping (Bool) -> Void) {
        targetSeek = AKSeek(position: .time(time),
                            toleranceBefore: toleranceBefore,
                            toleranceAfter: toleranceAfter,
                            completionHandler: completionHandler)
        playerController.performSeek(to: targetSeek!)
    }
    
    public override func seek(to time: CMTime,
                              toleranceBefore: CMTime,
                              toleranceAfter: CMTime) {
        targetSeek = AKSeek(position: .time(time),
                            toleranceBefore: toleranceBefore,
                            toleranceAfter: toleranceAfter)
        playerController.performSeek(to: targetSeek!)
    }
    
    public override func seek(to time: CMTime,
                              completionHandler: @escaping (Bool) -> Void) {
        targetSeek = AKSeek(position: .time(time),
                            completionHandler: completionHandler)
        playerController.performSeek(to: targetSeek!)
    }
    
    public override func seek(to time: CMTime) {
        targetSeek = AKSeek(position: .time(time))
        playerController.performSeek(to: targetSeek!)
    }
    
    public override func seek(to time: Double,
                              completionHandler: @escaping (Bool) -> Void) {
        let time = CMTime(seconds: time,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        targetSeek = AKSeek(position: .time(time),
                            completionHandler: completionHandler)
        playerController.performSeek(to: targetSeek!)
    }
    
    public override func seek(to time: Double) {
        let time = CMTime(seconds: time,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        targetSeek = AKSeek(position: .time(time))
        playerController.performSeek(to: targetSeek!)
    }
    
    public override func seek(to date: Date,
                              completionHandler: @escaping (Bool) -> Void) {
        targetSeek = AKSeek(position: .date(date),
                            completionHandler: completionHandler)
        playerController.performSeek(to: targetSeek!)
    }
    
    public override func seek(to date: Date) {
        targetSeek = AKSeek(position: .date(date))
        playerController.performSeek(to: targetSeek!)
    }
    
    public override func seek(toOffset offset: Double) {
        let time = CMTimeAdd(playerController.currentTime,
                             CMTimeMakeWithSeconds(offset, preferredTimescale: playerController.configuration.preferredTimeScale))
        seek(to: time)
    }
    
    public override func seek(toOffset offset: Double,
                              completionHandler: @escaping (Bool) -> Void) {
        let time = CMTimeAdd(playerController.currentTime,
                             CMTimeMakeWithSeconds(offset, preferredTimescale: playerController.configuration.preferredTimeScale))
        seek(to: time,
             completionHandler: completionHandler)
    }
    
    public override func seek(toPercentage percentage: Double,
                              completionHandler: @escaping (Bool) -> Void) {
        let time = CMTimeGetSeconds(playerController.currentItem!.duration) * (percentage / 100)
        seek(to: time,
             completionHandler: completionHandler)
    }
    
    public override func seek(toPercentage percentage: Double) {
        let time = CMTimeGetSeconds(playerController.currentItem!.duration) * (percentage / 100)
        seek(to: time)
    }
    
    // MARK: - Additional Helper Functions
    
    private func startObservingPlayerStatus() {
        playerController.player.publisher(for: \.status)
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [unowned self] status in
                guard status == .failed else { return }
                let controller = AKFailedState(playerController: playerController,
                                               error: .playerCanNoLongerPlay(error: playerController.player.error))
                change(controller)
            }.store(in: &subscriptions)
        
        playerController.player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [unowned self] timeControlStatus in
                guard playerController.player.currentItem == nil else { return }
                stop()
            }.store(in: &subscriptions)
    }
    
    private func startObservingPlayerItemNotifications() {
        let playerItem = playerController.currentMedia!.playerItem!
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime,
                                             object: playerItem)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            guard let self,
                  let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError else { return }
            guard error is URLError else {
                let controller = AKFailedState(playerController: playerController,
                                               error: .playerItemFailedToPlay(reason: .failedToPlayToEndTime(error: error)))
                return change(controller)
            }
            
            let controller = AKWaitingForNetworkState(playerController: playerController,
                                                      autoPlay: autoPlay,
                                                      rate: rate,
                                                      stateToNavigateAfterBuffering: stateToNavigateAfterBuffering)
            change(controller)
        }
        .store(in: &subscriptions)
    }
    
    private func startObservingPlayerItemBufferingStatus() {
        let playerItem = playerController.currentMedia!.playerItem!
        Publishers.CombineLatest(playerItem.publisher(for: \.isPlaybackBufferFull,
                                                      options: [.initial, .new]),
                                 playerItem.publisher(for: \.isPlaybackLikelyToKeepUp,
                                                      options: [.initial, .new]))
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] _ in
            if autoPlay {
                startPlayingIfPossible()
            } else {
                changeToPreviousState()
            }
        })
        .store(in: &subscriptions)
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
        guard canPlay() else { return }
        let controller = AKPlayingState(playerController: playerController,
                                        rate: rate)
        change(controller)
    }
    
    private func observeNetworkChanges() {
        playerController.networkStatusMonitor.networkStatusPublisher
            .receive(on: DispatchQueue.main)
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
            .store(in: &subscriptions)
    }
    
    override func beforeStateChange() {
        subscriptions.removeAll()
        
        timer?.invalidate()
        timer = nil
    }
}
