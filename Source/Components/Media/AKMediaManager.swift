//
//  AKMediaManager.swift
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

open class AKMediaManager: NSObject, AKMediaManagerProtocol {
    
    // MARK: - Properties
    
    public unowned let media: AKPlayable
    
    public var asset: AVURLAsset? {
        return playerItemInitService.asset
    }
    
    public var playerItem: AVPlayerItem? {
        return playerItemInitService.playerItem
    }
    
    public var error: AKPlayerError?
    
    public private(set) var state: AKPlayableState = .idle {
        didSet {
            stateSubject.send(state)
            media.delegate?.akMedia(media,
                                    didChangedState: state)
        }
    }
    
    public var statePublisher: AnyPublisher<AKPlayableState, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    public var didPlayToEndTimePublisher: AnyPublisher<CMTime, Never> {
        return playerItemNotificationsObserver.didPlayToEndTimePublisher
    }
    
    public var failedToPlayToEndTimePublisher: AnyPublisher<AKPlayerError, Never> {
        return playerItemNotificationsObserver.failedToPlayToEndTimePublisher
    }
    
    public var playbackStalledPublisher: AnyPublisher<Void, Never> {
        return playerItemNotificationsObserver.playbackStalledPublisher
    }
    
    public var timeJumpedPublisher: AnyPublisher<Void, Never> {
        return playerItemNotificationsObserver.timeJumpedPublisher
    }
    
    public var mediaSelectionDidChangePublisher: AnyPublisher<Void, Never> {
        return playerItemNotificationsObserver.mediaSelectionDidChangePublisher
    }
    
    public var recommendedTimeOffsetFromLiveDidChangePublisher: AnyPublisher<CMTime, Never> {
        return playerItemNotificationsObserver.recommendedTimeOffsetFromLiveDidChangePublisher
    }
    
    public var playbackLikelyToKeepUpPublisher: AnyPublisher<Bool, Never> {
        return playerItemBufferingStatusObserver.playbackLikelyToKeepUpPublisher
    }
    
    public var playbackBufferFullPublisher: AnyPublisher<Bool, Never> {
        return playerItemBufferingStatusObserver.playbackBufferFullPublisher
    }
    
    public var playbackBufferEmptyPublisher: AnyPublisher<Bool, Never> {
        return playerItemBufferingStatusObserver.playbackBufferEmptyPublisher
    }
    
    private let stateSubject = PassthroughSubject<AKPlayableState, Never>()
    
    private var playerItemInitService: AKPlayerItemInitServiceProtocol!
    
    private var playerItemReadinessObserver: AKPlayerItemReadinessObserverProtocol!
    
    private var playerItemTracksObserverProtocol: AKPlayerItemTracksObserverProtocol!
    
    private var playbackCapabilitiesObserver: AKPlaybackCapabilitiesObserverProtocol!
    
    private var steppingThroughMediaObserver: AKSteppingThroughMediaObserverProtocol!
    
    private var seekingThroughMediaService: AKSeekingThroughMediaServiceProtocol!
    
    private var playerItemTimingInformationObserver: AKPlayerItemTimingInformationObserverProtocol!
    
    private var playerItemAvailableTimeRangesObserver: AKPlayerItemTimeRangesObserver!
    
    private var playerItemTracksObserver: AKPlayerItemTracksObserverProtocol!
    
    private var playerItemPresentationObserver: AKPlayerItemPresentationObserverProtocol!
    
    private var playerItemNotificationsObserver: AKPlayerItemNotificationsObserverProtocol!
    
    private var playerItemBufferingStatusObserver: AKPlayerItemBufferingStatusObserverProtocol!
    
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(media: AKPlayable) {
        self.media = media
        playerItemInitService = AKPlayerItemInitService(with: media)
    }
    
    deinit {
        stopPlayerItemReadinessObserver()
        stopPlayerItemAssetKeysObserver()
        print("Deinit called from AKMediaManager 👌🏼")
    }
    
    open func createAsset() {
        assert(state.isIdle
               || state.isFailed,
               "This function can only be called if the media is idle or has encountered an error.")
        self.error = nil
        playerItemInitService.createAsset()
        state = .assetLoaded
    }
    
