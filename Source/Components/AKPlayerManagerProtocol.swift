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
    func playerManager(didCurrentMediaChange media: AKPlayable)
    func playerManager(didPlaybackRateChange playbackRate: AKPlaybackRate)
    func playerManager(didCurrentTimeChange currentTime: CMTime)
    func playerManager(didItemDurationChange itemDuration: CMTime)
    func playerManager(didItemPlayToEndTime endTime: CMTime)
    func playerManager(didVolumeChange volume: Float, isMuted: Bool)
    func playerManager(unavailableAction reason: AKPlayerUnavailableActionReason)
    func playerManager(didFailedWith error: AKPlayerError)
}

public protocol AKPlayerManagerProtocol: AKPlayerProtocol, AKPlayerCommandProtocol {
    var playingBeforeInterruption: Bool { get }
    var playbackInterruptionReason: AKPlaybackInterruptionReason { get }
    
    var requestedSeekingTime: CMTime? { get }
    
    var configuration: AKPlayerConfiguration { get }
    var controller: AKPlayerStateControllerProtocol! { get }
    
    var delegate: AKPlayerManagerDelegate? { get }
    var plugins: [AKPlayerPlugin]? { get }
    
    var remoteCommands: [AKRemoteCommand] { get }
    
    var audioSessionService: AKAudioSessionServiceable { get }
    var playerNowPlayingMetadataService: AKPlayerNowPlayingMetadataServiceable? { get }
    var remoteCommandController: AKRemoteCommandController? { get }
    var playerRateEventProducer: AKPlayerRateEventProducible! { get }
    var managingAudioOutputEventProducer: AKManagingAudioOutputEventProducible! { get }
    
    var audioSessionInterruptionEventProducer: AKAudioSessionInterruptionEventProducible! { get }
    var routeChangeEventProducer: AKRouteChangeEventProducible! { get }
    var mediaServicesResetEventProducer: AKMediaServicesResetEventProducible! { get }
    var applicationEventProducer: AKApplicationEventProducible! { get }
    
    func handleRemoteCommand(command: AKRemoteCommand, with event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    func change(_ controller: AKPlayerStateControllerProtocol)
    func startListeningEvents()
    func stopListeningEvents()
}

public enum AKPlaybackInterruptionReason: uint {
    case none
    case audioSessionInterrupted
    case applicationEnteredBackground
    case applicationResignActive
}
