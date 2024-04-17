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
    func playerManager(_ playerManager: AKPlayerManagerProtocol,
                       didChangeStateTo state: AKPlayerState)
    func playerManager(_ playerManager: AKPlayerManagerProtocol,
                       didChangeMediaTo media: AKPlayable)
    func playerManager(_ playerManager: AKPlayerManagerProtocol,
                       didChangePlaybackRateTo newRate: AKPlaybackRate,
                       from oldRate: AKPlaybackRate)
    func playerManager(_ playerManager: AKPlayerManagerProtocol,
                       didChangeCurrentTimeTo currentTime: CMTime,
                       for media: AKPlayable)
    func playerManager(_ playerManager: AKPlayerManagerProtocol,
                       didInvokeBoundaryTimeObserverAt time: CMTime,
                       for media: AKPlayable)
    func playerManager(_ playerManager: AKPlayerManagerProtocol,
                       playerItemDidReachEnd endTime: CMTime,
                       for media: AKPlayable)
    func playerManager(_ playerManager: AKPlayerManagerProtocol,
                       didChangeVolumeTo volume: Float)
    func playerManager(_ playerManager: AKPlayerManagerProtocol,
                       didChangeMutedStatusTo isMuted: Bool)
    func playerManager(_ playerManager: AKPlayerManagerProtocol,
                       unavailableActionWith reason: AKPlayerUnavailableCommandReason)
    func playerManager(_ playerManager: AKPlayerManagerProtocol,
                       didFailWith error: AKPlayerError)
}

public protocol AKPlayerManagerProtocol: AKPlayerProtocol, AKPlayerCommandsProtocol {
    var playerController: AKPlayerControllerProtocol { get }
    var configuration: AKPlayerConfigurationProtocol { get }
    var delegate: AKPlayerManagerDelegate? { get }
    var playerStateSnapshot: AKPlayerStateSnapshot? { get }
    var remoteCommands: [AKRemoteCommand] { get }
    
    var audioSessionService: AKAudioSessionServiceProtocol { get }
    var audioSessionInterruptionObserver: AKAudioSessionInterruptionObserverProtocol! { get }
    var audioSessionRouteChangesObserver: AKAudioSessionRouteChangesObserverProtocol! { get }
    var audioSessionMediaServicesWereResetObserver: AKAudioSessionMediaServicesWereResetObserverProtocol! { get }
    var audioSessionSilenceSecondaryAudioHintObserver: AKAudioSessionSilenceSecondaryAudioHintObserverProtocol! { get }
    var audioSessionMediaServicesLostObserver: AKAudioSessionMediaServicesLostObserverProtocol! { get }
    var audioSessionSpatialPlaybackCapabilitiesObserver: AKAudioSessionSpatialPlaybackCapabilitiesObserverProtocol! { get }
    var applicationLifeCycleEventsObserver: AKApplicationLifeCycleEventsObserverProtocol! { get }
    var nowPlayingSessionController: AKNowPlayingSessionController! { get }
    
    func prepare() throws
    func canPlay() -> Bool
    func updateNowPlayingControl()
    func setNowPlayingInfo()
    func handleRemoteCommand(_ command: AKRemoteCommand, with event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
}

public struct AKPlayerStateSnapshot {
    var state: AKPlayerState
    var shouldResume: Bool
    var applicationState: AKApplicationLifeCycleState
    var playbackInterruptionReason: AKPlaybackInterruptionReason
}

public enum AKPlaybackInterruptionReason: uint {
    case audioSessionInterruption
    case applicationResignActive
    case applicationEnteredBackground
    
    var isLifeCycleEvent: Bool {
        return self == .applicationEnteredBackground 
        || self == .applicationResignActive
    }
}