    open func fetchAssetPropertiesValues() async throws {
        assert(state.isAssetLoaded,
               "This function requires the asset to be loaded first.")
        do {
            try await playerItemInitService.fetchAssetPropertiesValues()
        } catch {
            throw error
        }
    }
    
    open func validateAssetPlayability() async throws {
        assert(state.isAssetLoaded,
               "This function requires the asset to be loaded first.")
        do {
            try await playerItemInitService.validateAssetPlayability()
        } catch {
            throw error
        }
    }
    
    open func createPlayerItemFromAsset() {
        assert(state.isAssetLoaded,
               "This function requires the asset to be loaded first.")
        self.error = nil
        playerItemInitService.createPlayerItemFromAsset()
        initializeObservers(with: playerItem!)
        state = .playerItemLoaded
    }
    
    open func abortAssetInitialization() {
        playerItemInitService?.abortAssetInitialization()
    }
    
    open func startPlayerItemReadinessObserver() {
        guard state.isPlayerItemLoaded
                || state.isReadyToPlay else { return }
        playerItemReadinessObserver.startObserving()
    }
    
    open func stopPlayerItemReadinessObserver() {
        playerItemReadinessObserver?.stopObserving()
    }
    
    open func startPlayerItemAssetKeysObserver() {
        guard state.isPlayerItemLoaded
                || state.isReadyToPlay else { return }
        
        startObservingPlayerItemProperties()
        
        steppingThroughMediaObserver.startObserving()
        playbackCapabilitiesObserver.startObserving()
        playerItemTimingInformationObserver.startObserving()
        playerItemAvailableTimeRangesObserver.startObserving()
        playerItemTracksObserver.startObserving()
        playerItemPresentationObserver.startObserving()
        playerItemNotificationsObserver.startObserving()
        playerItemBufferingStatusObserver.startObserving()
    }
    
    open func stopPlayerItemAssetKeysObserver() {
        steppingThroughMediaObserver?.stopObserving()
        playbackCapabilitiesObserver?.stopObserving()
        playerItemTimingInformationObserver?.stopObserving()
        playerItemAvailableTimeRangesObserver?.stopObserving()
        playerItemTracksObserver?.stopObserving()
        playerItemPresentationObserver?.stopObserving()
        playerItemNotificationsObserver?.stopObserving()
        playerItemBufferingStatusObserver?.stopObserving()
    }
    
    open func canStep(by count: Int) -> Bool {
        guard state.isPlayerItemLoaded || state.isReadyToPlay else { return false }
        var isForward: Bool { return count.signum() == 1 }
        return isForward ? playerItem!.canStepForward : playerItem!.canStepBackward
    }
    
    open func canPlay(at rate: AKPlaybackRate) -> Bool {
        guard state.isPlayerItemLoaded || state.isReadyToPlay else { return false }
        switch rate.rate {
        case 0.0...:
            switch rate.rate {
            case 2.0...:
                return playerItem!.canPlayFastForward
            case 1.0..<2.0:
                return true
            case 0.0..<1.0:
                return playerItem!.canPlaySlowForward
            default:
                return false
            }
        case ..<0.0:
            switch rate.rate {
            case -1.0:
                return playerItem!.canPlayReverse
            case -1.0..<0.0:
                return playerItem!.canPlaySlowReverse
            case ..<(-1.0):
                return playerItem!.canPlayFastReverse
            default:
                return false
            }
        default:
            return false
        }
    }
    
    open func canSeek(to time: CMTime) -> (flag: Bool,
                                           reason: AKPlayerUnavailableCommandReason?) {
        guard state.isPlayerItemLoaded
                || state.isReadyToPlay else {
            if state.isIdle
                || state.isFailed {
                return (false, .loadMediaFirst)
            } else {
                return (false, .waitTillMediaLoaded)
            }
        }
        return seekingThroughMediaService.canSeek(to: time)
    }
    
    // MARK: - Additional Helper Functions
    
