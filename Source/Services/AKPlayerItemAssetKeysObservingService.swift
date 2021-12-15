//
//  AKPlayerItemAssetKeysObservingService.swift
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

public protocol AKPlayerItemAssetKeysObservingServiceable {
    var media: AKPlayable { get }
    var playerItem: AVPlayerItem { get }
    
    func startListeningEvents()
    func stopListeningEvents()
}

open class AKPlayerItemAssetKeysObservingService: AKPlayerItemAssetKeysObservingServiceable {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public let media: AKPlayable
    
    private var determiningPlaybackCapabilitiesEventProducer: AKDeterminingPlaybackCapabilitiesEventProducible!
    
    private var steppingThroughMediaEventProducer: AKSteppingThroughMediaEventProducible!
    
    private var accessingTimingInformationEventProducer: AKAccessingTimingInformationEventProducible!
    
    private var determiningAvailableTimeRangesEventProducer: AKDeterminingAvailableTimeRangesEventProducible!
    
    private var accessingAssetAndTracksEventProducer: AKAccessingAssetAndTracksEventProducible!
    
    // MARK: - Init
    
    public init(with playerItem: AVPlayerItem,
                media: AKPlayable) {
        AKPlayerLogger.shared.log(message: "Init",
                                  domain: .lifecycleService)
        self.playerItem = playerItem
        self.media = media
        
        steppingThroughMediaEventProducer = AKSteppingThroughMediaEventProducer(with: playerItem)
        determiningPlaybackCapabilitiesEventProducer = AKDeterminingPlaybackCapabilitiesEventProducer(with: playerItem)
        accessingTimingInformationEventProducer = AKAccessingTimingInformationEventProducer(with: playerItem)
        determiningAvailableTimeRangesEventProducer = AKDeterminingAvailableTimeRangesEventProducer(with: playerItem)
        accessingAssetAndTracksEventProducer = AKAccessingAssetAndTracksEventProducer(with: playerItem)
        
        steppingThroughMediaEventProducer.eventListener = self
        determiningPlaybackCapabilitiesEventProducer.eventListener = self
        accessingTimingInformationEventProducer.eventListener = self
        determiningAvailableTimeRangesEventProducer.eventListener = self
        accessingAssetAndTracksEventProducer.eventListener = self
    }
    
    deinit {
        stopListeningEvents()
        AKPlayerLogger.shared.log(message: "DeInit",
                                  domain: .lifecycleService)
    }
    
    // MARK: - Additional Helper Functions
    
    open func startListeningEvents() {
        steppingThroughMediaEventProducer.startProducingEvents()
        determiningPlaybackCapabilitiesEventProducer.startProducingEvents()
        accessingTimingInformationEventProducer.startProducingEvents()
        determiningAvailableTimeRangesEventProducer.startProducingEvents()
        accessingAssetAndTracksEventProducer.startProducingEvents()
    }
    
    open func stopListeningEvents() {
        steppingThroughMediaEventProducer.stopProducingEvents()
        determiningPlaybackCapabilitiesEventProducer.stopProducingEvents()
        accessingTimingInformationEventProducer.stopProducingEvents()
        determiningAvailableTimeRangesEventProducer.stopProducingEvents()
        accessingAssetAndTracksEventProducer.stopProducingEvents()
    }
}

// MARK: - AKEventListener

extension AKPlayerItemAssetKeysObservingService: AKEventListener {
    
    public func onEvent(_ event: AKEvent, generetedBy eventProducer: AKEventProducer) {
        if let event = event as? AKSteppingThroughMediaEventProducer.SteppingThroughMediaEvent {
            switch event {
            case .canStepForward(let canStepForward):
                media.delegate?.akMedia(media, didChangeCanStepForwardStatus: canStepForward)
            case .canStepBackward(let canStepBackward):
                media.delegate?.akMedia(media, didChangeCanStepBackwardStatus: canStepBackward)
            }
        }else if let event = event as? AKDeterminingPlaybackCapabilitiesEventProducer.DeterminingPlaybackCapabilitiesEvent {
            switch event {
            case .canPlayReverse(let canPlayReverse):
                media.delegate?.akMedia(media, didChangeCanPlayReverseStatus: canPlayReverse)
            case .canPlayFastForward(let canPlayFastForward):
                media.delegate?.akMedia(media, didChangeCanPlayFastForwardStatus: canPlayFastForward)
            case .canPlayFastReverse(let canPlayFastReverse):
                media.delegate?.akMedia(media, didChangeCanPlayFastReverseStatus: canPlayFastReverse)
            case .canPlaySlowForward(let canPlaySlowForward):
                media.delegate?.akMedia(media, didChangeCanPlaySlowForwardStatus: canPlaySlowForward)
            case .canPlaySlowReverse(let canPlaySlowReverse):
                media.delegate?.akMedia(media, didChangeCanPlaySlowReverseStatus: canPlaySlowReverse)
            }
        }else if let event = event as? AKAccessingTimingInformationEventProducer.AccessingTimingInformationEvent {
            switch event {
            case .durationChanged(let duration):
                media.delegate?.akMedia(media, didChangeItemDuration: duration)
            }
        }else if let event = event as? AKDeterminingAvailableTimeRangesEventProducer.DeterminingAvailableTimeRangesEvent {
            switch event {
            case .loadedTimeRanges(let loadedTimeRanges):
                media.delegate?.akMedia(media, didChangeLoadedTimeRanges: loadedTimeRanges)
            case .seekableTimeRanges(let seekableTimeRanges):
                media.delegate?.akMedia(media, didChangeSeekableTimeRanges: seekableTimeRanges)
            }
        }else if let event = event as? AKAccessingAssetAndTracksEventProducer.AccessingAssetAndTracksEvent {
            switch event {
            case .tracks(let tracks):
                media.delegate?.akMedia(media, didChangeTracks: tracks)
            }
        } else {
            fatalError()
        }
    }
}
