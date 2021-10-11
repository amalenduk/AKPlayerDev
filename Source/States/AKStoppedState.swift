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

final class AKStoppedState: AKPlayerStateControllable {
    
    // MARK: - Properties
    
    unowned let manager: AKPlayerManagerProtocol
    
    let state: AKPlayerState = .stopped
    
    private let playerItemDidPlayToEndTime: Bool
    
    private var observingPlayerTimeService: AKObservingPlayerTimeService!
    
    private var playerItemAssetKeysObservingService: AKPlayerItemAssetKeysObservingService!
    
    // MARK: - Init
    
    init(manager: AKPlayerManagerProtocol,
         playerItemDidPlayToEndTime flag: Bool = false,
         playerItemAssetKeysObservingService: AKPlayerItemAssetKeysObservingService!) {
        AKPlayerLogger.shared.log(message: "Init",
                                  domain: .lifecycleState)
        self.manager = manager
        self.playerItemDidPlayToEndTime = flag
        self.playerItemAssetKeysObservingService = playerItemAssetKeysObservingService
        manager.player.pause()
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit",
                                  domain: .lifecycleState)
    }
    
    func stateDidChange() {
        guard let media = manager.currentMedia else { assertionFailure("Media and Current item should available"); return }
        manager.plugins?.forEach({$0.playerPlugin(didStopped: media,
                                                  at: manager.currentTime)})
        startObservingPlayerTimeService()
        if !playerItemDidPlayToEndTime { seek(to: 0) }
        setPlaybackInfo()
    }
    
    // MARK: - Commands
    
    func load(media: AKPlayable) {
        let controller = AKLoadingState(manager: manager,
                                        media: media)
        manager.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool) {
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay)
        manager.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: CMTime) {
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay,
                                        at: position)
        manager.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: Double) {
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay,
                                        at: CMTime(seconds: position,
                                                   preferredTimescale: manager.configuration.preferredTimescale))
        manager.change(controller)
    }
    
    func play() {
        if manager.currentItem?.status == .readyToPlay {
            if (manager.currentTime.seconds + 1) >= (manager.duration?.seconds ?? 0) { seek(to: 0) }
            let controller = AKBufferingState(manager: manager,
                                              playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
            manager.change(controller)
            controller.playCommand()
        } else if let media = manager.currentMedia {
            let controller = AKLoadingState(manager: manager,
                                            media: media,
                                            autoPlay: true)
            manager.change(controller)
        } else {
            assertionFailure("Sould not be here")
        }
    }
    
    func pause() {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.alreadyStopped.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .alreadyStopped)
    }
    
    func togglePlayPause() {
        play()
    }
    
    func stop() {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.alreadyStopped.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .alreadyStopped)
    }
    
    func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: @escaping (Bool) -> Void) {
        manager.player.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
        manager.player.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
    }
    
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        manager.player.seek(to: time,
                            completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime) {
        manager.player.seek(to: time)
    }
    
    func seek(to time: Double,
              completionHandler: @escaping (Bool) -> Void) {
        seek(to: CMTime(seconds: time,
                        preferredTimescale: manager.configuration.preferredTimescale),
             completionHandler: completionHandler)
    }
    
    func seek(to time: Double) {
        seek(to: CMTime(seconds: time,
                        preferredTimescale: manager.configuration.preferredTimescale))
    }
    
    func seek(to date: Date, completionHandler: @escaping (Bool) -> Void) {
        manager.player.seek(to: date, completionHandler: completionHandler)
    }
    
    func seek(to date: Date) {
        manager.player.seek(to: date)
    }
    
    func seek(offset: Double) {
        seek(to: manager.currentTime.seconds + offset)
    }
    
    func seek(offset: Double,
              completionHandler: @escaping (Bool) -> Void) {
        seek(to: manager.currentTime.seconds + offset,
             completionHandler: completionHandler)
    }
    
    func seek(toPercentage value: Double,
              completionHandler: @escaping (Bool) -> Void) {
        seek(to: (manager.duration?.seconds ?? 0) / value,
             completionHandler: completionHandler)
    }
    
    func seek(toPercentage value: Double) {
        seek(to: (manager.duration?.seconds ?? 0) / value)
    }
    
    func step(byCount stepCount: Int) {
        guard let playerItem = manager.currentItem else { assertionFailure("Player item should available"); return }
        playerItem.step(byCount: stepCount)
    }
    
    // MARK: - Additional Helper Functions
    
    private func startObservingPlayerTimeService() {
        /*
         Check before start observing boundaryTime becuase if current item is nil no need to start observing,
         Sometimes state can change direct from loading state to stop state
         */
        guard manager.player.currentItem != nil else { return }
        observingPlayerTimeService = AKObservingPlayerTimeService(with: manager.player,
                                                                  configuration: manager.configuration)
        observingPlayerTimeService.onChangePeriodicTime = { [unowned self] time in
            setPlaybackInfo()
            manager.delegate?.playerManager(didCurrentTimeChange: time)
        }
    }
    
    private func setPlaybackInfo() {
        manager.setNowPlayingPlaybackInfo()
    }
}


