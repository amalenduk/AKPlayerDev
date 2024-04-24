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
    
    public private(set) var asset: AVURLAsset?
    
    public private(set) var playerItem: AVPlayerItem?
    
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
    
    private let stateSubject = PassthroughSubject<AKPlayableState, Never>()
    
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
    
    open func createAsset() -> AVURLAsset {
        assert(state.isIdle
               || state.isFailed,
               "This function can only be called if the media is idle or has encountered an error.")
        self.error = nil
        let asset = playerItemInitService.createAsset()
        self.asset = asset
        state = .assetLoaded
        return asset
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
    
    open func createPlayerItemFromAsset() -> AVPlayerItem {
        assert(state.isAssetLoaded,
               "This function requires the asset to be loaded first.")
        self.error = nil
        let playerItem = playerItemInitService!.createPlayerItemFromAsset()
        initializeObservers(with: playerItem)
        self.playerItem = playerItem
        state = .playerItemLoaded
        return playerItem
    }
    
    open func abortAssetInitialization() {
        playerItemInitService?.abortAssetInitialization()
    }
    
    open func startPlayerItemReadinessObserver() {
        guard state.isPlayerItemLoaded || state.isReadyToPlay else { return }
        playerItemReadinessObserver.startObserving()
    }
    
    open func stopPlayerItemReadinessObserver() {
        playerItemReadinessObserver?.stopObserving()
    }
    
    open func startPlayerItemAssetKeysObserver() {
        guard state.isPlayerItemLoaded || state.isReadyToPlay else { return }
        
        steppingThroughMediaObserver.startObserving()
        playbackCapabilitiesObserver.startObserving()
        playerItemTimingInformationObserver.startObserving()
        playerItemAvailableTimeRangesObserver.startObserving()
        playerItemTracksObserver.startObserving()
        playerItemPresentationObserver.startObserving()
    }
    
    open func stopPlayerItemAssetKeysObserver() {
        steppingThroughMediaObserver?.stopObserving()
        playbackCapabilitiesObserver?.stopObserving()
        playerItemTimingInformationObserver?.stopObserving()
        playerItemAvailableTimeRangesObserver?.stopObserving()
        playerItemTracksObserver?.stopObserving()
        playerItemPresentationObserver?.stopObserving()
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
        guard state.isPlayerItemLoaded || state.isReadyToPlay else {
            if state.isIdle || state.isFailed {
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
        
        playerItemReadinessObserver.delegate = self
        playerItemTracksObserverProtocol.delegate = self
        steppingThroughMediaObserver.delegate = self
        playbackCapabilitiesObserver.delegate = self
        playerItemTimingInformationObserver.delegate = self
        playerItemAvailableTimeRangesObserver.delegate = self
        playerItemTracksObserver.delegate = self
        playerItemPresentationObserver.delegate = self
    }
}

// MARK: - AKPlayerItemReadinessObserverDelegate

extension AKMediaManager: AKPlayerItemReadinessObserverDelegate {
    public func playerItemReadinessObserver(_ observer: AKPlayerItemReadinessObserverProtocol,
                                            didChangeStatusTo status: AVPlayerItem.Status,
                                            for playerItem: AVPlayerItem,
                                            with error: AKPlayerError?) {
        switch status {
        case .readyToPlay:
            state = .readyToPlay
        case .failed:
            self.error = error
            state = .failed
        default: break
        }
    }
}

// MARK: - AKPlayerItemTracksObserverDelegate

extension AKMediaManager: AKPlayerItemTracksObserverDelegate {
    public func playerItemTracksObserver(_ observer: AKPlayerItemTracksObserverProtocol,
                                         didLoad tracks: [AVPlayerItemTrack],
                                         for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media,
                                didChangeTracks: tracks)
    }
}

// MARK: - AKPlaybackCapabilitiesObserverDelegate

extension AKMediaManager: AKPlaybackCapabilitiesObserverDelegate {
    
    public func playbackCapabilitiesObserver(_ observer: AKPlaybackCapabilitiesObserverProtocol,
                                             didChangeCanPlayReverseStatusTo canPlayReverse: Bool,
                                             for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media,
                                didChangeCanPlayReverseStatus: canPlayReverse)
    }
    
    public func playbackCapabilitiesObserver(_ observer: AKPlaybackCapabilitiesObserverProtocol,
                                             didChangeCanPlayFastForwardStatusTo canPlayFastForward: Bool,
                                             for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media,
                                didChangeCanPlayFastForwardStatus: canPlayFastForward)
    }
    
    public func playbackCapabilitiesObserver(_ observer: AKPlaybackCapabilitiesObserverProtocol,
                                             didChangeCanPlayFastReverseStatusTo canPlayFastReverse: Bool,
                                             for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media,
                                didChangeCanPlayFastReverseStatus: canPlayFastReverse)
    }
    
    public func playbackCapabilitiesObserver(_ observer: AKPlaybackCapabilitiesObserverProtocol,
                                             didChangeCanPlaySlowForwardStatusTo canPlaySlowForward: Bool,
                                             for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media,
                                didChangeCanPlaySlowForwardStatus: canPlaySlowForward)
    }
    
    public func playbackCapabilitiesObserver(_ observer: AKPlaybackCapabilitiesObserverProtocol,
                                             didChangeCanPlaySlowReverseStatusTo canPlaySlowReverse: Bool,
                                             for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media,
                                didChangeCanPlaySlowReverseStatus: canPlaySlowReverse)
    }
}

