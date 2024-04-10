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
import Network

final class AKWaitingForNetworkState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned public let playerController: AKPlayerControllerProtocol
    
    public let state: AKPlayerState = .waitingForNetwork
    
    private var rate: AKPlaybackRate?
    
    public var autoPlay: Bool = false
    
    private var stateBeforeBuffering: AKPlayerState?
    
    private var targetSeek: AKSeek?
    
    private var monitor: NWPathMonitor?
    
    private var playerItemNotificationsObserver: AKPlayerItemNotificationsObserverProtocol!
    
    // MARK: - Init
    
    init(playerController: AKPlayerControllerProtocol,
         autoPlay: Bool = false,
         rate: AKPlaybackRate? = nil,
         stateBeforeBuffering: AKPlayerState? = nil) {
        self.stateBeforeBuffering = stateBeforeBuffering ?? playerController.state
        self.playerController = playerController
        self.autoPlay = autoPlay
        self.rate = rate
        
        monitor = NWPathMonitor()
        
        playerItemNotificationsObserver = AKPlayerItemNotificationsObserver(playerItem: playerController.currentItem!)
    }
    
    deinit { }
    
    func didChangeState() {
        startPlayerItemObservingNotificationsService()
        
        monitor?.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.monitor?.cancel()
                let controller = AKBufferingState(playerController: self.playerController,
                                                  autoPlay: self.autoPlay,
                                                  rate: self.rate,
                                                  stateBeforeBuffering: self.stateBeforeBuffering)
                self.change(controller)
            }
        }
        monitor?.start(queue: DispatchQueue.global())
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
        guard monitor!.currentPath.status == .satisfied else {
            autoPlay = true
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .waitingForEstablishedNetwork)
            return
        }
        guard let reasonForWaitingToPlay = playerController.player.reasonForWaitingToPlay else {
            let controller = AKBufferingState(playerController: playerController,
                                              autoPlay: autoPlay,
                                              rate: rate,
                                              stateBeforeBuffering: stateBeforeBuffering)
            change(controller)
            return
        }
        
        switch reasonForWaitingToPlay {
        case .evaluatingBufferingRate, .toMinimizeStalls:
            let controller = AKBufferingState(playerController: playerController,
                                              autoPlay: autoPlay,
                                              rate: rate,
                                              stateBeforeBuffering: stateBeforeBuffering)
            change(controller)
        case .noItemToPlay:
            let controller = AKLoadingState(playerController: playerController,
                                            media: playerController.currentMedia!,
                                            autoPlay: true)
            change(controller)
        default:
            let controller = AKLoadingState(playerController: playerController,
                                            media: playerController.currentMedia!,
                                            autoPlay: true)
            change(controller)
        }
    }
    
    func play(at rate: AKPlaybackRate) {
        guard monitor!.currentPath.status == .satisfied else {
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
        guard let reasonForWaitingToPlay = playerController.player.reasonForWaitingToPlay else {
            let controller = AKBufferingState(playerController: playerController,
                                              autoPlay: autoPlay,
                                              rate: rate,
                                              stateBeforeBuffering: stateBeforeBuffering)
            change(controller)
            return
        }
        
        switch reasonForWaitingToPlay {
        case .evaluatingBufferingRate, .toMinimizeStalls:
            let controller = AKBufferingState(playerController: playerController,
                                              autoPlay: autoPlay,
                                              rate: rate,
                                              stateBeforeBuffering: stateBeforeBuffering)
            change(controller)
        case .noItemToPlay:
            let controller = AKLoadingState(playerController: playerController,
                                            media: playerController.currentMedia!,
                                            autoPlay: true, rate: rate)
            change(controller)
        default:
            assertionFailure("Sould be not here \(reasonForWaitingToPlay.rawValue)")
        }
    }
    
    func pause() {
        let controller = AKPausedState(playerController: playerController)
        change(controller)
    }
    
    func togglePlayPause() {
        pause()
    }
    
    func stop() {
        let controller = AKStoppedState(playerController: playerController,
                                        seekToZero: false)
        change(controller)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        targetSeek = AKSeek(position: .time(time),
                            toleranceBefore: toleranceBefore,
                            toleranceAfter: toleranceAfter,
                            completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime) {
        targetSeek = AKSeek(position: .time(time),
                            toleranceBefore: toleranceBefore,
                            toleranceAfter: toleranceAfter)
    }
    
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        targetSeek = AKSeek(position: .time(time),
                            completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime) {
        targetSeek = AKSeek(position: .time(time))
    }
    
    func seek(to time: Double,
              completionHandler: @escaping (Bool) -> Void) {
        let cmTime = CMTime(seconds: time,
                            preferredTimescale: playerController.configuration.preferredTimeScale)
        targetSeek = AKSeek(position: .time(cmTime),
                            completionHandler: completionHandler)
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time,
                            preferredTimescale: playerController.configuration.preferredTimeScale)
        targetSeek = AKSeek(position: .time(cmTime))
    }
    
    func seek(to date: Date,
              completionHandler: @escaping (Bool) -> Void) {
        targetSeek = AKSeek(position: .date(date),
                            completionHandler: completionHandler)
    }
    
    func seek(to date: Date) {
        targetSeek = AKSeek(position: .date(date))
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
    
    func rewind() {
        play(at: playerController.configuration.rewindRate)
    }
    
    func rewind(at rate: AKPlaybackRate) {
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
}

// MARK: - AKPlayerItemNotificationsObserverDelegate

extension AKWaitingForNetworkState: AKPlayerItemNotificationsObserverDelegate {
    
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didFailToPlayToEndTimeWith error: AKPlayerError,
                                         for playerItem: AVPlayerItem) {
        guard playerController.player.timeControlStatus == .waitingToPlayAtSpecifiedRate,
              let reasonForWaitingToPlay = playerController.player.reasonForWaitingToPlay else {
            let controller = AKFailedState(playerController: playerController,
                                           error: .itemFailedToPlayToEndTime)
            return change(controller)
        }
        if reasonForWaitingToPlay == .noItemToPlay { return stop() }
        print("Already Waiting for network `onPlayerItemFailedToPlayToEndTime`")
    }
    
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didStallPlaybackFor playerItem: AVPlayerItem) {
        print("Already Waiting for network `onPlayerItemPlaybackStalled`")
    }
}
