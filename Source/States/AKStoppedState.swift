//
//  AKStoppedState.swift
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

public class AKStoppedState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned public let playerController: AKPlayerControllerProtocol
    
    public let state: AKPlayerState = .stopped
    
    private let seekToZero: Bool
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol,
                seekToZero flag: Bool = false) {
        self.playerController = playerController
        self.seekToZero = flag
    }
    
    deinit { }
    
    public func didChangeState() {
        if playerController.player.timeControlStatus == .playing
            || playerController.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            playerController.player.pause()
        }
        
        guard playerController.currentMedia!.state.isReadyToPlay
                && playerController.currentMedia!.currentTime.seconds > 0
                && seekToZero else { return }
        playerController.delegate?.playerController(playerController,
                                                    didChangeCurrentTimeTo: .zero, for: playerController.currentMedia!)
        playerController.currentMedia?.playerItem?.seek(to: .zero,
                                                        toleranceBefore: .zero,
                                                        toleranceAfter: .zero,
                                                        completionHandler: { [unowned self] finished in
            playerController.delegate?.playerController(playerController,
                                                        didChangeCurrentTimeTo: .zero, for: playerController.currentMedia!)
        })
    }
    
    // MARK: - Commands bolo Ajay Ajay
    
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
        guard playerController.currentMedia!.state.isReadyToPlay,
        playerController.player.currentItem == playerController.currentMedia?.playerItem else {
            load(media: playerController.currentMedia!,
                 autoPlay: true)
            return
        }
        
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true)
        change(controller)
        controller.seek(to: CMTime.zero,
                        toleranceBefore: .zero,
                        toleranceAfter: .zero)
    }
    
    public func play(at rate: AKPlaybackRate) {
        guard playerController.currentMedia!.state.isReadyToPlay,
        playerController.player.currentItem == playerController.currentMedia?.playerItem else {
            let controller = AKLoadingState(playerController: playerController,
                                            media: playerController.currentMedia!,
                                            autoPlay: true,
                                            rate: rate)
            return change(controller)
        }
        
        guard playerController.currentMedia!.canPlay(at: rate) else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .canNotPlayAtSpecifiedRate)
            return
        }
        
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        change(controller)
        controller.seek(to: CMTime.zero,
                        toleranceBefore: .zero,
                        toleranceAfter: .zero)
    }
    
    public func pause() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .alreadyStopped)
    }
    
    public func togglePlayPause() {
        play()
    }
    
    public func stop() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .alreadyStopped)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        guard playerController.currentMedia!.state.isReadyToPlay else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .loadMediaFirst)
            return
        }
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        change(controller)
        controller.seek(to: time,
                        toleranceBefore: toleranceBefore,
                        toleranceAfter: toleranceAfter,
                        completionHandler: completionHandler)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime) {
        guard playerController.currentMedia!.state.isReadyToPlay else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .loadMediaFirst)
            return
        }
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        change(controller)
        controller.seek(to: time,
                        toleranceBefore: toleranceBefore,
                        toleranceAfter: toleranceAfter)
    }
    
    public func seek(to time: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        guard playerController.currentMedia!.state.isReadyToPlay else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .loadMediaFirst)
            return
        }
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        change(controller)
        controller.seek(to: time,
                        completionHandler: completionHandler)
    }
    
    public func seek(to time: CMTime) {
        guard playerController.currentMedia!.state.isReadyToPlay else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .loadMediaFirst)
            return
        }
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
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
        guard playerController.currentMedia!.state.isReadyToPlay else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .loadMediaFirst)
            return
        }
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        change(controller)
        controller.seek(to: date,
                        completionHandler: completionHandler)
    }
    
    public func seek(to date: Date) {
        guard playerController.currentMedia!.state.isReadyToPlay else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .loadMediaFirst)
            return
        }
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        change(controller)
        controller.seek(to: date)
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
        guard playerController.currentMedia!.state.isReadyToPlay else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .loadMediaFirst)
            return
        }
        
        let result = playerController.currentMedia!.canStep(by: count)
        
        guard result else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .canNotStepForward)
            return
        }
        
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
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        playerController.change(controller)
    }
}
