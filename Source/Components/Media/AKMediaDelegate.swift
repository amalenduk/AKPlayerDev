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
                 didLoadedAssetProperties properties: [AVPartialAsyncProperty<AVAsset>],
                 with error: Error?,
                 forAsset asset: AVURLAsset)
    func akMedia(_ media: AKPlayable, 
                 didChangeItemDuration itemDuration: CMTime)
    func akMedia(_ media: AKPlayable, 
                 didChangeTimebase timebase: CMTimebase?)
    func akMedia(_ media: AKPlayable, 
                 didChangeCanPlayReverseStatus canPlayReverse: Bool)
    func akMedia(_ media: AKPlayable, 
                 didChangeCanPlayFastForwardStatus canPlayFastForward: Bool)
    func akMedia(_ media: AKPlayable, 
                 didChangeCanPlayFastReverseStatus canPlayFastReverse: Bool)
    func akMedia(_ media: AKPlayable, 
                 didChangeCanPlaySlowForwardStatus canPlaySlowForward: Bool)
    func akMedia(_ media: AKPlayable, 
                 didChangeCanPlaySlowReverseStatus canPlaySlowReverse: Bool)
    func akMedia(_ media: AKPlayable, 
                 didChangeCanStepForwardStatus canStepForward: Bool)
    func akMedia(_ media: AKPlayable, 
                 didChangeCanStepBackwardStatus canStepBackward: Bool)
    func akMedia(_ media: AKPlayable, 
                 didChangeLoadedTimeRanges loadedTimeRanges: [NSValue])
    func akMedia(_ media: AKPlayable, 
                 didChangeSeekableTimeRanges seekableTimeRanges: [NSValue])
    func akMedia(_ media: AKPlayable, 
                 didChangeTracks tracks: [AVPlayerItemTrack])
    func akMedia(_ media: AKPlayable, 
                 didChangePresentationSize size: CGSize)
}

public extension AKMediaDelegate {
    func akMedia(_ media: AKPlayable,
                 didLoadedAssetProperties properties: [AVPartialAsyncProperty<AVAsset>],
                 with error: Error?,
                 forAsset asset: AVURLAsset) { }
    func akMedia(_ media: AKPlayable,
                 didChangeItemDuration itemDuration: CMTime) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeTimebase timebase: CMTimebase?) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeCanPlayReverseStatus canPlayReverse: Bool) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeCanPlayFastForwardStatus canPlayFastForward: Bool) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeCanPlayFastReverseStatus canPlayFastReverse: Bool) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeCanPlaySlowForwardStatus canPlaySlowForward: Bool) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeCanPlaySlowReverseStatus canPlaySlowReverse: Bool) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeCanStepForwardStatus canStepForward: Bool) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeCanStepBackwardStatus canStepBackward: Bool) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeLoadedTimeRanges loadedTimeRanges: [NSValue]) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeSeekableTimeRanges seekableTimeRanges: [NSValue]) { }
    func akMedia(_ media: AKPlayable, 
                 didChangeTracks tracks: [AVPlayerItemTrack]) { }
    func akMedia(_ media: AKPlayable, 
                 didChangePresentationSize size: CGSize) { }
}
