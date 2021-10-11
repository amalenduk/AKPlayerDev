//
//  AKLoadingState.swift
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

final class AKLoadingState: AKPlayerStateControllable {
    
    // MARK: - Properties
    
    unowned let manager: AKPlayerManagerProtocol
    
    let state: AKPlayerState = .loading
    
    private let media: AKPlayable
    
    let autoPlay: Bool
    
    private let position: CMTime?
    
    private var playerItemInitializationController: AKPlayerItemInitializationController!
    
    private var determiningPlayerItemStatusService: AKDeterminingPlayerItemStatusService!
    
    // MARK: - Init
    
    init(manager: AKPlayerManagerProtocol,
         media: AKPlayable,
         autoPlay: Bool = false,
         at position: CMTime? = nil) {
        AKPlayerLogger.shared.log(message: "Init",
                                  domain: .lifecycleState)
        self.manager = manager
        self.media = media
        self.autoPlay = autoPlay
        self.position = position
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit",
                                  domain: .lifecycleState)
    }
    
    func stateDidChange() {
        setMetadata()
        resetPlayer()
        manager.delegate?.playerManager(didCurrentMediaChange: media)
        manager.plugins?.forEach({$0.playerPlugin(willStartLoading: media)})
        createPlayerItem(with: media)
        manager.plugins?.forEach({$0.playerPlugin(didStartLoading: media)})
    }
    
    // MARK: - Commands
    
    func load(media: AKPlayable) {
        cancelLoading()
        let controller = AKLoadingState(manager: manager,
                                        media: media)
        manager.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool) {
        cancelLoading()
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay)
        manager.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: CMTime) {
        cancelLoading()
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay,
                                        at: position)
        manager.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: Double) {
        cancelLoading()
        let controller = AKLoadingState(manager: manager,
                                        media: media,
                                        autoPlay: autoPlay,
                                        at: CMTime(seconds: position,
                                                   preferredTimescale: manager.configuration.preferredTimescale))
        manager.change(controller)
    }
    
    func play() {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
    }
    
    func pause() {
        cancelLoading()
        let controller = AKPausedState(manager: manager,
                                       playerItemAssetKeysObservingService: nil)
        manager.change(controller)
    }
    
    func togglePlayPause() {
        pause()
    }
    
    func stop() {
        cancelLoading()
        let controller = AKStoppedState(manager: manager,
                                        playerItemAssetKeysObservingService: nil)
        manager.change(controller)
    }
    
    func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: @escaping (Bool) -> Void) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
    }
    
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(to time: CMTime) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
    }
    
    func seek(to time: Double,
              completionHandler: @escaping (Bool) -> Void) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(to time: Double) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
    }
    
    func seek(to date: Date, completionHandler: @escaping (Bool) -> Void) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
    }
    
    func seek(to date: Date) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
    }
    
    func seek(offset: Double) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
    }
    
    func seek(offset: Double,
              completionHandler: @escaping (Bool) -> Void) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(toPercentage value: Double,
              completionHandler: @escaping (Bool) -> Void) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(toPercentage value: Double) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
    }
    
    func step(byCount stepCount: Int) {
        AKPlayerLogger.shared.log(message: AKPlayerUnavailableActionReason.waitTillMediaLoaded.description,
                                  domain: .unavailableCommand)
        manager.delegate?.playerManager(unavailableAction: .waitTillMediaLoaded)
    }
    
    // MARK: - Additional Helper Functions
    
    private func createPlayerItem(with media: AKPlayable) {
        playerItemInitializationController = AKPlayerItemInitializationController(with: media,
                                                                            configuration: manager.configuration)
        playerItemInitializationController.onCompletedCreatingPlayerItem = { [unowned self] result in
            switch result {
            case .success(let item):
                manager.player.replaceCurrentItem(with: item)
                startObservingStatus(for: item)
            case .failure(let error):
                assetFailedToPrepareForPlayback(with: error)
            }
        }
        
        playerItemInitializationController.startInitialization()
    }
    
    private func startObservingStatus(for item: AVPlayerItem) {
        determiningPlayerItemStatusService = AKDeterminingPlayerItemStatusService(playerItem: item) { [unowned self] (status) in
            switch status {
            case .unknown:
                AKPlayerLogger.shared.log(message: "AVPlayerItem.status: 'unknown'", domain: .state)
            case .readyToPlay:
                becameReadyToPlay()
            case .failed:
                assetFailedToPrepareForPlayback(with: .loadingFailed(error: item.error!))
            @unknown default:
                assertionFailure()
            }
        }
    }
    
    private func becameReadyToPlay() {
        let controller = AKLoadedState(manager: manager,
                                       autoPlay: autoPlay,
                                       at: position)
        manager.change(controller)
    }
    
    private func cancelLoading() {
        if let playerItemInitializationController = playerItemInitializationController {
            playerItemInitializationController.cancelLoading(clearCallBacks: true)
        }
        if let determiningPlayerItemStatusService = determiningPlayerItemStatusService {
            determiningPlayerItemStatusService.stop()
        }
        manager.currentItem?.cancelPendingSeeks()
        manager.player.replaceCurrentItem(with: nil)
    }
    
    private func resetPlayer() {
        /*
         Loading a clip media from playing state, play automatically the new clip media
         Ensure player will play only when we ask
         */
        manager.player.pause()
        
        /*
         It seems to be a good idea to reset player current item
         Fix side effect when coming from failed state
         */
        manager.player.replaceCurrentItem(with: nil)
        
        cancelLoading()
    }
    
    private func setMetadata() {
        manager.playerNowPlayingMetadataService?.clearNowPlayingPlaybackInfo()
        manager.setNowPlayingMetadata()
    }
    
    // MARK: - Error Handling - Preparing Assets for Playback Failed
    
    /* --------------------------------------------------------------
     **  Called when an asset fails to prepare for playback for any of
     **  the following reasons:
     **
     **  1) values of asset keys did not load successfully,
     **  2) the asset keys did load successfully, but the asset is not
     **     playable
     **  3) the item did not become ready to play.
     ** ----------------------------------------------------------- */
    private func assetFailedToPrepareForPlayback(with error: AKPlayerError) {
        AKPlayerLogger.shared.log(message: error.localizedDescription,
                                  domain: .error)
        let controller = AKFailedState(manager: manager,
                                       error: error)
        manager.change(controller)
    }
}