    private func initializeObservers(with playerItem: AVPlayerItem) {
        playerItemReadinessObserver = AKPlayerItemReadinessObserver(with: playerItem)
        playerItemTracksObserverProtocol = AKPlayerItemTracksObserver(with: playerItem)
        steppingThroughMediaObserver = AKSteppingThroughMediaObserver(with: playerItem)
        playbackCapabilitiesObserver = AKPlaybackCapabilitiesObserver(with: playerItem)
        playerItemTimingInformationObserver = AKPlayerItemTimingInformationObserver(with: playerItem)
        playerItemAvailableTimeRangesObserver = AKPlayerItemTimeRangesObserver(with: playerItem)
        playerItemTracksObserver = AKPlayerItemTracksObserver(with: playerItem)
        playerItemPresentationObserver = AKPlayerItemPresentationObserver(with: playerItem)
        seekingThroughMediaService = AKSeekingThroughMediaService(with: playerItem)
        playerItemNotificationsObserver = AKPlayerItemNotificationsObserver(playerItem: playerItem)
        playerItemBufferingStatusObserver = AKPlayerItemBufferingStatusObserver(with: playerItem)
    }
    
    private func startObservingPlayerItemProperties() {
        playerItemReadinessObserver.statusPublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] result in
                switch result.status {
                case .readyToPlay:
                    state = .readyToPlay
                case .failed:
                    self.error = result.error
                    state = .failed
                default: break
                }
            }
            .store(in: &cancellables)
        
        playerItemTracksObserver.tracksPublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] tracks in
                media.delegate?.akMedia(media,
                                        didChangeTracks: tracks)
            }
            .store(in: &cancellables)
        
        steppingThroughMediaObserver.canStepForwardPublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] canStepForward in
                media.delegate?.akMedia(media,
                                        didChangeCanStepForwardStatus: canStepForward)
            }
            .store(in: &cancellables)
        
        steppingThroughMediaObserver.canStepBackwardPublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] canStepBackward in
                media.delegate?.akMedia(media,
                                        didChangeCanStepBackwardStatus: canStepBackward)
            }
            .store(in: &cancellables)
        
        playerItemPresentationObserver.presentationSizePublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] presentationSize in
                media.delegate?.akMedia(media,
                                        didChangePresentationSize: presentationSize)
            }
            .store(in: &cancellables)
        
        playerItemAvailableTimeRangesObserver.loadedTimeRangesPublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] loadedTimeRanges in
                media.delegate?.akMedia(media,
                                        didChangeLoadedTimeRanges: loadedTimeRanges)
            }
            .store(in: &cancellables)
        
        playerItemAvailableTimeRangesObserver.seekableTimeRangesPublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] seekableTimeRanges in
                media.delegate?.akMedia(media,
                                        didChangeSeekableTimeRanges: seekableTimeRanges)
            }
            .store(in: &cancellables)
        
        playerItemTimingInformationObserver.durationPublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] duration in
                media.delegate?.akMedia(media,
                                        didChangeItemDuration: duration)
            }
            .store(in: &cancellables)
        
        playerItemTimingInformationObserver.timebasePublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] timebase in
                media.delegate?.akMedia(media,
                                        didChangeTimebase: timebase)
            }
            .store(in: &cancellables)
        
        playbackCapabilitiesObserver.canPlayReversePublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] canPlayReverse in
                media.delegate?.akMedia(media,
                                        didChangeCanPlayReverseStatus: canPlayReverse)
            }
            .store(in: &cancellables)
        
        playbackCapabilitiesObserver.canPlayFastForwardPublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] canPlayFastForward in
                media.delegate?.akMedia(media,
                                        didChangeCanPlayFastForwardStatus: canPlayFastForward)
            }
            .store(in: &cancellables)
        
        playbackCapabilitiesObserver.canPlayFastReversePublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] canPlayFastReverse in
                media.delegate?.akMedia(media,
                                        didChangeCanPlayFastReverseStatus: canPlayFastReverse)
            }
            .store(in: &cancellables)
        
        playbackCapabilitiesObserver.canPlaySlowForwardPublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] canPlaySlowForward in
                media.delegate?.akMedia(media,
                                        didChangeCanPlaySlowForwardStatus: canPlaySlowForward)
            }
            .store(in: &cancellables)
        
        playbackCapabilitiesObserver.canPlaySlowReversePublisher
            .subscribe(on: DispatchQueue.global(qos: .background))
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] canPlaySlowReverse in
                media.delegate?.akMedia(media,
                                        didChangeCanPlaySlowReverseStatus: canPlaySlowReverse)
            }
            .store(in: &cancellables)
    }
}