// MARK: - AKSteppingThroughMediaObserverDelegate

extension AKMediaManager: AKSteppingThroughMediaObserverDelegate {
    
    public func steppingThroughMediaObserver(_ observer: AKSteppingThroughMediaObserverProtocol,
                                             didChangeCanStepForwardStatusTo canStepForward: Bool,
                                             for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media, didChangeCanStepForwardStatus: canStepForward)
    }
    
    public func steppingThroughMediaObserver(_ observer: AKSteppingThroughMediaObserverProtocol,
                                             didChangeCanStepBackwardStatusTo canStepBackward: Bool,
                                             for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media, didChangeCanStepBackwardStatus: canStepBackward)
    }
}

// MARK: - AKPlayerItemTimingInformationObserverDelegate

extension AKMediaManager: AKPlayerItemTimingInformationObserverDelegate {
    
    public func playerItemTimingInformationObserver(_ observer: AKPlayerItemTimingInformationObserverProtocol,
                                                    didChangeDurationTo duration: CMTime,
                                                    for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media,
                                didChangeItemDuration: duration)
    }
    
    public func accessingTimingInformationObserver(_ observer: AKPlayerItemTimingInformationObserverProtocol,
                                                   didChangeTimebaseTo timebase: CMTimebase?,
                                                   for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media,
                                didChangeTimebase: timebase)
    }
}

// MARK: - AKPlayerItemTimeRangesObserverDelegate

extension AKMediaManager: AKPlayerItemTimeRangesObserverDelegate {
    
    public func playerItemTimeRangesObserver(_ observer: AKPlayerItemTimeRangesObserverProtocol,
                                             didChangeLoadedTimeRangesTo loadedTimeRanges: [NSValue],
                                             for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media,
                                didChangeLoadedTimeRanges: loadedTimeRanges)
    }
    
    public func playerItemTimeRangesObserver(_ observer: AKPlayerItemTimeRangesObserverProtocol,
                                             didChangeSeekableTimeRangesTo seekableTimeRanges: [NSValue],
                                             for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media, didChangeSeekableTimeRanges: seekableTimeRanges)
    }
}

// MARK: - AKPlayerItemPresentationObserverDelegate

extension AKMediaManager: AKPlayerItemPresentationObserverDelegate {
    
    public func playerItemPresentationObserver(_ observer: AKPlayerItemPresentationObserverProtocol,
                                               didChangePresentationSizeTo size: CGSize,
                                               for playerItem: AVPlayerItem) {
        media.delegate?.akMedia(media,
                                didChangePresentationSize: size)
    }
}
