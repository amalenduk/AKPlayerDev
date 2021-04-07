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

final class AKLoadedState: AKPlayerStateControllable {
    
    // MARK: - Properties
    
    unowned let manager: AKPlayerManagerProtocol
    
    let state: AKPlayer.State = .loaded
    
    let autoPlay: Bool

    private let position: CMTime?
    
    private var audioSessionInterruptionObservingService: AKAudioSessionInterruptionObservingServiceable!

    private var observingPlayerTimeService: AKObservingPlayerTimeService!

    private var playerItemAssetKeysObservingService: AKPlayerItemAssetKeysObservingService!
    
    private var workItem: DispatchWorkItem?
    
    // MARK: - Init
    
    init(manager: AKPlayerManagerProtocol,
         autoPlay: Bool = false,
         at position: CMTime? = nil) {
        AKPlayerLogger.shared.log(message: "Init",
                                  domain: .lifecycleState)
        self.manager = manager
        self.autoPlay = autoPlay
        self.position = position
        setMetadata()
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit",
                                  domain: .lifecycleState)
    }

    func stateChanged() {
        guard let media = manager.currentMedia,
              let currentItem = manager.currentItem else { assertionFailure("Media and Current item should available"); return }
        startPlayerItemAssetKeysObservingService(with: currentItem,
                                                 media: media)
        manager.plugins?.forEach({$0.playerPlugin(didLoad: media,
                                                  with: currentItem.duration)})
        startAudioSessionInterruptionObservingService()
        startObservingPlayerTimeService()
        if let position = position {
            seek(to: position)
        }else {
            manager.delegate?.playerManager(didCurrentTimeChange: currentItem.currentTime())
        }
        if autoPlay && !manager.audioSessionInterrupted {
            workItem = DispatchWorkItem(block: { [unowned self] in
                play()
            })
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: workItem!)
        }
    }
    
    // MARK: - Commands
    
    func load(media: AKPlayable) {
        let controller = AKLoadingState(manager: manager,
                                        media: media)
        change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool) {
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay)
        change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: CMTime) {
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay,
                                        at: position)
        change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: Double) {
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay,
                                        at: CMTime(seconds: position,
                                                   preferredTimescale: manager.configuration.preferredTimescale))
        change(controller)
    }
    
    func play() {
        let controller = AKBufferingState(manager: manager,
                                          playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
        change(controller)
        controller.playCommand()
    }
    
    func pause() {
        let controller = AKPausedState(manager: manager,
                                       playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
        change(controller)
    }
    
    func stop() {
        let controller = AKStoppedState(manager: manager,
                                        playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
        change(controller)
    }
    
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        manager.currentItem?.cancelPendingSeeks()
        manager.player.seek(to: time,
                            completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime) {
        manager.currentItem?.cancelPendingSeeks()
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
        seek(to: (manager.itemDuration?.seconds ?? 0) / value,
             completionHandler: completionHandler)
    }
    
    func seek(toPercentage value: Double) {
        seek(to: (manager.itemDuration?.seconds ?? 0) / value)
    }
    
    func step(byCount stepCount: Int) {
        guard let playerItem = manager.currentItem else { assertionFailure("Player item should available"); return }
        playerItem.step(byCount: stepCount)
    }
    
    // MARK: - Additional Helper Functions
    
    private func startAudioSessionInterruptionObservingService() {
        audioSessionInterruptionObservingService = AKAudioSessionInterruptionObservingService(audioSession: manager.audioSessionService.audioSession)
        
        audioSessionInterruptionObservingService.onInterruptionBegan = { [unowned self] in
            if autoPlay { pause() }
        }
    }
    
    private func startObservingPlayerTimeService() {
        observingPlayerTimeService = AKObservingPlayerTimeService(with: manager.player,
                                                                  configuration: manager.configuration)
        
        observingPlayerTimeService.onChangePeriodicTime = { [unowned self] time in
            manager.setNowPlayingPlaybackInfo()
            manager.delegate?.playerManager(didCurrentTimeChange: time)
        }
    }
    
    private func startPlayerItemAssetKeysObservingService(with playerItem: AVPlayerItem,
                                                          media: AKPlayable) {
        playerItemAssetKeysObservingService = AKPlayerItemAssetKeysObservingService(with: playerItem,
                                                                                    media: media,
                                                                                    manager: manager)
        playerItemAssetKeysObservingService.startObserving()
    }

    private func change(_ controller: AKPlayerStateControllable) {
        workItem?.cancel()
        manager.change(controller)
    }
    
    private func setMetadata() {
        manager.setNowPlayingMetadata()
    }
}
