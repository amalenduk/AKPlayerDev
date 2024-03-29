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
import Combine

final class AKLoadingState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned let playerController: AKPlayerControllerProtocol
    
    let state: AKPlayerState = .loading
    
    private let media: AKPlayable
    
    private(set) var autoPlay: Bool
    
    private let position: CMTime?
    
    private var rate: AKPlaybackRate?
    
    private var task: Task<Void, Never>?
    
    private var cancellable: AnyCancellable?
    
    private var isMediaInitializing: Bool = false
    
    // MARK: - Init
    
    init(playerController: AKPlayerControllerProtocol,
         media: AKPlayable,
         autoPlay: Bool = false,
         position: CMTime? = nil,
         rate: AKPlaybackRate? = nil) {
        self.playerController = playerController
        self.media = media
        self.autoPlay = autoPlay
        self.position = position
        self.rate = rate
    }
    
    deinit { print("Deinit called from ", #file) }
    
    func didChangeState() {
        resetPlayer()
        playerController.delegate?.playerController(playerController,
                                                    didChangeMediaTo: media)
        cancellable = media.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] state in
                handleMediaSteChange(with: state)
            }
    }
    
    // MARK: - Commands
    
    func load(media: AKPlayable) {
        cancelLoading()
        let controller = AKLoadingState(playerController: playerController,
                                        media: media)
        playerController.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool) {
        cancelLoading()
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay)
        playerController.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: CMTime) {
        cancelLoading()
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: position)
        playerController.change(controller)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: Double) {
        cancelLoading()
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: CMTime(seconds: position,
                                                         preferredTimescale: playerController.configuration.preferredTimeScale))
        playerController.change(controller)
    }
    
    func play() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func play(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func pause() {
        switch media.state {
        case .loading, .loaded, .readyToPlay:
            autoPlay = false
        case .failed:
            failedToPrepareForPlayback(with: media.error!)
        default: break
        }
    }
    
    func togglePlayPause() {
        pause()
    }
    
    func stop() {
        cancelLoading()
        stopPlayerItemObservers()
        let controller = AKStoppedState(playerController: playerController)
        playerController.change(controller)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(to time: CMTime) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func seek(to time: Double,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(to time: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func seek(to date: Date,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(to date: Date) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func seek(toOffset offset: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func seek(toOffset offset: Double,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(toPercentage percentage: Double,
              completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    func seek(toPercentage percentage: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func step(by count: Int) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func fastForward() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func fastForward(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func rewind(){
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    func rewind(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    // MARK: - Additional Helper Functions
    
    private func handleMediaSteChange(with state: AKPlayableState) {
        switch state {
        case .idle: createPlayerItem(with: media)
        case .loading: break
        case .loaded: playerItemLoaded()
        case .readyToPlay: becameReadyToPlay()
        case .failed:
            if isMediaInitializing {
                failedToPrepareForPlayback(with: media.error!)
            } else {
                createPlayerItem(with: media)
            }
        }
    }
    
    private func createPlayerItem(with media: AKPlayable) {
        isMediaInitializing = true
        task = Task { [weak self] in
            guard let self else { return }
            do {
                try await media.initializePlayerItem()
            } catch let error as AKPlayerError {
                print(Task.isCancelled)
                guard !Task.isCancelled else { return }
                failedToPrepareForPlayback(with: error)
            } catch (let error) {
                guard !Task.isCancelled else { return }
                if let err = error as? URLError,
                   err.code  == URLError.Code.notConnectedToInternet {
                    failedToPrepareForPlayback(with: AKPlayerError.assetLoadingFailed(reason: .notConnectedToInternet(error: err)))
                } else {
                    failedToPrepareForPlayback(with: AKPlayerError.assetLoadingFailed(reason: .assetInitializationFailed(error: error)))
                }
            }
        }
    }
    
    private func playerItemLoaded() {
        /*
         Setup some key-value observers on the player to update the
         app's user interface elements.
         */
        media.startPlayerItemAssetKeysObserver()
        /*
         You should call this method before associating the player item with the player to make
         sure you capture all state changes to the item’s status.
         */
        media.startPlayerItemReadinessObserver()
        playerController.player.replaceCurrentItem(with: media.playerItem!)
    }
    
    private func becameReadyToPlay() {
        let controller = AKLoadedState(playerController: playerController,
                                       autoPlay: autoPlay,
                                       position: position)
        playerController.change(controller)
    }
    
    private func cancelLoading() {
        task?.cancel()
        cancellable?.cancel()
        media.cancelInitialization()
    }
    
    private func stopPlayerItemObservers() {
        media.stopPlayerItemReadinessObserver()
        media.stopPlayerItemAssetKeysObserver()
    }
    
    private func resetPlayer() {
        /*
         Loading a clip media from playing state, play automatically the new clip media
         Ensure player will play only when we ask
         */
        if playerController.player.timeControlStatus == .playing
            || playerController.player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            playerController.player.pause()
        }
        
        /*
         It seems to be a good idea to reset player current item
         Fix side effect when coming from failed state
         */
        playerController.currentItem?.cancelPendingSeeks()
        playerController.player.replaceCurrentItem(with: nil)
        
        cancelLoading()
        stopPlayerItemObservers()
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
    private func failedToPrepareForPlayback(with error: AKPlayerError) {
        cancelLoading()
        let controller = AKFailedState(playerController: playerController, error: error)
        playerController.change(controller)
    }
}
