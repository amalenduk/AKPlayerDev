//
//  AKMediaDelegate.swift
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

public protocol AKMediaDelegate: AnyObject {
    func akMedia(_ media: AKPlayable,
                 didChangeState state: AKPlayableState)
    func akMedia(_ media: AKPlayable,
                 didChangeItemDurationTo itemDuration: CMTime)
    func akMedia(_ media: AKPlayable,
                 didChangeTimebaseTo timebase: CMTimebase?)
    func akMedia(_ media: AKPlayable,
                 didChangeCanPlayReverseStatusTo canPlayReverse: Bool)
    func akMedia(_ media: AKPlayable,
                 didChangeCanPlayFastForwardStatusTo canPlayFastForward: Bool)
    func akMedia(_ media: AKPlayable,
                 didChangeCanPlayFastReverseStatusTo canPlayFastReverse: Bool)
    func akMedia(_ media: AKPlayable,
                 didChangeCanPlaySlowForwardStatusTo canPlaySlowForward: Bool)
    func akMedia(_ media: AKPlayable,
                 didChangeCanPlaySlowReverseStatusTo canPlaySlowReverse: Bool)
    func akMedia(_ media: AKPlayable,
                 didChangeCanStepForwardStatusTo canStepForward: Bool)
    func akMedia(_ media: AKPlayable,
                 didChangeCanStepBackwardStatusTo canStepBackward: Bool)
    func akMedia(_ media: AKPlayable,
                 didChangeLoadedTimeRangesTo loadedTimeRanges: [NSValue])
    func akMedia(_ media: AKPlayable,
                 didChangeSeekableTimeRangesTo seekableTimeRanges: [NSValue])
    func akMedia(_ media: AKPlayable,
                 didChangeTracksTo tracks: [AVPlayerItemTrack])
    func akMedia(_ media: AKPlayable,
                 didChangePresentationSizeTo size: CGSize)
}

public extension AKMediaDelegate {
    func akMedia(_ media: AKPlayable,
                 didChangeState state: AKPlayableState) { }
    func akMedia(_ media: AKPlayable,
                 didChangeItemDurationTo itemDuration: CMTime) { }
    func akMedia(_ media: AKPlayable,
                 didChangeTimebaseTo timebase: CMTimebase?) { }
    func akMedia(_ media: AKPlayable,
                 didChangeCanPlayReverseStatusTo canPlayReverse: Bool) { }
    func akMedia(_ media: AKPlayable,
                 didChangeCanPlayFastForwardStatusTo canPlayFastForward: Bool) { }
    func akMedia(_ media: AKPlayable,
                 didChangeCanPlayFastReverseStatusTo canPlayFastReverse: Bool) { }
    func akMedia(_ media: AKPlayable,
                 didChangeCanPlaySlowForwardStatusTo canPlaySlowForward: Bool) { }
    func akMedia(_ media: AKPlayable,
                 didChangeCanPlaySlowReverseStatusTo canPlaySlowReverse: Bool) { }
    func akMedia(_ media: AKPlayable,
                 didChangeCanStepForwardStatusTo canStepForward: Bool) { }
    func akMedia(_ media: AKPlayable,
                 didChangeCanStepBackwardStatusTo canStepBackward: Bool) { }
    func akMedia(_ media: AKPlayable,
                 didChangeLoadedTimeRangesTo loadedTimeRanges: [NSValue]) { }
    func akMedia(_ media: AKPlayable,
                 didChangeSeekableTimeRangesTo seekableTimeRanges: [NSValue]) { }
    func akMedia(_ media: AKPlayable,
                 didChangeTracksTo tracks: [AVPlayerItemTrack]) { }
    func akMedia(_ media: AKPlayable,
                 didChangePresentationSizeTo size: CGSize) { }
}
