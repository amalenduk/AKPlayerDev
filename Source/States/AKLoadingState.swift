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

public class AKLoadingState: AKPlayerStateControllerProtocol {
    
    // MARK: - Properties
    
    unowned public let playerController: AKPlayerControllerProtocol
    
    public let state: AKPlayerState = .loading
    
    private let media: AKPlayable
    
    public private(set) var autoPlay: Bool
    
    private let position: CMTime?
    
    private var rate: AKPlaybackRate?
    
    private var isCancelled: Bool = false
    
    private var task: Task<Void, Never>?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol,
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
    
    deinit { }
    
    public func didChangeState() {
        resetPlayer()
        playerController.delegate?.playerController(playerController,
                                                    didChangeMediaTo: media)
        
        media.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] state in
                handleMediaSteChange(with: state)
            }.store(in: &cancellables)
        
        handleMediaSteChange(with: media.state)
    }
    
    // MARK: - Commands
    
    public func load(media: AKPlayable) {
        abortAssetInitialization()
        let controller = AKLoadingState(playerController: playerController,
                                        media: media)
        change(controller)
    }
    
    public func load(media: AKPlayable,
                     autoPlay: Bool) {
        abortAssetInitialization()
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay)
        change(controller)
    }
    
    public func load(media: AKPlayable,
                     autoPlay: Bool,
                     at position: CMTime) {
        abortAssetInitialization()
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: position)
        change(controller)
    }
    
    public func load(media: AKPlayable,
                     autoPlay: Bool,
                     at position: Double) {
        abortAssetInitialization()
        let time = CMTime(seconds: position,
                          preferredTimescale: playerController.configuration.preferredTimeScale)
        let controller = AKLoadingState(playerController: playerController,
                                        media: media,
                                        autoPlay: autoPlay,
                                        position: time)
        change(controller)
    }
    
    public func play() {
        autoPlay = true
    }
    
    public func play(at rate: AKPlaybackRate) {
        autoPlay = true
        self.rate = rate
    }
    
    public func pause() {
        guard !media.state.isFailed else {
            failedToPrepareForPlayback(with: media.error!)
            return
        }
        autoPlay = false
    }
    
    public func togglePlayPause() {
        if autoPlay {
            pause()
        } else {
            play()
        }
    }
    
    public func stop() {
        abortAssetInitialization()
        stopPlayerItemObservers()
        let controller = AKStoppedState(playerController: playerController)
        change(controller)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    public func seek(to time: CMTime,
                     toleranceBefore: CMTime,
                     toleranceAfter: CMTime) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    public func seek(to time: CMTime,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    public func seek(to time: CMTime) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    public func seek(to time: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    public func seek(to time: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    public func seek(to date: Date,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    public func seek(to date: Date) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    public func seek(toOffset offset: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    public func seek(toOffset offset: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    public func seek(toPercentage percentage: Double,
                     completionHandler: @escaping (Bool) -> Void) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
        completionHandler(false)
    }
    
    public func seek(toPercentage percentage: Double) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    public func step(by count: Int) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    public func fastForward() {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    public func fastForward(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    public func rewind(){
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    public func rewind(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    unavailableActionWith: .waitTillMediaLoaded)
    }
    
    // MARK: - Additional Helper Functions
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        playerController.change(controller)
    }
    
    private func handleMediaSteChange(with state: AKPlayableState) {
        switch state {
        case .idle:
            createAsset()
        case .assetLoaded:
            task = Task { [weak self] in
                guard let self else { return }
                await validateAssetPlayability()
                if Task.isCancelled { return }
                createPlayerItemFromAsset()
            }
        case .playerItemLoaded:
            playerItemLoaded()
        case .readyToPlay where !(playerController.player.currentItem == media.playerItem):
            playerItemLoaded()
        case .readyToPlay:
            becameReadyToPlay()
        case .failed:
            failedToPrepareForPlayback(with: media.error!)
        }
    }
    
    private func createAsset() {
        media.createAsset()
    }
    
    private func validateAssetPlayability() async {
        do {
            try await media.validateAssetPlayability()
        } catch {
            failedToPrepareForPlayback(with: error as! AKPlayerError)
        }
    }
    
    private func createPlayerItemFromAsset() {
        media.createPlayerItemFromAsset()
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
        playerController.playerStatusPublisher
            .prepend(playerController.player.status)
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [unowned self] status in
                switch status {
                case .readyToPlay:
                    let controller = AKLoadedState(playerController: playerController,
                                                   autoPlay: autoPlay,
                                                   position: position)
                    change(controller)
                case .failed:
                    let controller = AKFailedState(playerController: playerController,
                                                   error: .playerCanNoLongerPlay(error: playerController.player.error))
                    change(controller)
                default: break
                }
            }.store(in: &cancellables)
    }
    
    
    private func abortAssetInitialization() {
        isCancelled = true
        task?.cancel()
        cancellables.forEach({$0.cancel()})
        cancellables.removeAll()
        media.abortAssetInitialization()
    }
    
    private func stopPlayerItemObservers() {
        media.stopPlayerItemReadinessObserver()
        media.stopPlayerItemAssetKeysObserver()
    }
    
    private func resetPlayer() {
        if !(playerController.player.timeControlStatus == .paused) {
            playerController.player.pause()
        }
        
        /*
         It seems to be a good idea to reset player current item
         Fix side effect when coming from failed state
         */
        playerController.currentItem?.cancelPendingSeeks()
        playerController.player.replaceCurrentItem(with: nil)
        
        stopPlayerItemObservers()
    }
    
    // MARK: - Error Handling - Preparing Assets for Playback Failed
    
    private func failedToPrepareForPlayback(with error: AKPlayerError) {
        guard !isCancelled else { return }
        let controller = AKFailedState(playerController: playerController, error: error)
        change(controller)
    }
}
