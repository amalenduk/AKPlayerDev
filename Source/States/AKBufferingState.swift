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

final class AKBufferingState: AKPlayerStateControllerProtocol  {
    
    // MARK: - Properties
    
    unowned let playerController: AKPlayerControllerProtocol
    
    let state: AKPlayerState = .buffering
    
    private var rate: AKPlaybackRate?
    
    private var isSeeking: Bool = false
    
    private var previousState: AKPlayerState?
    
    private var playerItemBufferingStatusObserver: AKPlayerItemBufferingStatusObserverProtocol!
    
    private var playerItemNotificationsObserver: AKPlayerItemNotificationsObserverProtocol!
    
    // MARK: - Init
    
    init(playerController: AKPlayerControllerProtocol,
         rate: AKPlaybackRate? = nil) {
        print("Init called from ", #file)
        self.playerController = playerController
        self.rate = rate
        
        playerItemBufferingStatusObserver = AKPlayerItemBufferingStatusObserver(with: playerController.currentItem!)
        playerItemNotificationsObserver = AKPlayerItemNotificationsObserver(playerItem: playerController.currentItem!)
    }
    
    deinit { print("Deinit called from ", #file) }
    
    func didChangeState() {
        if (playerController.player.timeControlStatus == .playing)
            || playerController.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            playerController.player.pause()
        }
        startPlayerItemBufferingStatusObserver()
        startPlayerItemNotificationsObserver()
    }
    
    // MARK: - Commands
    
    func load(media: AKPlayable) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media)
        change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay)
        change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: CMTime) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: position)
        change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: Double) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: CMTime(seconds: position,
                                                         preferredTimescale: playerController.configuration.preferredTimeScale))
        change(controller)
    }
    
    func play() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .alreadyTryingToPlay)
    }
    
    func play(at rate: AKPlaybackRate) {
        self.rate = rate
    }
    
    func pause() {
        let controller = AKPausedState(playerController: playerController)
        change(controller)
    }
    
    func togglePlayPause() {
        pause()
    }
    
    func stop() {
        let controller = AKStoppedState(playerController: playerController)
        change(controller)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        isSeeking = true
        playerController.player.seek(to: time,
                                     toleranceBefore: toleranceBefore,
                                     toleranceAfter: toleranceAfter) { [weak self] finished in
            print("Seek completed ", finished)
            guard let self = self else { return }
            if finished {
                isSeeking = false
            }
            completionHandler(finished)
        }
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime) {
        isSeeking = true
        playerController.player.seek(to: time,
                                     toleranceBefore: toleranceBefore,
                                     toleranceAfter: toleranceAfter) { [weak self] finished in
            guard let self = self else { return }
            if finished {
                isSeeking = false
            }
        }
    }
    
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        isSeeking = true
        playerController.player.seek(to: time) { [weak self] finished in
            guard let self = self else { return }
            if finished {
                isSeeking = false
            }
            completionHandler(finished)
        }
    }
    
    func seek(to time: CMTime) {
        isSeeking = true
        playerController.player.seek(to: time) { [weak self] finished in
            guard let self = self else { return }
            if finished {
                isSeeking = false
            }
        }
    }
    
    func seek(to time: Double,
              completionHandler: @escaping (Bool) -> Void) {
        seek(to: CMTime(seconds: time,
                        preferredTimescale: playerController.configuration.preferredTimeScale),
             completionHandler: completionHandler)
    }
    
    func seek(to time: Double) {
        seek(to: CMTime(seconds: time,
                        preferredTimescale: playerController.configuration.preferredTimeScale))
    }
    
    func seek(to date: Date,
              completionHandler: @escaping (Bool) -> Void) {
        isSeeking = true
        playerController.player.seek(to: date) { [weak self] finished in
            guard let self = self else { return }
            if finished {
                isSeeking = false
            }
            completionHandler(finished)
        }
    }
    
    func seek(to date: Date) {
        isSeeking = true
        playerController.player.seek(to: date) { [weak self] finished in
            guard let self = self else { return }
            if finished {
                isSeeking = false
            }
        }
    }
    
    func seek(toOffset offset: Double) {
        seek(to: playerController.currentTime.seconds + offset)
    }
    
    func seek(toOffset offset: Double,
              completionHandler: @escaping (Bool) -> Void) {
        seek(to: playerController.currentTime.seconds + offset,
             completionHandler: completionHandler)
    }
    
    func seek(toPercentage percentage: Double,
              completionHandler: @escaping (Bool) -> Void) {
        seek(to: (playerController.currentItem?.duration.seconds ?? 0) * (percentage / 100),
             completionHandler: completionHandler)
    }
    
    func seek(toPercentage percentage: Double) {
        seek(to: (playerController.currentItem?.duration.seconds ?? 0) * (percentage / 100))
    }
    
    func step(by count: Int) {
        playerController.currentItem!.step(byCount: count)
    }
    
    func fastForward() {
        play(at: playerController.configuration.fastForwardRate)
    }
    
    func fastForward(at rate: AKPlaybackRate) {
        play(at: rate)
    }
    
    func rewind(){
        play(at: playerController.configuration.rewindRate)
    }
    
    func rewind(at rate: AKPlaybackRate) {
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
        playerItemBufferingStatusObserver.stopObserving()
        playerController.change(controller)
    }
}

