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
    
    private unowned let manager: AKPlayerManagerProtocol
    
    private let playerItem: AVPlayerItem
    
    private let media: AKPlayable
    
    private var determiningPlaybackCapabilitiesService: AKDeterminingPlaybackCapabilitiesService!
    
    private var steppingThroughMediaService: AKSteppingThroughMediaService!
    
    private var accessingTimingInformationService: AKAccessingTimingInformationService!
    
    private var determiningAvailableTimeRangesService: AKDeterminingAvailableTimeRangesService!
    
    private var accessingAssetAndTracks: AKAccessingAssetAndTracksService!
    
    // MARK: - Init
    
    init(with playerItem: AVPlayerItem,
         media: AKPlayable,
         manager: AKPlayerManagerProtocol) {
        AKPlayerLogger.shared.log(message: "Init",
                                  domain: .lifecycleService)
        self.playerItem = playerItem
        self.media = media
        self.manager = manager
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit",
                                  domain: .lifecycleService)
    }
    
    // MARK: - Additional Helper Functions
    
    private func setupDeterminingPlaybackCapabilitiesService() {
        determiningPlaybackCapabilitiesService = AKDeterminingPlaybackCapabilitiesService(with: playerItem)
        
        determiningPlaybackCapabilitiesService.onChangeCanPlayReverseCallback = { [unowned self] canPlayReverse in
            manager.delegate?.playerManager(didCanPlayReverseStatusChange: canPlayReverse,
                                            for: media)
        }
        
        determiningPlaybackCapabilitiesService.onChangeCanPlayFastForwardCallback = { [unowned self] canPlayFastForward in
            manager.delegate?.playerManager(didCanPlayFastForwardStatusChange: canPlayFastForward,
                                            for: media)
            
        }
        
        determiningPlaybackCapabilitiesService.onChangeCanPlayFastReverseCallback = { [unowned self] canPlayFastReverse in
            manager.delegate?.playerManager(didCanPlayFastReverseStatusChange: canPlayFastReverse,
                                            for: media)
            
        }
        
        determiningPlaybackCapabilitiesService.onChangeCanPlaySlowForwardCallback = { [unowned self] canPlaySlowForward in
            manager.delegate?.playerManager(didCanPlaySlowForwardStatusChange: canPlaySlowForward,
                                            for: media)
            
        }
        
        determiningPlaybackCapabilitiesService.onChangeCanPlaySlowReverseCallback = { [unowned self] canPlaySlowReverse in
            manager.delegate?.playerManager(didCanPlaySlowReverseStatusChange: canPlaySlowReverse,
                                            for: media)
        }
    }
    
    private func setupSteppingThroughMediaService() {
        steppingThroughMediaService = AKSteppingThroughMediaService(with: playerItem)
        
        steppingThroughMediaService.onChangecanStepForwardCallback = { [unowned self] canStepForward in
            manager.delegate?.playerManager(didCanStepForwardStatusChange: canStepForward,
                                            for: media)
        }
        
        steppingThroughMediaService.onChangecanStepBackwardCallback = { [unowned self] canStepBackward in
            manager.delegate?.playerManager(didCanStepBackwardStatusChange: canStepBackward,
                                            for: media)
        }
    }
    
    private func setupDeterminingAvailableTimeRangesService() {
        determiningAvailableTimeRangesService = AKDeterminingAvailableTimeRangesService(with: playerItem)
        
        determiningAvailableTimeRangesService.onChangeLoadedTimeRangesCallback = { [unowned self] loadedTimeRanges in
            manager.delegate?.playerManager(didLoadedTimeRangesChange: loadedTimeRanges, for: media)
        }
    }
    
    private func setupAccessingTimingInformationService() {
        accessingTimingInformationService = AKAccessingTimingInformationService(with: playerItem)
        
        accessingTimingInformationService.onChangeDurationCallback = { [unowned self] duration in
            manager.delegate?.playerManager(didItemDurationChange: duration)
        }
    }
    
    private func setupAccessingAssetAndTracksService() {
        accessingAssetAndTracks = AKAccessingAssetAndTracksService(with: playerItem)
        
        accessingAssetAndTracks.onChangeTracks = { [unowned self] tracks in
            manager.delegate?.playerManager(didChangedTracks: tracks, for: media)
        }
    }
    
    var vc: AKAccessingChapterMetadataService?
    var vc2: AKMediaSelectionService!
    
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
        
        vc = AKAccessingChapterMetadataService(with: playerItem.asset)
        vc?.startObserving()
        
        vc2 = AKMediaSelectionService(with: playerItem)
    }
}
