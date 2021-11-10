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

final class AKPlayerItemAssetKeysObservingService {
    
    // MARK: - Properties
    
    private let playerItem: AVPlayerItem
    
    private let media: AKPlayable
    
    private var determiningPlaybackCapabilitiesService: AKDeterminingPlaybackCapabilitiesService!
    
    private var steppingThroughMediaService: AKSteppingThroughMediaService!
    
    private var accessingTimingInformationService: AKAccessingTimingInformationService!
    
    private var determiningAvailableTimeRangesService: AKDeterminingAvailableTimeRangesService!
    
    private var accessingAssetAndTracks: AKAccessingAssetAndTracksService!
    
    // MARK: - Init
    
    init(with playerItem: AVPlayerItem,
         media: AKPlayable) {
        AKPlayerLogger.shared.log(message: "Init",
                                  domain: .lifecycleService)
        self.playerItem = playerItem
        self.media = media
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit",
                                  domain: .lifecycleService)
    }
    
    // MARK: - Additional Helper Functions
    
    private func setupDeterminingPlaybackCapabilitiesService() {
        determiningPlaybackCapabilitiesService = AKDeterminingPlaybackCapabilitiesService(with: playerItem)
        
        determiningPlaybackCapabilitiesService.onChangeCanPlayReverseCallback = { [unowned self] canPlayReverse in
            media.delegate?.akMedia(media, didChangeCanPlayReverseStatus: canPlayReverse)
        }
        
        determiningPlaybackCapabilitiesService.onChangeCanPlayFastForwardCallback = { [unowned self] canPlayFastForward in
            media.delegate?.akMedia(media, didChangeCanPlayFastForwardStatus: canPlayFastForward)
            
        }
        
        determiningPlaybackCapabilitiesService.onChangeCanPlayFastReverseCallback = { [unowned self] canPlayFastReverse in
            media.delegate?.akMedia(media, didChangeCanPlayFastReverseStatus: canPlayFastReverse)
        }
        
        determiningPlaybackCapabilitiesService.onChangeCanPlaySlowForwardCallback = { [unowned self] canPlaySlowForward in
            media.delegate?.akMedia(media, didChangeCanPlaySlowForwardStatus: canPlaySlowForward)
        }
        
        determiningPlaybackCapabilitiesService.onChangeCanPlaySlowReverseCallback = { [unowned self] canPlaySlowReverse in
            media.delegate?.akMedia(media, didChangeCanPlaySlowReverseStatus: canPlaySlowReverse)
        }
    }
    
    private func setupSteppingThroughMediaService() {
        steppingThroughMediaService = AKSteppingThroughMediaService(with: playerItem)
        
        steppingThroughMediaService.onChangecanStepForwardCallback = { [unowned self] canStepForward in
            media.delegate?.akMedia(media, didChangeCanStepForwardStatus: canStepForward)
        }
        
        steppingThroughMediaService.onChangecanStepBackwardCallback = { [unowned self] canStepBackward in
            media.delegate?.akMedia(media, didChangeCanStepBackwardStatus: canStepBackward)
        }
    }
    
    private func setupDeterminingAvailableTimeRangesService() {
        determiningAvailableTimeRangesService = AKDeterminingAvailableTimeRangesService(with: playerItem)
        
        determiningAvailableTimeRangesService.onChangeLoadedTimeRangesCallback = { [unowned self] loadedTimeRanges in
            media.delegate?.akMedia(media, didChangeLoadedTimeRanges: loadedTimeRanges)
        }
    }
    
    private func setupAccessingTimingInformationService() {
        accessingTimingInformationService = AKAccessingTimingInformationService(with: playerItem)
        
        accessingTimingInformationService.onChangeDurationCallback = { [unowned self] duration in
            media.delegate?.akMedia(media, didChangeItemDuration: duration)
        }
    }
    
    private func setupAccessingAssetAndTracksService() {
        accessingAssetAndTracks = AKAccessingAssetAndTracksService(with: playerItem)
        
        accessingAssetAndTracks.onChangeTracks = { [unowned self] tracks in
            media.delegate?.akMedia(media, didChangeTracks: tracks)
        }
    }
    
    func startObserving() {
        setupDeterminingPlaybackCapabilitiesService()
        setupSteppingThroughMediaService()
        setupAccessingTimingInformationService()
        setupDeterminingAvailableTimeRangesService()
        setupAccessingAssetAndTracksService()
        
        accessingTimingInformationService.startObserving()
        steppingThroughMediaService.startObserving()
        determiningPlaybackCapabilitiesService.startObserving()
        determiningAvailableTimeRangesService.startObserving()
        accessingAssetAndTracks.startObserving()
    }
}
