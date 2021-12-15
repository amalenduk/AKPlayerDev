//
//  AKBufferingState.swift
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

final class AKBufferingState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned let manager: AKPlayerManagerProtocol
    
    let state: AKPlayerState = .buffering
    
    private var configuringAutomaticWaitingBehaviorService: AKConfiguringAutomaticWaitingBehaviorService!
    
    private var determiningBufferingStatusService: AKDeterminingBufferingStatusService!
    
    private var playerItemObservingNotificationsService: AKPlayerItemObservingNotificationsService!
    
    private var observingPlayerTimeService: AKObservingPlayerTimeService!
            
    private var playerItemAssetKeysObservingService: AKPlayerItemAssetKeysObservingServiceable!
    
    // MARK: - Init
    
    init(manager: AKPlayerManagerProtocol,
         playerItemAssetKeysObservingService: AKPlayerItemAssetKeysObservingServiceable) {
        AKPlayerLogger.shared.log(message: "Init",
                                  domain: .lifecycleState)
        self.manager = manager
        self.playerItemAssetKeysObservingService = playerItemAssetKeysObservingService
        
        guard let playerItem = manager.currentItem else { assertionFailure("Player item should available"); return }
        
        configuringAutomaticWaitingBehaviorService = AKConfiguringAutomaticWaitingBehaviorService(with: manager.player,
                                                                                                  configuration: manager.configuration)
        
        determiningBufferingStatusService = AKDeterminingBufferingStatusService(with: playerItem,
                                                                                configuration: manager.configuration)
        
        playerItemObservingNotificationsService = AKPlayerItemObservingNotificationsService(playerItem: playerItem)
        
        observingPlayerTimeService = AKObservingPlayerTimeService(with: manager.player,
                                                                  configuration: manager.configuration)
        }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit",
                                  domain: .lifecycleState)
    }
    
    func stateDidChange() {
        guard let media = manager.currentMedia else { assertionFailure("Media and Current item should available"); return }
        manager.plugins?.forEach({$0.playerPlugin(didStartBuffering: media)})
        startConfiguringAutomaticWaitingBehaviorService()
        startDeterminingBufferingStatusService()
        startPlayerItemObservingNotificationsService()
        startObservingPlayerTimeService()
        setPlaybackInfo()
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
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.alreadyTryingToPlay.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .alreadyTryingToPlay)
    }
    
    func pause() {
        clearCallBacks()
        let controller = AKPausedState(manager: manager,
                                       playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
        change(controller)
    }
    
    func togglePlayPause() {
        pause()
    }
    
    func stop() {
        clearCallBacks()
        let controller = AKStoppedState(manager: manager,
                                        playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
        change(controller)
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
    
    private func startConfiguringAutomaticWaitingBehaviorService() {
        configuringAutomaticWaitingBehaviorService.onChangeTimeControlStatus = { [unowned self] status in
            guard status == .waitingToPlayAtSpecifiedRate,
                  let reasonForWaitingToPlay = manager.player.reasonForWaitingToPlay,
                  reasonForWaitingToPlay == .noItemToPlay else { return }
            stop()
        }
    }
    
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
            change(controller)
        }
        
        playerItemObservingNotificationsService.onPlayerItemFailedToPlayToEndTime = { [unowned self] in
            guard manager.player.timeControlStatus == .waitingToPlayAtSpecifiedRate,
                  let reasonForWaitingToPlay = manager.player.reasonForWaitingToPlay else {
                clearCallBacks()
                let controller = AKFailedState(manager: manager,
                                               error: .itemFailedToPlayToEndTime)
                return change(controller)
            }
            
            switch reasonForWaitingToPlay {
            case .evaluatingBufferingRate, .toMinimizeStalls:
                clearCallBacks()
                let controller = AKWaitingForNetworkState(manager: manager,
                                                          playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
                change(controller)
            case .noItemToPlay:
                stop()
            default:
                assertionFailure("Sould be not here \(reasonForWaitingToPlay.rawValue)")
            }
        }
        
        playerItemObservingNotificationsService.onPlayerItemPlaybackStalled = { [unowned self] in
            clearCallBacks()
            let controller = AKWaitingForNetworkState(manager: manager,
                                                      playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
            change(controller)
        }
    }
    
    private func startDeterminingBufferingStatusService() {
        determiningBufferingStatusService.startObservationWithTimeInterval()
        determiningBufferingStatusService.onChangePlaybackBufferEmptyStatus = { [unowned self] flag in
            if flag {
                clearCallBacks()
                let controller = AKWaitingForNetworkState(manager: manager,
                                                          playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
                change(controller)
            }
        }
        
        determiningBufferingStatusService.onChangePlaybackBufferFullStatus = { [unowned self] flag in
            if flag {
                clearCallBacks()
                let controller = AKPlayingState(manager: manager,
                                                playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
                change(controller)
            }
        }
        
        determiningBufferingStatusService.onChangePlaybackLikelyToKeepUpStatus = { [unowned self] flag in
            if flag {
                clearCallBacks()
                let controller = AKPlayingState(manager: manager,
                                                playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
                change(controller)
            }
        }
        
        determiningBufferingStatusService.onChangePlaybackBufferStatus = { [unowned self] flag in
            if flag {
                clearCallBacks()
                let controller = AKPlayingState(manager: manager,
                                                playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
                change(controller)
            }else {
                clearCallBacks()
                let controller = AKWaitingForNetworkState(manager: manager,
                                                          playerItemAssetKeysObservingService: playerItemAssetKeysObservingService)
                change(controller)
            }
        }
    }
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        determiningBufferingStatusService.stop(clearCallBacks: true)
        guard let media = manager.currentMedia else { assertionFailure("Media and Current item should available"); return }
        if controller is AKPlayingState { manager.plugins?.forEach({$0.playerPlugin(didStartPlaying: media,
                                                                                    at: manager.currentTime)})}
        manager.change(controller)
    }
    
    func playCommand() {
        guard let currentItem = manager.currentItem else { assertionFailure("Current item should available"); return }
        AKDeterminingPlaybackCapabilitiesEventProducer.itemCanBePlayed(at: manager.rate,
                                                                 for: currentItem) ? (manager.player.rate = manager.rate.rate) : (manager.rate = .normal)
    }
    
    private func startObservingPlayerTimeService() {
        observingPlayerTimeService.onChangePeriodicTime = { [unowned self] time in
            setPlaybackInfo()
            manager.delegate?.playerManager(didCurrentTimeChange: time)
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

extension AKBufferingState {
    
    func handle(_ event: AKEvent, generetedBy eventProducer: AKEventProducer) {
        
    }
}
