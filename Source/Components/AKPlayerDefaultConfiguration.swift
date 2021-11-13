//
//  AKPlayerDefaultConfiguration.swift
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

public struct AKPlayerDefaultConfiguration: AKPlayerConfiguration {
    
    // MARK: - Properties
    
    public var periodicPlayingTimeInSecond: Double = 0.5
    
    public var preferredTimescale: CMTimeScale = CMTimeScale(NSEC_PER_SEC)
    
    public var itemLoadedAssetKeys: [String] = ["availableChapterLocales", "duration", "playable", "hasProtectedContent"]
    
    public var boundaryTimeObserverMultiplier: Double = 0.20
    
    public var bufferObservingTimeout: TimeInterval = 480
    
    public var bufferObservingTimeInterval: TimeInterval = 0.3
    
    public var audioSession: AKAudioSessionConfiguration = AKAudioSessionConfiguration()
    
    public var isNowPlayingEnabled: Bool = true
    
    public var idleTimerDisabledForStates: [AKPlayerState] = [AKPlayerState.buffering,
                                                              AKPlayerState.playing]
    public var textStyleRules: [AVTextStyleRule]? = nil
    
    public var playbackPausesWhenResigningActive: Bool = false
    
    public var playbackPausesWhenBackgrounded: Bool = false
    
    public var playbackResumesWhenBecameActive: Bool = true
    
    public var playbackResumesWhenEnteringForeground: Bool = true
    
    public var playbackFreezesAtEnd: Bool = true
    
    /// Default Configuration
    public static var `default` = AKPlayerDefaultConfiguration()
    
    // MARK: - Init
    
    public init() {}
    
}
