//
//  AKLoadedState.swift
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

final class AKLoadedState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned public let playerController: AKPlayerControllerProtocol
    
    public let state: AKPlayerState = .loaded
    
    var autoPlay: Bool
    
    private let position: CMTime?
    
    private var rate: AKPlaybackRate?
    
    private var isSeeking: Bool = false
    
    // MARK: - Init
    
    init(playerController: AKPlayerControllerProtocol,
         autoPlay: Bool = false,
         position: CMTime? = nil,
         rate: AKPlaybackRate? = nil) {
        self.playerController = playerController
        self.autoPlay = autoPlay
        self.position = position
        self.rate = rate
    }
    
    deinit { print("Deinit called from ", #file) }
    
    func didChangeState() {
        playerController.delegate?.playerController(playerController,
                                                    didChangeCurrentTimeTo: playerController.currentTime,
                                                    for: playerController.currentMedia!)
        if autoPlay {
            play()
        } else if let position = position {
            seek(to: position)
        }
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
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        change(controller)
        if let position = position { controller.seek(to: position) }
    }
    
    func play(at rate: AKPlaybackRate) {
        guard playerController.currentMedia!.canPlay(at: rate) else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .canNotPlayAtSpecifiedRate)
            return
        }
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        change(controller)
        if let position = position { controller.seek(to: position) }
    }
    
    func pause() {
        if autoPlay {
            autoPlay = false
        } else {
            playerController.delegate?.playerController(playerController,
                                                        unavailableActionWith: .alreadyPaused)
        }
    }
    
    func togglePlayPause() {
        if autoPlay {
            pause()
        } else {
            play()
        }
    }
    
    func stop() {
        let controller = AKStoppedState(playerController: playerController,
                                        seekToZero: true)
        change(controller)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        playerController.change(controller)
        controller.seek(to: time,
                        toleranceBefore: toleranceBefore,
                        toleranceAfter: toleranceAfter,
                        completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        playerController.change(controller)
        controller.seek(to: time,
                        toleranceBefore: toleranceBefore,
                        toleranceAfter: toleranceAfter)
    }
    
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        playerController.change(controller)
        controller.seek(to: time,
                        completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        playerController.change(controller)
        controller.seek(to: time)
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
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        playerController.change(controller)
        controller.seek(to: date,
                        completionHandler: completionHandler)
    }
    
    func seek(to date: Date) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        playerController.change(controller)
        controller.seek(to: date)
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
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        playerController.change(controller)
    }
}
