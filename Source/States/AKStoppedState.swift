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

final class AKStoppedState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned let playerController: AKPlayerControllerProtocol
    
    let state: AKPlayerState = .stopped
    
    private let playerItemDidPlayToEndTime: Bool
    
    // MARK: - Init
    
    init(playerController: AKPlayerControllerProtocol,
         playerItemDidPlayToEndTime flag: Bool = false) {
        self.playerController = playerController
        self.playerItemDidPlayToEndTime = flag
    }
    
    deinit { print("Deinit called from ", #file) }
    
    func didChangeState() {
        playerController.player.pause()
        if !playerItemDidPlayToEndTime { seek(to: 0) }
    }
    
    // MARK: - Commands
    
    func load(media: AKPlayable) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media)
        playerController.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay)
        playerController.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: CMTime) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: position)
        playerController.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: Double) {
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: CMTime(seconds: position,
                                                         preferredTimescale: playerController.configuration.preferredTimeScale))
        playerController.change(controller)
    }
    
    func play() {
        guard let currentMedia = playerController.currentMedia else { fatalError() }
        if currentMedia.state == .readyToPlay {
            if (playerController.currentTime.seconds + 1) >= (playerController.currentItem?.duration.seconds ?? 0) { seek(to: 0) }
            let controller = AKBufferingState(playerController: playerController)
            playerController.change(controller)
        } else {
            let controller = AKLoadingState(playerController: playerController,
                                            media: currentMedia,
                                            autoPlay: true)
            playerController.change(controller)
        }
    }
    
    func play(at rate: AKPlaybackRate) {
        guard let currentMedia = playerController.currentMedia else { fatalError() }
        
        if currentMedia.state.isReadyToPlay {
            if (playerController.currentTime.seconds + 1) >= (playerController.currentItem?.duration.seconds ?? 0) { seek(to: 0) }
            
            if currentMedia.canPlay(at: rate) {
                let controller: AKBufferingState
                controller = AKBufferingState(playerController: playerController,
                                              rate: rate)
                playerController.change(controller)
            } else {
                playerController.delegate?.playerController(playerController,
                                                            unavailableActionWith: .canNotPlayAtSpecifiedRate)
            }
        } else {
            let controller = AKLoadingState(playerController: playerController,
                                            media: currentMedia,
                                            autoPlay: true,
                                            rate: rate)
            playerController.change(controller)
        }
    }
    
    func pause() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .alreadyStopped)
    }
    
    func togglePlayPause() {
        play()
    }
    
    func stop() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .alreadyStopped)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.player.seek(to: time,
                                     toleranceBefore: toleranceBefore,
                                     toleranceAfter: toleranceAfter,
                                     completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime) {
        playerController.player.seek(to: time,
                                     toleranceBefore: toleranceBefore,
                                     toleranceAfter: toleranceAfter)
    }
    
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.player.seek(to: time,
                                     completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime) {
        playerController.player.seek(to: time)
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
        playerController.player.seek(to: date,
                                     completionHandler: completionHandler)
    }
    
    func seek(to date: Date) {
        playerController.player.seek(to: date)
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
}
