//
//  AKIdleState.swift
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

final class AKIdleState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned let playerController: AKPlayerControllerProtocol
    
    let state: AKPlayerState = .idle
    
    // MARK: - Init
    
    init(playerController: AKPlayerControllerProtocol) {
        self.playerController = playerController
    }
    
    deinit { }
    
    func didChangeState() { }
    
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
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func play(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func pause() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func togglePlayPause() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func stop() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    func seek(to time: CMTime) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func seek(to time: Double,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    func seek(to time: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func seek(to date: Date,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    func seek(to date: Date) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func seek(toOffset offset: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func seek(toOffset offset: Double,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    func seek(toPercentage percentage: Double,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    func seek(toPercentage percentage: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func step(by count: Int) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func fastForward() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func fastForward(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func rewind() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    func rewind(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
}
