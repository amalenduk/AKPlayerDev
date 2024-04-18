//
//  AKWaitingForNetworkState.swift
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

public class AKWaitingForNetworkState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned public let playerController: AKPlayerControllerProtocol
    
    public let state: AKPlayerState = .waitingForNetwork
    
    private var rate: AKPlaybackRate?
    
    public private(set) var autoPlay: Bool = false
    
    private var stateToNavigateAfterBuffering: AKPlayerState?
    
    private var targetSeek: AKSeek?
    
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    private var playerItemNotificationsObserver: AKPlayerItemNotificationsObserverProtocol!
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol,
                autoPlay: Bool = false,
                rate: AKPlaybackRate? = nil,
                stateToNavigateAfterBuffering: AKPlayerState? = nil) {
        self.stateToNavigateAfterBuffering = stateToNavigateAfterBuffering
        self.playerController = playerController
        self.autoPlay = autoPlay
        self.rate = rate
        
        playerItemNotificationsObserver = AKPlayerItemNotificationsObserver(playerItem: playerController.currentMedia!.playerItem!)
    }
    
    deinit { }
    
    public func didChangeState() {
        if playerController.player.timeControlStatus == .playing
            || playerController.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            playerController.player.pause()
        }
        
        startPlayerItemObservingNotificationsService()
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
        guard playerController.networkStatusMonitor.isConnected else {
            autoPlay = true
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .waitingForEstablishedNetwork)
            return
        }
        
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: autoPlay,
                                          rate: rate,
                                          stateToNavigateAfterBuffering: stateToNavigateAfterBuffering)
        change(controller)
    }
    
    public func play(at rate: AKPlaybackRate) {
        guard playerController.networkStatusMonitor.isConnected else {
            autoPlay = true
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .waitingForEstablishedNetwork)
            return
        }
        
        guard playerController.currentMedia!.canPlay(at: rate) else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .canNotPlayAtSpecifiedRate)
            return
        }
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: autoPlay,
                                          rate: rate,
                                          stateToNavigateAfterBuffering: stateToNavigateAfterBuffering)
        change(controller)
    }
    
    public func pause() {
        let controller = AKPausedState(playerController: playerController)
        change(controller)
    }
    
    public func togglePlayPause() {
        if autoPlay {
            pause()
        } else {
            self.autoPlay = true
        }
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
        let time = CMTimeGetSeconds(playerController.currentTime) + offset
        seek(to: time)
    }
    
    public func seek(toOffset offset: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        let time = CMTimeGetSeconds(playerController.currentTime) + offset
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
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitingForEstablishedNetwork)
    }
    
    public func fastForward() {
        play(at: playerController.configuration.fastForwardRate)
    }
    
    public func fastForward(at rate: AKPlaybackRate) {
        play(at: rate)
    }
    
    public func rewind() {
        play(at: playerController.configuration.rewindRate)
    }
    
    public func rewind(at rate: AKPlaybackRate) {
        play(at: rate)
    }
    
    // MARK: - Additional Helper Functions
    
    private func startPlayerItemObservingNotificationsService() {
        playerItemNotificationsObserver.delegate = self
        playerItemNotificationsObserver.startObserving()
    }
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        playerController.change(controller)
        guard let seek = targetSeek,
              let controller = controller as? AKBufferingState else { return }
        if let completionHandler = seek.completionHandler {
            switch seek.position {
            case .time(let cmTime):
                controller.seek(to: cmTime,
                                toleranceBefore: seek.toleranceBefore,
                                toleranceAfter: seek.toleranceAfter,
                                completionHandler: completionHandler)
            case .date(let date):
                controller.seek(to: date,
                                completionHandler: completionHandler)
            }
        } else {
            switch seek.position {
            case .time(let cmTime):
                controller.seek(to: cmTime,
                                toleranceBefore: seek.toleranceBefore,
                                toleranceAfter: seek.toleranceAfter)
            case .date(let date):
                controller.seek(to: date)
            }
        }
    }
    
    private func observeNetworkChanges() {
        playerController.networkStatusMonitor.networkStatusPublisher
            .receive(on: RunLoop.main)
            .prepend(playerController.networkStatusMonitor.currentNetworkStatus)
            .sink { [unowned self] status in
                if status == .satisfied {
                    let controller = AKBufferingState(playerController: playerController,
                                                      autoPlay: true,
                                                      rate: rate,
                                                      stateToNavigateAfterBuffering: stateToNavigateAfterBuffering)
                    change(controller)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - AKPlayerItemNotificationsObserverDelegate

extension AKWaitingForNetworkState: AKPlayerItemNotificationsObserverDelegate {
    
    public func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                                didFailToPlayToEndTimeWith error: AKPlayerError,
                                                for playerItem: AVPlayerItem) {
        
        guard error.underlyingError is URLError else {
            let controller = AKFailedState(playerController: playerController,
                                           error: .itemFailedToPlayToEndTime)
            return change(controller)
        }
        
        /*
         If playback failed for internet issue will wait till internet gets activated
         */
    }
}
