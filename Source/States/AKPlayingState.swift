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

final class AKPlayingState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned let manager: AKPlayerManagerProtocol
    
    let state: AKPlayerState = .playing
    
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
        
        guard let playerItem = manager.currentItem else { assertionFailure("Player item should available"); return }
        playerItemObservingNotificationsService = AKPlayerItemObservingNotificationsService(playerItem: playerItem)
        
        audioSessionInterruptionObservingService = AKAudioSessionInterruptionObservingService(audioSession: manager.audioSessionService.audioSession)
        
        observingPlayerTimeService = AKObservingPlayerTimeService(with: manager.player, configuration: manager.configuration)
        
        routeChangeObservingService = AKRouteChangeObservingService(audioSession: manager.audioSessionService.audioSession)
        
        configuringAutomaticWaitingBehaviorService = AKConfiguringAutomaticWaitingBehaviorService(with: manager.player, configuration: manager.configuration)
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit",
                                  domain: .lifecycleState)
    }
    
    func stateDidChange() {
        guard let media = manager.currentMedia else { assertionFailure("Media and Current item should available"); return }
        manager.plugins?.forEach({$0.playerPlugin(didStartPlaying: media,
                                                  at: manager.currentTime)})
        startPlayerItemObservingNotificationsService()
        startObservingPlayerTimeService()
        startAudioSessionInterruptionObservingService()
        startRouteChangeObservingService()
        startConfiguringAutomaticWaitingBehaviorService()
        setPlaybackInfo()
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
    
    func togglePlayPause() {
        pause()
    }
    
    func stop() {
        clearCallBacks()
        let controller = AKStoppedState(manager: manager,
                                        playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
        manager.change(controller)
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
    
    private func startPlayerItemObservingNotificationsService() {
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
            clearCallBacks()
            let controller = AKWaitingForNetworkState(manager: manager,
                                                      playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
            manager.change(controller)
        }
        
        playerItemObservingNotificationsService.onPlayerItemPlaybackStalled = { [unowned self] in
            clearCallBacks()
            let controller = AKWaitingForNetworkState(manager: manager,
                                                      playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
            manager.change(controller)
        }
    }
    
    private func startAudioSessionInterruptionObservingService() {
        audioSessionInterruptionObservingService.onInterruptionBegan = { [unowned self] in
            pause()
        }
    }
    
    private func startObservingPlayerTimeService() {
        observingPlayerTimeService.onChangePeriodicTime = { [unowned self] time in
            setPlaybackInfo()
            manager.delegate?.playerManager(didCurrentTimeChange: time)
        }
    }
    
    private func startRouteChangeObservingService() {
        routeChangeObservingService.onChangeRoute = { [weak self] reason  in
            guard let strongSelf = self else { return }
            switch reason {
            case .oldDeviceUnavailable, .unknown:
                if !strongSelf.routeChangeObservingService.hasHeadphones() {
                    strongSelf.pause()
                }
            default:
                break
            }
        }
    }
    
    private func startConfiguringAutomaticWaitingBehaviorService() {
        configuringAutomaticWaitingBehaviorService.onChangeTimeControlStatus = { [weak self] status in
            guard let strongSelf = self,
                  status == .waitingToPlayAtSpecifiedRate,
                  let reasonForWaitingToPlay = strongSelf.manager.player.reasonForWaitingToPlay else { return }
            
            switch reasonForWaitingToPlay {
            case .noItemToPlay:
                strongSelf.stop()
            default:
                strongSelf.clearCallBacks()
                let controller = AKBufferingState(manager: strongSelf.manager,
                                                  playerItemAssetKeysObservingService: strongSelf.playerItemAssetKeysObservingService)
                strongSelf.manager.change(controller)
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
    
    private func setPlaybackInfo() {
        manager.setNowPlayingPlaybackInfo()
    }
}
