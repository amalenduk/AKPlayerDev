//
//  AKPlayingState.swift
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

public class AKPlayingState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned public let playerController: AKPlayerControllerProtocol
    
    public let state: AKPlayerState = .playing
    
    private var rate: AKPlaybackRate?
    
    private var playerReadinessObserver: AKPlayerReadinessObserverProtocol!
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol,
                rate: AKPlaybackRate? = nil) {
        self.playerController = playerController
        self.rate = rate
    }
    
    deinit { }
    
    public func didChangeState() {
        startObservingPlayerStatus()
        startObservingPlayerItemNotifications()
        
        if !(playerController.player.timeControlStatus == .playing) {
            playerController.player.play()
        }
        
        guard let rate = rate,
              playerController.player.rate != rate.rate else { return }
        play(at: rate)
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
                                                    unavailableActionWith: .alreadyPlaying)
    }
    
    public func play(at rate: AKPlaybackRate) {
        guard playerController.currentMedia!.canPlay(at: rate) else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .canNotPlayAtSpecifiedRate)
            return
        }
        self.rate = rate
        playerController.player.rate = rate.rate
    }
    
    public func pause() {
        let controller = AKPausedState(playerController: playerController)
        change(controller)
    }
    
    public func togglePlayPause() {
        pause()
    }
    
    public func stop() {
        let controller = AKStoppedState(playerController: playerController)
        change(controller)
    }
    
    public  func seek(to time: CMTime,
                      toleranceBefore: CMTime,
                      toleranceAfter: CMTime,
                      completionHandler: @escaping (Bool) -> Void) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        change(controller)
        controller.seek(to: time,
                        toleranceBefore: toleranceBefore,
                        toleranceAfter: toleranceAfter,
                        completionHandler: completionHandler)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        change(controller)
        controller.seek(to: time,
                        toleranceBefore: toleranceBefore,
                        toleranceAfter: toleranceAfter)
    }
    
    public func seek(to time: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        change(controller)
        controller.seek(to: time,
                        completionHandler: completionHandler)
    }
    
    public func seek(to time: CMTime) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        change(controller)
        controller.seek(to: time)
    }
    
    public func seek(to time: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        let time = CMTime(seconds: time,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        seek(to: time,
             completionHandler: completionHandler)
    }
    
    public func seek(to time: Double) {
        let time = CMTime(seconds: time,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        seek(to: time)
    }
    
    public func seek(to date: Date,
                     completionHandler: @escaping (Bool) -> Void) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        change(controller)
        controller.seek(to: date,
                        completionHandler: completionHandler)
    }
    
    public func seek(to date: Date) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        change(controller)
        controller.seek(to: date)
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
    
    public func rewind() {
        play(at: playerController.configuration.rewindRate)
    }
    
    public func rewind(at rate: AKPlaybackRate) {
        play(at: rate)
    }
    
    // MARK: - Additional Helper Functions
    
    private func startObservingPlayerStatus() {
        playerController.playerStatusPublisher
            .prepend(playerController.player.status)
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
        playerController.currentMedia!.playerItemFailedToPlayToEndTimePublisher
            .sink { [weak self] error in
                guard let self else { return }
                guard error.underlyingError is URLError else {
                    let controller = AKFailedState(playerController: playerController,
                                                   error: .itemFailedToPlayToEndTime)
                    return change(controller)
                }
                
                let controller = AKWaitingForNetworkState(playerController: playerController,
                                                          autoPlay: true,
                                                          rate: rate)
                change(controller)
            }.store(in: &cancellables)
        
        playerController.currentMedia!.playerItemDidPlayToEndTimePublisher
            .sink { [weak self] error in
                guard let self else { return }
                let controller = AKPausedState(playerController: playerController,
                                               playerItemDidPlayToEndTime: true)
                change(controller)
            }.store(in: &cancellables)
        
        playerController.currentMedia!.playerItemPlaybackStalledPublisher
            .sink { [weak self] error in
                guard let self else { return }
                let controller = AKBufferingState(playerController: playerController,
                                                  autoPlay: true,
                                                  rate: rate)
                change(controller)
            }.store(in: &cancellables)
    }
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        playerController.change(controller)
    }
}
