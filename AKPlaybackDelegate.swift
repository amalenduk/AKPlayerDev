//
//  AKPlaybackDelegate.swift
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

public protocol AKPlaybackDelegate: AnyObject {
    func akPlayback(didCanPlayReverseStatusChange canPlayReverse: Bool, for media: AKPlayable)
    func akPlayback(didCanPlayFastForwardStatusChange canPlayFastForward: Bool, for media: AKPlayable)
    func akPlayback(didCanPlayFastReverseStatusChange canPlayFastReverse: Bool, for media: AKPlayable)
    func akPlayback(didCanPlaySlowForwardStatusChange canPlaySlowForward: Bool, for media: AKPlayable)
    func akPlayback(didCanPlaySlowReverseStatusChange canPlaySlowReverse: Bool, for media: AKPlayable)
    
    func akPlayback(didCanStepForwardStatusChange canStepForward: Bool, for media: AKPlayable)
    func akPlayback(didCanStepBackwardStatusChange canStepBackward: Bool, for media: AKPlayable)
    func akPlayback(didLoadedTimeRangesChange loadedTimeRanges: [NSValue], for media: AKPlayable)
    func akPlayback(didSeekableTimeRangesChange seekableTimeRanges: [NSValue], for media: AKPlayable)
    
    func akPlayback(didChangedTracks tracks: [AVPlayerItemTrack], for media: AKPlayable)
}

public extension AKPlaybackDelegate {
    func akPlayback(didCanPlayReverseStatusChange canPlayReverse: Bool, for media: AKPlayable) { }
    func akPlayback(didCanPlayFastForwardStatusChange canPlayFastForward: Bool, for media: AKPlayable) { }
    func akPlayback(didCanPlayFastReverseStatusChange canPlayFastReverse: Bool, for media: AKPlayable) { }
    func akPlayback(didCanPlaySlowForwardStatusChange canPlaySlowForward: Bool, for media: AKPlayable) { }
    func akPlayback(didCanPlaySlowReverseStatusChange canPlaySlowReverse: Bool, for media: AKPlayable) { }
    
    func akPlayback(didCanStepForwardStatusChange canStepForward: Bool, for media: AKPlayable) { }
    func akPlayback(didCanStepBackwardStatusChange canStepBackward: Bool, for media: AKPlayable) { }
    func akPlayback(didLoadedTimeRangesChange loadedTimeRanges: [NSValue], for media: AKPlayable) { }
    func akPlayback(didSeekableTimeRangesChange seekableTimeRanges: [NSValue], for media: AKPlayable) { }
    
    func akPlayback(didChangedTracks tracks: [AVPlayerItemTrack], for media: AKPlayable) { }
}
