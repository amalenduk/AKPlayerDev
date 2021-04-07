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

final class AKPlayingState: AKPlayerStateControllable {
    
    // MARK: - Properties
    
    unowned let manager: AKPlayerManagerProtocol
    
    let state: AKPlayer.State = .playing
    
    private var playerItemObservingNotificationsService: AKPlayerItemObservingNotificationsService!

    private var audioSessionInterruptionObservingService: AKAudioSessionInterruptionObservingServiceable!

    private var observingPlayerTimeService: AKObservingPlayerTimeService!

    private var routeChangeObservingService: AKRouteChangeObservingService!

    private var configuringAutomaticWaitingBehaviorService: AKConfiguringAutomaticWaitingBehaviorService!
    
    private var playerItemAssetKeysObservingService: AKPlayerItemAssetKeysObservingService!
    
    // MARK: - Init
    
    init(manager: AKPlayerManagerProtocol,
         playerItemAssetKeysObservingService: AKPlayerItemAssetKeysObservingService) {
        AKPlayerLogger.shared.log(message: "Init",
                                  domain: .lifecycleState)
        self.manager = manager
        self.playerItemAssetKeysObservingService = playerItemAssetKeysObservingService
        setMetadata()
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit",
                                  domain: .lifecycleState)
    }

    func stateChanged() {
        guard let media = manager.currentMedia else { assertionFailure("Media and Current item should available"); return }
        manager.plugins?.forEach({$0.playerPlugin(didStartPlaying: media,
                                                  at: manager.currentTime)})
        startPlayerItemObservingNotificationsService()
        startObservingPlayerTimeService()
        startAudioSessionInterruptionObservingService()
        startRouteChangeObservingService()
        startConfiguringAutomaticWaitingBehaviorService()
    }
    
    // MARK: - Commands
    
    func load(media: AKPlayable) {
        clearCallBacks()
        let controller = AKLoadingState(manager: manager,
                                        media: media)
        manager.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool) {
        clearCallBacks()
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay)
        manager.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: CMTime) {
        clearCallBacks()
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay,
                                        at: position)
        manager.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: Double) {
        clearCallBacks()
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay,
                                        at: CMTime(seconds: position,
                                                   preferredTimescale: manager.configuration.preferredTimescale))
        manager.change(controller)
    }
    
    func play() {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.alreadyPlaying.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .alreadyPlaying)
    }
    
    func pause() {
        clearCallBacks()
        let controller = AKPausedState(manager: manager,
                                       playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
        manager.change(controller)
    }
    
    func stop() {
        clearCallBacks()
        let controller = AKStoppedState(manager: manager,
                                        playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
        manager.change(controller)
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
    
    private func startPlayerItemObservingNotificationsService() {
        guard let playerItem = manager.currentItem else { assertionFailure("Player item should available"); return }
        playerItemObservingNotificationsService = AKPlayerItemObservingNotificationsService(playerItem: playerItem)
        
        playerItemObservingNotificationsService.onPlayerItemDidPlayToEndTime = { [unowned self] in
            manager.delegate?.playerManager(didItemPlayToEndTime: manager.currentTime)
            guard let media = manager.currentMedia else { assertionFailure("Media should available"); return }
            manager.plugins?.forEach({$0.playerPlugin(didPlayToEnd: media,
                                                      at: manager.currentTime)})
            clearCallBacks()
            let controller = AKStoppedState(manager: manager,
                                            playerItemDidPlayToEndTime: true,
                                            playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
            manager.change(controller)
        }
        
        playerItemObservingNotificationsService.onPlayerItemFailedToPlayToEndTime = { [unowned self] in
            let controller = AKWaitingForNetworkState(manager: manager,
                                                      playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
            manager.change(controller)
        }
        
        playerItemObservingNotificationsService.onPlayerItemPlaybackStalled = { [unowned self] in
            let controller = AKWaitingForNetworkState(manager: manager,
                                                      playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
            manager.change(controller)
        }
    }
    
    private func startAudioSessionInterruptionObservingService() {
        audioSessionInterruptionObservingService = AKAudioSessionInterruptionObservingService(audioSession: manager.audioSessionService.audioSession)
        
        audioSessionInterruptionObservingService.onInterruptionBegan = { [unowned self] in
            pause()
        }
    }
    
    private func startObservingPlayerTimeService() {
        observingPlayerTimeService = AKObservingPlayerTimeService(with: manager.player, configuration: manager.configuration)

        observingPlayerTimeService.onChangePeriodicTime = { [unowned self] time in
            setMetadata()
            manager.delegate?.playerManager(didCurrentTimeChange: time)
        }
    }
    
    private func startRouteChangeObservingService() {
        routeChangeObservingService = AKRouteChangeObservingService(audioSession: manager.audioSessionService.audioSession)
        
        routeChangeObservingService.onChangeRoute = { [unowned self] reason  in
            switch reason {
            case .oldDeviceUnavailable, .unknown:
                if !routeChangeObservingService.hasHeadphones() {
                    pause()
                }
            default:
                break
            }
        }
    }
    
    private func startConfiguringAutomaticWaitingBehaviorService() {
        configuringAutomaticWaitingBehaviorService = AKConfiguringAutomaticWaitingBehaviorService(with: manager.player, configuration: manager.configuration)

        configuringAutomaticWaitingBehaviorService.onChangeTimeControlStatus = { [unowned self] status in
            switch status {
            case .paused:
                pause()
            case .waitingToPlayAtSpecifiedRate:
                let controller = AKBufferingState(manager: manager,
                                                  playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
                manager.change(controller)
            default:
                break
            }
        }
    }

    private func clearCallBacks() {
        /* It is necessary to remove the callbacks for time control status before change state to paused state,
         Eighter it will cause an infinite loop between paused state and the time control staus to call on waiting
         for the network state. */
        if let configuringAutomaticWaitingBehaviorService = configuringAutomaticWaitingBehaviorService {
            configuringAutomaticWaitingBehaviorService.stop(clearCallBacks: true)
        }
    }
    
    private func setMetadata() {
        manager.setNowPlayingPlaybackInfo()
    }
}
