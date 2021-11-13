//
//  AKPlayerConfiguration.swift
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

public struct AKAudioSessionConfiguration {
    
    // MARK: - Properties
    
    public var category: AVAudioSession.Category = .playback
    public var activeOptions: AVAudioSession.SetActiveOptions = [.notifyOthersOnDeactivation]
    public var mode: AVAudioSession.Mode = .default
    public var categoryOptions: AVAudioSession.CategoryOptions = [.duckOthers]
    
    // MARK: - Init
    
    public init() {}
}

public protocol AKPlayerConfiguration {
    var itemLoadedAssetKeys: [String] { get set }
    var periodicPlayingTimeInSecond: Double { get set }
    var boundaryTimeObserverMultiplier: Double { get set }
    var preferredTimescale: CMTimeScale { get set }
    var bufferObservingTimeout: TimeInterval { get set }
    var bufferObservingTimeInterval: TimeInterval { get set }
    
    var audioSession: AKAudioSessionConfiguration { get set }
    
    /// Pauses playback automatically when resigning active.
    var playbackPausesWhenResigningActive: Bool { get set }
    
    /// Pauses playback automatically when backgrounded.
    var playbackPausesWhenBackgrounded: Bool { get set }
    
    /// Resumes playback when became active.
    var playbackResumesWhenBecameActive: Bool { get set }
    
    /// Resumes playback when entering foreground.
    var playbackResumesWhenEnteringForeground: Bool { get set }
    
    /// Playback freezes on last frame frame when true and does not reset seek position timestamp..
    var playbackFreezesAtEnd: Bool { get set }
    
    
    var isNowPlayingEnabled: Bool { get set }
    var idleTimerDisabledForStates: [AKPlayerState] { get set }
}

public enum AKTimeEventFrequency {
    case everySecond
    case everyHalfSecond
    case everyQuarterSecond
    case custom(time: CMTime)
    
    func getTime() -> CMTime {
        switch self {
        case .everySecond: return CMTime(value: 1, timescale: 1)
        case .everyHalfSecond: return CMTime(value: 1, timescale: 2)
        case .everyQuarterSecond: return CMTime(value: 1, timescale: 4)
        case .custom(let time): return time
        }
    }
}