// MARK: - AKPlayerItemBufferingStatusObserverDelegate

extension AKBufferingState: AKPlayerItemBufferingStatusObserverDelegate {
    func playerItemBufferingStatusObserver(_ observer: AKPlayerItemBufferingStatusObserverProtocol,
                                           didChangePlaybackLikelyToKeepUpStatusTo isPlaybackLikelyToKeepUp: Bool,
                                           for playerItem: AVPlayerItem) {
        if isPlaybackLikelyToKeepUp {
            let controller = AKPlayingState(playerController: playerController)
            change(controller)
        }
    }
    
    func playerItemBufferingStatusObserver(_ observer: AKPlayerItemBufferingStatusObserverProtocol,
                                           didChangePlaybackBufferFullStatusTo isPlaybackBufferFull: Bool,
                                           for playerItem: AVPlayerItem) {
        if isPlaybackBufferFull {
            let controller = AKPlayingState(playerController: playerController)
            change(controller)
        }
    }
    
    func playerItemBufferingStatusObserver(_ observer: AKPlayerItemBufferingStatusObserverProtocol,
                                           didChangePlaybackBufferEmptyStatusTo isPlaybackBufferEmpty: Bool,
                                           for playerItem: AVPlayerItem) {
        if isPlaybackBufferEmpty {
            let controller = AKWaitingForNetworkState(playerController: playerController)
            change(controller)
        }
    }
    
    func playerItemBufferingStatusObserver(_ observer: AKPlayerItemBufferingStatusObserverProtocol,
                                           didChangeMediaPlaybackContinuationStatusTo shouldContinuePlayback: Bool,
                                           for playerItem: AVPlayerItem) {
        guard shouldContinuePlayback
                && !isSeeking else {
            let controller = AKWaitingForNetworkState(playerController: playerController)
            return change(controller)
        }
        
        switch playerController.player.status {
        case .readyToPlay:
            let controller = AKPlayingState(playerController: playerController,
                                            rate: rate)
            change(controller)
        case .failed:
            let controller = AKFailedState(playerController: playerController,
                                           error: .playerCanNoLongerPlay(error: playerController.player.error))
            return change(controller)
        default: break
        }
    }
}

// MARK: - AKPlayerItemNotificationsObserverDelegate

extension AKBufferingState: AKPlayerItemNotificationsObserverDelegate {
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didPlayToEndTimeAt time: CMTime,
                                         for playerItem: AVPlayerItem) {
        playerController.delegate?.playerController(playerController,
                                                    playerItemDidReachEnd: playerController.currentTime,
                                                    for: playerController.currentMedia!)
        let controller = AKStoppedState(playerController: playerController,
                                        playerItemDidPlayToEndTime: true)
        change(controller)
    }
    
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didFailToPlayToEndTimeWith error: AKPlayerError,
                                         for playerItem: AVPlayerItem) {
        guard playerController.player.timeControlStatus == .waitingToPlayAtSpecifiedRate,
              let reasonForWaitingToPlay = playerController.player.reasonForWaitingToPlay else {
            // TODO: Should navigate to pause state if automaticallyWaitsToMinimizeStalling id NO
            let controller = AKFailedState(playerController: playerController,
                                           error: .itemFailedToPlayToEndTime)
            return change(controller)
        }
        
        switch reasonForWaitingToPlay {
        case .evaluatingBufferingRate, .toMinimizeStalls:
            let controller = AKWaitingForNetworkState(playerController: playerController)
            change(controller)
        case .noItemToPlay: stop()
        default:
            assertionFailure("Sould be not here \(reasonForWaitingToPlay.rawValue)")
        }
    }
    
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didStallPlaybackFor playerItem: AVPlayerItem) {
        let controller = AKWaitingForNetworkState(playerController: playerController)
        change(controller)
    }
}
