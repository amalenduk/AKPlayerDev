//
//  AKPlayable+Extensions.swift
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

import Foundation
import AVFoundation
import MediaPlayer
import Combine

private var managerKey: Void?

internal extension AKPlayable {
    
    private var manager: AKMediaManagerProtocol {
        get {
            guard let manager = objc_getAssociatedObject(self, &managerKey) as? AKMediaManagerProtocol else {
                let manager = AKMediaManager(media: self)
                setRetainedAssociatedObject(self, &managerKey, manager)
                return manager
            }
            return manager
        }
        set { setRetainedAssociatedObject(self, &managerKey, newValue)}
    }
    
    var statePublisher: AnyPublisher<AKPlayableState, Never> {
        get { manager.statePublisher }
    }
}

public extension AKPlayable {
    
    var playerItem: AVPlayerItem? {
        get { return manager.playerItem }
    }
    
    var state: AKPlayableState {
        get { return manager.state }
    }
    
    var error: AKPlayerError? {
        get { return manager.error }
    }
}

public extension AKPlayable {
    
    @discardableResult
    func createAsset() -> AVURLAsset {
        return manager.createAsset()
    }
    
    func fetchAssetPropertiesValues() async throws {
        try await manager.fetchAssetPropertiesValues()
    }
    
    func validateAssetPlayability() async throws {
        try await manager.validateAssetPlayability()
    }
    
    @discardableResult
    func createPlayerItemFromAsset() -> AVPlayerItem {
        return manager.createPlayerItemFromAsset()
    }
    
    func abortAssetInitialization() {
        manager.abortAssetInitialization()
    }
    
    func startPlayerItemAssetKeysObserver() {
        manager.startPlayerItemAssetKeysObserver()
    }
    
    func stopPlayerItemAssetKeysObserver() {
        manager.stopPlayerItemAssetKeysObserver()
    }
    
    func startPlayerItemReadinessObserver() {
        manager.startPlayerItemReadinessObserver()
    }
    
    func stopPlayerItemReadinessObserver() {
        manager.stopPlayerItemReadinessObserver()
    }
}

public extension AKPlayable {
    
    func canStep(by count: Int) -> Bool {
        return manager.canStep(by: count)
    }
    
    func canPlay(at rate: AKPlaybackRate) -> Bool {
        return manager.canPlay(at: rate)
    }
    
    func canSeek(to time: CMTime) -> (flag: Bool,
                                      reason: AKPlayerUnavailableCommandReason?) {
        return manager.canSeek(to: time)
    }
}

public extension AKPlayable {
    
    var tracks: [AVPlayerItemTrack] {
        return playerItem?.tracks ?? []
    }
}

public extension AKPlayable {
    
    var canPlayReverse: Bool {
        return playerItem?.canPlayReverse ?? false
    }
    
    var canPlayFastForward: Bool {
        return playerItem?.canPlayFastForward ?? false
    }
    
    var canPlayFastReverse: Bool {
        return playerItem?.canPlayFastReverse ?? false
    }
    
    var canPlaySlowForward: Bool {
        return playerItem?.canPlaySlowForward ?? false
    }
    
    var canPlaySlowReverse: Bool {
        return playerItem?.canPlaySlowReverse ?? false
    }
}

public extension AKPlayable {
    
    var forwardPlaybackEndTime: CMTime {
        get { playerItem?.forwardPlaybackEndTime ?? .invalid }
        set { playerItem?.forwardPlaybackEndTime = newValue }
    }
    
    var reversePlaybackEndTime: CMTime {
        get { playerItem?.reversePlaybackEndTime ?? .invalid }
        set { playerItem?.reversePlaybackEndTime = newValue }
    }
}

public extension AKPlayable {
    
    var canStepForward: Bool {
        return playerItem?.canStepForward ?? false
    }
    
    var canStepBackward: Bool {
        return playerItem?.canStepBackward ?? false
    }
}


public extension AKPlayable {
    
    var currentTime: CMTime {
        return playerItem?.currentTime() ?? .invalid
    }
    
    var currentDate: Date? {
        return playerItem?.currentDate()
    }
    
    var duration: CMTime {
        return playerItem?.duration ?? .invalid
    }
    
    var timebase: CMTimebase? {
        return playerItem?.timebase
    }
}

public extension AKPlayable {
    
    var seekableTimeRanges: [NSValue] {
        return playerItem?.seekableTimeRanges ?? []
    }
    
    var loadedTimeRanges: [NSValue] {
        return playerItem?.loadedTimeRanges ?? []
    }
    
    var seekableTimeRange: CMTimeRange {
        guard let firstRange = seekableTimeRanges.first?.timeRangeValue,
              !firstRange.isIndefinite,
              let lastRange = seekableTimeRanges.last?.timeRangeValue,
              !lastRange.isIndefinite else {
            return .invalid
        }
        return CMTimeRangeFromTimeToTime(start: firstRange.start,
                                         end: lastRange.end)
    }
    
    var loadedTimeRange: CMTimeRange {
        guard let firstRange = loadedTimeRanges.first?.timeRangeValue,
              !firstRange.isIndefinite,
              let lastRange = loadedTimeRanges.last?.timeRangeValue,
              !lastRange.isIndefinite else {
            return .invalid
        }
        return CMTimeRangeFromTimeToTime(start: firstRange.start,
                                         end: lastRange.end)
    }
    
    var buffer: Float {
        let duration = seekableTimeRange.duration
        guard loadedTimeRange.end.isNumeric,
              duration.isNumeric,
              duration != .zero else { return 0 }
        return Float(loadedTimeRange.end.seconds / duration.seconds)
    }
}

public extension AKPlayable {
    
    var isPlaybackLikelyToKeepUp: Bool {
        return playerItem?.isPlaybackLikelyToKeepUp ?? false
    }
    
    var isPlaybackBufferFull: Bool {
        return playerItem?.isPlaybackBufferFull ?? false
    }
    
    var isPlaybackBufferEmpty: Bool {
        return playerItem?.isPlaybackBufferEmpty ?? false
    }
}

public extension AKPlayable {
    
    var presentationSize: CGSize {
        return playerItem?.presentationSize ?? .zero
    }
    
    var automaticallyLoadedAssetKeysStrings: [String] {
        return playerItem?.automaticallyLoadedAssetKeys ?? []
    }
}
