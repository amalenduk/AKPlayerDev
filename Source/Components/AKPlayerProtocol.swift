//
//  AKPlayerProtocol.swift
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

public protocol AKPlayerProtocol: AnyObject, AKPlayerCommandsProtocol {
    var player: AVPlayer { get }
    var state: AKPlayerState { get }
    var defaultRate: AKPlaybackRate { get set }
    var rate: AKPlaybackRate { get set }
    var currentMedia: AKPlayable? { get }
    var currentItem: AVPlayerItem? { get }
    var currentItemDuration: CMTime { get }
    var currentTime: CMTime { get }
    var remainingTime: CMTime? { get }
    var autoPlay: Bool { get }
    var isSeeking: Bool { get }
    var seekPosition: AKSeekPosition? { get }
    var volume: Float { get set }
    var isMuted: Bool { get set }
    var error: AKPlayerError? { get }
    
    func addBoundaryTimeObserver(for times: [CMTime])
    func removeBoundaryTimeObserver()
}
