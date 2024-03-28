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
    
    public private(set) var playerItem: AVPlayerItem?
    
    @Published public private(set) var state: AKPlayableState = .idle
    
    public var error: AKPlayerError?
    
    public var statePublisher: Published<AKPlayableState>.Publisher { $state }
    
    private var playerItemInitService: AKPlayerItemInitServiceProtocol!
    
    private var playerItemReadinessObserver: AKPlayerItemReadinessObserverProtocol!
    
    private var playerItemTracksObserverProtocol: AKPlayerItemTracksObserverProtocol!
    
    private var playbackCapabilitiesObserver: AKPlaybackCapabilitiesObserverProtocol!
    
    private var steppingThroughMediaObserver: AKSteppingThroughMediaObserverProtocol!
    
    private var playerItemTimingInformationObserver: AKPlayerItemTimingInformationObserverProtocol!
    
    private var playerItemAvailableTimeRangesObserver: AKPlayerItemTimeRangesObserver!
    
    private var playerItemTracksObserver: AKPlayerItemTracksObserverProtocol!
    
    private var playerItemPresentationObserver: AKPlayerItemPresentationObserverProtocol!
    
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
    
    open func initializePlayerItem() async throws {
        assert(state.isIdle || state.isFailed, "Unexpected media state: Media should be idle or in a failed state.")
        state = .loading
        do {
            playerItem = try await playerItemInitService.initialize()
            initializeObservers(with: playerItem!)
            error = nil
            state = .loaded
        } catch (let err) {
            error = err as? AKPlayerError
            state = .failed
            throw error!
        }
    }
    
    open func cancelInitialization() {
        playerItemInitService?.cancelInitialization()
    }
    
    open func startPlayerItemReadinessObserver() {
        guard state.isLoaded || state.isReadyToPlay else { return }
        playerItemReadinessObserver.startObserving()
    }
    
    open func stopPlayerItemReadinessObserver() {
        playerItemReadinessObserver?.stopObserving()
    }
    
    open func startPlayerItemAssetKeysObserver() {
        guard state.isLoaded || state.isReadyToPlay else { return }
        
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
        guard state.isLoaded || state.isReadyToPlay else { return false }
        return playerItem!.canStep(by: count)
    }
    
    open func canPlay(at rate: AKPlaybackRate) -> Bool {
        guard state.isLoaded || state.isReadyToPlay else { return false }
        return playerItem!.canPlay(at: rate)
    }
    
    open func canSeek(to time: CMTime) -> Bool {
        guard state.isLoaded || state.isReadyToPlay else { return false }
        return playerItem!.canSeek(to: time)
    }
    
    private func initializeObservers(with playerItem: AVPlayerItem) {
        playerItemReadinessObserver = AKPlayerItemReadinessObserver(with: playerItem)
        playerItemTracksObserverProtocol = AKPlayerItemTracksObserver(with: playerItem)
        steppingThroughMediaObserver = AKSteppingThroughMediaObserver(with: playerItem)
        playbackCapabilitiesObserver = AKPlaybackCapabilitiesObserver(with: playerItem)
        playerItemTimingInformationObserver = AKPlayerItemTimingInformationObserver(with: playerItem)
        playerItemAvailableTimeRangesObserver = AKPlayerItemTimeRangesObserver(with: playerItem)
        playerItemTracksObserver = AKPlayerItemTracksObserver(with: playerItem)
        playerItemPresentationObserver = AKPlayerItemPresentationObserver(with: playerItem)
        
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
                                            for playerItem: AVPlayerItem) {
        switch status {
        case .unknown: break
        case .readyToPlay:
            state = .readyToPlay
        case .failed:
            error = AKPlayerError.playerItemLoadingFailed(reason: .statusLoadingFailed(error: playerItem.error!))
            state = .failed
        @unknown default: assertionFailure()
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
        media.delegate?.akMedia(media, didChangeCanPlayReverseStatus: canPlayReverse)
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
