//
//  AKBaseState.swift
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

import Foundation
import AVFoundation
import Combine

open class AKBaseState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned public let playerController: any AKPlayerControllerProtocol
    
    public let state: AKPlayerState
    
    // MARK: - Init
    
    public init(playerController: any AKPlayerControllerProtocol, state: AKPlayerState) {
        self.playerController = playerController
        self.state = state
    }
    
    deinit { }
    
    public func processStateChange() {
        // Default noop; concrete states may override
    }
    
    // MARK: - Commands
    
    public func load(media: AKPlayable) {
        startLoad(media: media, autoPlay: false)
    }
    
    public func load(media: AKPlayable,
                     autoPlay: Bool) {
        startLoad(media: media, autoPlay: autoPlay)
    }
    
    public func load(media: AKPlayable,
                     autoPlay: Bool,
                     at position: CMTime) {
        startLoad(media: media, autoPlay: autoPlay, at: position)
    }
    
    public func load(media: AKPlayable,
                     autoPlay: Bool,
                     at position: Double) {
        let time = CMTime(seconds: position,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        startLoad(media: media, autoPlay: autoPlay, at: time)
    }
    
    public func play() {
        performIfAllowed(allowed: { [weak self] in
            guard let self else { return false }
            return allowsPlay()
        }, action: { [weak self] in
            guard let self else { return }
            guard let performer = playerController as? AKPlayerControllerPerforming else {
                assertionFailure("Controller must implement AKPlayerControllerPerforming")
                return
            }
            performer.performPlay()
        }, blocked: { err in
            debugPrint("Play blocked:", err)
        })
    }
    
    public func play(at rate: AKPlaybackRate) {
        performIfAllowed(allowed: { [weak self] in
            guard let s = self else { return false }
            return s.allowsPlay()
        }, action: { [weak self] in
            guard let s = self else { return }
            s.playerController.play(at: rate)
            s.playerController.performPlay(at: rate)
        }, blocked: { err in
            debugPrint("Play(at:) blocked:", err)
        })
    }
    
    public func pause() {
        performIfAllowed(allowed: { [weak self] in
            guard let s = self else { return false }
            return s.allowsPause()
        }, action: { [weak self] in
            guard let s = self else { return }
            s.playerController.pause()
            s.playerController.performPause()
        }, blocked: { err in
            debugPrint("Pause blocked:", err)
        })
    }
    
    public func togglePlayPause() {
        // default toggle uses controller state
        if state.isPlaying ?? false {
            if state.isPlaying ?? false {
                pause()
            } else {
                play()
            }
        }
    }
    
    public func stop() {
        performIfAllowed(allowed: { [weak self] in
            guard let s = self else { return false }
            return s.allowsStop()
        }, action: { [weak self] in
            guard let s = self else { return }
            s.playerController.stop()
            s.playerController.performStop()
        }, blocked: { err in
            debugPrint("Stop blocked:", err)
        })
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        performIfAllowed(allowed: { [weak self] in
            guard let s = self else { return false }
            return s.allowsSeek()
        }, action: { [weak self] in
            guard let s = self else { completionHandler(false); return }
            s.playerController.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
            s.playerController.performSeek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
        }, blocked: { _ in completionHandler(false) })
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime) {
        
    }
    
    public func seek(to time: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        controller.seek(to: time,
                        completionHandler: completionHandler)
        change(controller)
    }
    
    public func seek(to time: CMTime) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        controller.seek(to: time)
        change(controller)
    }
    
    public func seek(to time: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        seek(to: CMTime(seconds: time,
                        preferredTimescale: playerController.configuration.preferredTimeScale),
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
                                          autoPlay: false)
        controller.seek(to: date,
                        completionHandler: completionHandler)
        change(controller)
    }
    
    public func seek(to date: Date) {
        let controller = AKBufferingState(playerController: playerController,
                                          autoPlay: false)
        controller.seek(to: date)
        change(controller)
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
    
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        playerController.change(controller)
    }
    
    open func performIfAllowed(allowed: @escaping () -> Bool = { true },
                               action: @escaping () -> Void,
                               blocked: ((AKPlayerError) -> Void)? = nil) {
        // Global checks (optional): if you have a controller-level preflight that doesn't need a command enum,
        // you can call it here. For now only per-action allowed-check is applied.
        guard allowed() else {
            blocked?(.noItemToPlay) //.invalidstate
            return
        }
        action()
    }
    
    // Per-action allow hooks — override in concrete states to change behavior.
    open func allowsPlay() -> Bool {
        return state.isLoaded && !state.isPlaying
    }
    open func allowsPause() -> Bool {
        return state.isPlaying
    }
    open func allowsSeek() -> Bool {
        return playerController.currentMedia?.canSeek(to: .zero).flag ?? false
    }
    open func allowsStop() -> Bool {
        return state.isLoaded
    }
    
    private func startLoad(media: AKPlayable, autoPlay: Bool, at position: CMTime? = nil) {
        let canLoad = canLoad(media, autoPlay: autoPlay)
        guard canLoad.0 else {
            playerController.delegate?.playerController(playerController,
                                                        didEncounterUnavailableAction: canLoad.1!)
            return
        }
        beforeLoad(media: media, autoPlay: autoPlay, position: position)
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: position)
        change(controller)
    }
    
    // MARK: - Pre-load hook
    
    /// Called on the current state before starting a new load.
    /// Override in a concrete state to perform cleanup (e.g. abortAssetInitialization).
    open func beforeLoad(media: AKPlayable, autoPlay: Bool, position: CMTime?) { }
    
    /// Centralized preflight for loads. Return true if load can proceed, false otherwise.
    open func canLoad(_ media: AKPlayable, autoPlay: Bool) -> (Bool, AKPlayerUnavailableCommandReason?) {
        // Global player-level check: if AVPlayer has a fatal error, block load and notify delegate.
        if playerController.player.error != nil {
            playerController.delegate?.playerController(playerController,
                                                        didEncounterUnavailableAction: .playerCanNoLongerPlay)
            return (false, .playerCanNoLongerPlay)
        }
        // Let media perform its own validation (if available). Prefer async validate elsewhere.
        // Example: if media has an immediate state that blocks loading you can check here.
        return (true, nil)
    }
    
    open func canSeek() -> (Bool, AKPlayerUnavailableCommandReason?) {
        return (true, nil)
    }
    
    open func canFastForward() -> (Bool, AKPlayerUnavailableCommandReason?) {
        return (true, nil)
    }
    
    open func canRewind() -> (Bool, AKPlayerUnavailableCommandReason?) {
        return (true, nil)
    }
    
    open func canStep() -> (Bool, AKPlayerUnavailableCommandReason?) {
        return (true, nil)
    }
}
