//
//  AKPlayerManagerProtocol.swift
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

public protocol AKPlayerManagerDelegate: AnyObject {
    func playerManager(didStateChange state: AKPlayerState)
    func playerManager(didPlaybackRateChange playbackRate: AKPlaybackRate)
    func playerManager(didCurrentMediaChange media: AKPlayable)
    func playerManager(didCurrentTimeChange currentTime: CMTime)
    func playerManager(didItemDurationChange itemDuration: CMTime)
    func playerManager(didItemPlayToEndTime endTime: CMTime)
    func playerManager(didVolumeChange volume: Float, isMuted: Bool)
    func playerManager(unavailableAction reason: AKPlayerUnavailableActionReason)
    func playerManager(didFailedWith error: AKPlayerError)
    
    func playerManager(didCanPlayReverseStatusChange canPlayReverse: Bool, for media: AKPlayable)
    func playerManager(didCanPlayFastForwardStatusChange canPlayFastForward: Bool, for media: AKPlayable)
    func playerManager(didCanPlayFastReverseStatusChange canPlayFastReverse: Bool, for media: AKPlayable)
    func playerManager(didCanPlaySlowForwardStatusChange canPlaySlowForward: Bool, for media: AKPlayable)
    func playerManager(didCanPlaySlowReverseStatusChange canPlaySlowReverse: Bool, for media: AKPlayable)
    
    func playerManager(didCanStepForwardStatusChange canStepForward: Bool, for media: AKPlayable)
    func playerManager(didCanStepBackwardStatusChange canStepBackward: Bool, for media: AKPlayable)
    func playerManager(didLoadedTimeRangesChange loadedTimeRanges: [NSValue], for media: AKPlayable)
    func playerManager(didSeekableTimeRangesChange seekableTimeRanges: [NSValue], for media: AKPlayable)
    
    func playerManager(didChangedTracks tracks: [AVPlayerItemTrack], for media: AKPlayable)
}

public protocol AKPlayerManagerProtocol: AKPlayerProtocol, AKPlayerCommand {
    var audioSessionInterrupted: Bool { get }
    var playingBeforeInterruption: Bool { get }
    var requestedSeekingTime: CMTime? { get }
    
    var configuration: AKPlayerConfiguration { get }
    var controller: AKPlayerStateControllable! { get }
    
    var delegate: AKPlayerManagerDelegate? { get }
    var plugins: [AKPlayerPlugin]? { get }
    
    var remoteCommands: [AKRemoteCommand] { get }
    
    var audioSessionService: AKAudioSessionServiceable { get }
    var playerNowPlayingMetadataService: AKPlayerNowPlayingMetadataServiceable? { get }
    var remoteCommandController: AKRemoteCommandController? { get }
    var playerRateObservingService: AKPlayerRateObservingService! { get }
    var audioSessionInterruptionObservingService: AKAudioSessionInterruptionObservingServiceable! { get }
    var managingAudioOutputService: AKManagingAudioOutputService! { get }
    
    func handleRemoteCommand(command: AKRemoteCommand, with event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    func change(_ controller: AKPlayerStateControllable)
}
