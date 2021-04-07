//
//  AKWaitingForNetworkState.swift
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

final class AKWaitingForNetworkState: AKPlayerStateControllable {
    
    // MARK: - Properties
    
    unowned let manager: AKPlayerManagerProtocol
    
    let state: AKPlayer.State = .waitingForNetwork

    private var audioSessionInterruptionObservingService: AKAudioSessionInterruptionObservingServiceable!

    private var configuringAutomaticWaitingBehaviorService: AKConfiguringAutomaticWaitingBehaviorService!

    private var observingPlayerTimeService: AKObservingPlayerTimeService!

    private var routeChangeObservingService: AKRouteChangeObservingService!
    
    private var playerItemAssetKeysObservingService: AKPlayerItemAssetKeysObservingService!

    private var timer: Timer?
    
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
        timer?.invalidate()
    }

    func stateChanged() {
        guard let media = manager.currentMedia else { assertionFailure("Media and Current item should available"); return }
        manager.plugins?.forEach({$0.playerPlugin(didStartWaitingForNetwork: media)})
        startAudioSessionInterruptionObservingService()
        startObservingPlayerTimeService()
        startRouteChangeObservingService()
        startConfiguringAutomaticWaitingBehaviorService()
    }
    
    // MARK: - Commands
    
    func load(media: AKPlayable) {
        clearCallBacks()
        let controller = AKLoadingState(manager: manager,
                                        media: media)
        change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool) {
        clearCallBacks()
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay)
        change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: CMTime) {
        clearCallBacks()
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay,
                                        at: position)
        change(controller)
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
        change(controller)
    }
    
    func play() {
        guard let media = manager.currentMedia else { assertionFailure("Should available media at this stage"); return}
        guard let reasonForWaitingToPlay = manager.player.reasonForWaitingToPlay else {
            let controller = AKBufferingState(manager: manager,
                                              playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
            change(controller)
            controller.playCommand()
            return
        }
        
        switch reasonForWaitingToPlay {
        case .evaluatingBufferingRate:
            load(media: media,
                 autoPlay: true,
                 at: manager.currentTime)
        case .toMinimizeStalls:
            let controller = AKBufferingState(manager: manager,
                                              playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
            change(controller)
            controller.playCommand()
        default:
            assertionFailure("Sould be not here \(reasonForWaitingToPlay.rawValue)")
        }
    }
    
    func pause() {
        clearCallBacks()
        let controller = AKPausedState(manager: manager,
                                       playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
        change(controller)
    }
    
    func stop() {
        clearCallBacks()
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
    
    private func startConfiguringAutomaticWaitingBehaviorService() {
        configuringAutomaticWaitingBehaviorService = AKConfiguringAutomaticWaitingBehaviorService(with: manager.player, configuration: manager.configuration)
        
        configuringAutomaticWaitingBehaviorService.onChangeTimeControlStatus = { [unowned self] status in
            switch status {
            case .paused:
                pause()
            case .waitingToPlayAtSpecifiedRate:
                AKPlayerLogger.shared.log(message: "TimeControlStaus is WaitingToPlayAtSpecifiedRate now",
                                          domain: .state)
            case .playing:
                let controller = AKPlayingState(manager: manager,
                                                playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
                change(controller)
            @unknown default:
                assertionFailure("Sould be not here \(status.rawValue)")
            }
        }
    }

    private func change(_ controller: AKPlayerStateControllable) {
        manager.change(controller)
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

    private func clearCallBacks() {
        /* It is necessary to remove the callbacks for time control status before change state to paused state,
         Eighter it will cause an infinite loop between paused state and the time control staus to call on waiting
         for the network state. */
        if let configuringAutomaticWaitingBehaviorService = configuringAutomaticWaitingBehaviorService {
            configuringAutomaticWaitingBehaviorService.stop(clearCallBacks: true)
        }
    }

    private func setMetadata() {
        guard manager.configuration.isNowPlayingEnabled else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            self.manager.setNowPlayingPlaybackInfo()
        })
    }
}
