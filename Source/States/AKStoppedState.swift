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
import Combine

public class AKStoppedState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned public let playerController: AKPlayerControllerProtocol
    
    public let state: AKPlayerState = .stopped
    
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol) {
        self.playerController = playerController
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    public func didChangeState() {
        startObservingPlayerStatus()
        
        if !(playerController.player.timeControlStatus == .paused) {
            playerController.player.pause()
        }
        
        playerController.currentMedia?.playerItem?.cancelPendingSeeks()
        playerController.player.replaceCurrentItem(with: nil)
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
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func play(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func pause() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .alreadyStopped)
    }
    
    public func togglePlayPause() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func stop() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .alreadyStopped)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func seek(to time: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    public func seek(to time: CMTime) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func seek(to time: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    public func seek(to time: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func seek(to date: Date,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    public func seek(to date: Date) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func seek(toOffset offset: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func seek(toOffset offset: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    public func seek(toPercentage percentage: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
        completionHandler(false)
    }
    
    public func seek(toPercentage percentage: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func step(by count: Int) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func fastForward() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func fastForward(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func rewind() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
    }
    
    public func rewind(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .loadMediaFirst)
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
    }
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        playerController.change(controller)
    }
}
