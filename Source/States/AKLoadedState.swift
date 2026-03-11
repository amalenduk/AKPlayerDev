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
import Combine

public class AKLoadedState: AKBaseState {
    
    // MARK: - Properties
    
    public private(set) var autoPlay: Bool
    private let position: CMTime?
    private var rate: AKPlaybackRate?
    
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol,
                autoPlay: Bool = false,
                position: CMTime? = nil,
                rate: AKPlaybackRate? = nil) {
        self.autoPlay = autoPlay
        self.position = position
        self.rate = rate
        super.init(playerController: playerController, state: .loaded)
    }
    
    deinit {
        subscriptions.removeAll()
    }
    
    public override func processStateChange() {
        startObservingPlayerProperties()
        
        playerController.delegate?.playerController(playerController,
                                                    didChangeCurrentTimeTo: playerController.currentTime,
                                                    for: playerController.currentMedia!)
        if autoPlay {
            play()
        } else if let position = position {
            let result = playerController.currentMedia!.canSeek(to: position)
            guard result.flag else {
                playerController.delegate?.playerController(playerController,
                                                            didEncounterUnavailableAction: result.reason!)
                return
            }
            seek(to: position)
        }
    }
    
    // MARK: - Commands
    
    public override func play() {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        if let position = position { controller.seek(to: position) }
        change(controller)
    }
    
    public override func play(at rate: AKPlaybackRate) {
        guard playerController.currentMedia!.canPlay(at: rate) else {
            playerController.delegate?.playerController(playerController,
                                                        didEncounterUnavailableAction: .canNotPlayAtSpecifiedRate)
            return
        }
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: true,
                                          rate: rate)
        if let position = position { controller.seek(to: position) }
        change(controller)
    }
    
    public override func pause() {
        if autoPlay {
            autoPlay = false
        } else {
            playerController.delegate?.playerController(playerController,
                                                        didEncounterUnavailableAction: .alreadyPaused)
        }
    }
    
    public override func togglePlayPause() {
        if autoPlay {
            pause()
        } else {
            play()
        }
    }
    
    public override func stop() {
        let controller = AKStoppedState(playerController: playerController)
        change(controller)
    }
    
    public override func seek(to time: CMTime,
                              toleranceBefore: CMTime,
                              toleranceAfter: CMTime,
                              completionHandler: @escaping (Bool) -> Void) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        controller.seek(to: time,
                        toleranceBefore: toleranceBefore,
                        toleranceAfter: toleranceAfter,
                        completionHandler: completionHandler)
        change(controller)
    }
    
    public override func seek(to time: CMTime,
                              toleranceBefore: CMTime,
                              toleranceAfter: CMTime) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        controller.seek(to: time,
                        toleranceBefore: toleranceBefore,
                        toleranceAfter: toleranceAfter)
        change(controller)
    }
    
    public override func seek(to time: CMTime,
                              completionHandler: @escaping (Bool) -> Void) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        controller.seek(to: time,
                        completionHandler: completionHandler)
        change(controller)
    }
    
    public override func seek(to time: CMTime) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        controller.seek(to: time)
        change(controller)
    }
    
    public override func seek(to time: Double,
                              completionHandler: @escaping (Bool) -> Void) {
        seek(to: CMTime(seconds: time,
                        preferredTimescale: playerController.configuration.preferredTimeScale),
             completionHandler: completionHandler)
    }
    
    public override func seek(to time: Double) {
        let time = CMTime(seconds: time,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        seek(to: time)
    }
    
    public override func seek(to date: Date,
                              completionHandler: @escaping (Bool) -> Void) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        controller.seek(to: date,
                        completionHandler: completionHandler)
        change(controller)
    }
    
    public override func seek(to date: Date) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        controller.seek(to: date)
        change(controller)
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
    
    public override func step(by count: Int) {
        playerController.currentItem!.step(byCount: count)
    }
    
    public override func fastForward() {
        play(at: playerController.configuration.fastForwardRate)
    }
    
    public override func fastForward(at rate: AKPlaybackRate) {
        play(at: rate)
    }
    
    public override func rewind() {
        play(at: playerController.configuration.rewindRate)
    }
    
    public override func rewind(at rate: AKPlaybackRate) {
        play(at: rate)
    }
    
    // MARK: - Additional Helper Functions
    
    private func startObservingPlayerProperties() {
        playerController.player.publisher(for: \.status)
            .prepend(playerController.player.status)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] status in
                guard status == .failed else { return }
                let controller = AKFailedState(playerController: playerController,
                                               error: .playerCanNoLongerPlay(error: playerController.player.error))
                change(controller)
            }.store(in: &subscriptions)
        
        playerController.player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] timeControlStatus in
                guard playerController.player.currentItem == nil else { return }
                stop()
            }.store(in: &subscriptions)
    }
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        subscriptions.removeAll()
        playerController.change(controller)
    }
}
