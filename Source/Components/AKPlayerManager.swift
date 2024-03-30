//
//  AKPlayerManager.swift
//  AKPlayer
///Users/amal/Desktop/MyProjects/Akplayer/AKPod/AKPlayer/Source/Components
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
import Foundation
import MediaPlayer

public class AKPlayerManager: NSObject, AKPlayerManagerProtocol {
    
    // MARK: - Properties
    
    public var player: AVPlayer {
        return playerController.player
    }
    
    public var state: AKPlayerState {
        return playerController.state
    }
    
    public var defaultRate: AKPlaybackRate {
        get { return playerController.defaultRate }
        set { playerController.defaultRate = newValue }
    }
    
    public var rate: AKPlaybackRate {
        get { return playerController.rate }
        set { playerController.rate = newValue }
    }
    
    public var currentMedia: AKPlayable? {
        playerController.currentMedia
    }
    
    public var currentItem: AVPlayerItem? {
        return playerController.currentItem
    }
    
    public var currentItemDuration: CMTime? {
        return playerController.currentItemDuration
    }
    
    public var currentTime: CMTime {
        return playerController.currentTime
    }
    
    public var remainingTime: CMTime? {
        return playerController.remainingTime
    }
    
    public var autoPlay: Bool {
        return playerController.autoPlay
    }
    
    public var volume: Float {
        get { return playerController.volume }
        set { playerController.volume = newValue }
    }
    
    public var isMuted: Bool {
        get { return playerController.isMuted }
        set { playerController.isMuted = newValue }
    }
    
    public var error: AKPlayerError? { playerController.error }
    
    public let playerController: AKPlayerControllerProtocol
    
    public var remoteCommands: [AKRemoteCommand] = []
    
    public var configuration: AKPlayerConfigurationProtocol { playerController.configuration }
    
    public weak var delegate: AKPlayerManagerDelegate?
    
    public private(set) var playerStateSnapshot: AKPlayerStateSnapshot?
    
    public var audioSession: AVAudioSession { audioSessionService.audioSession }
    
    private var isExternalAudioPlaybackDeviceConnected: Bool = false
    
    public let audioSessionService: AKAudioSessionServiceProtocol
    
    public private(set) var audioSessionInterruptionObserver: AKAudioSessionInterruptionObserverProtocol!
    
    public private(set) var audioSessionRouteChangesObserver: AKAudioSessionRouteChangesObserverProtocol!
    
    public private(set) var audioSessionMediaServicesWereResetObserver: AKAudioSessionMediaServicesWereResetObserverProtocol!
    
    public private(set) var audioSessionSilenceSecondaryAudioHintObserver: AKAudioSessionSilenceSecondaryAudioHintObserverProtocol!
    
    public private(set) var audioSessionMediaServicesLostObserver: AKAudioSessionMediaServicesLostObserverProtocol!
    
    public private(set) var audioSessionSpatialPlaybackCapabilitiesObserver: AKAudioSessionSpatialPlaybackCapabilitiesObserverProtocol!
    
    public private(set) var applicationLifeCycleEventsObserver: AKApplicationLifeCycleEventsObserverProtocol!
    
    public private(set) var nowPlayingSessionController: AKNowPlayingSessionController!
    
    // MARK: - Init
    
    public init(player: AVPlayer,
                configuration: AKPlayerConfigurationProtocol,
                audioSessionService: AKAudioSessionServiceProtocol = AKAudioSessionService()) {
        self.playerController = AKPlayerController(player: player,
                                                   configuration: configuration)
        self.audioSessionService = audioSessionService
        super.init()
        
        audioSessionInterruptionObserver = AKAudioSessionInterruptionObserver(audioSession: audioSession)
        audioSessionRouteChangesObserver = AKAudioSessionRouteChangesObserver(audioSession: audioSession)
        audioSessionMediaServicesWereResetObserver = AKAudioSessionMediaServicesWereResetObserver(audioSession: audioSession)
        applicationLifeCycleEventsObserver = AKApplicationLifeCycleEventsObserver()
        nowPlayingSessionController = AKNowPlayingSessionController(players: [player])
        
        playerController.delegate = self
        audioSessionInterruptionObserver.delegate = self
        audioSessionRouteChangesObserver.delegate = self
        audioSessionMediaServicesWereResetObserver.delegate = self
        applicationLifeCycleEventsObserver.delegate = self
        nowPlayingSessionController.delegate = self
    }
    
    deinit {
        stopObservers()
        print("AKPLayerManager: Deinit called from the AKPLayerManager ✌🏼")
    }
    
    open func prepare() throws {
        try setAudioSession(true)
        try playerController.prepare()
        try setNowPlayingSessionActive()
        
        startObservers()
        isExternalAudioPlaybackDeviceConnected = audioSessionRouteChangesObserver.isExternalDeviceConnected()
    }
    
    open func canPlay() -> Bool {
        switch applicationLifeCycleEventsObserver.state {
        case .resignActive where configuration.playbackPausesWhenResigningActive: return false
        case .background where configuration.playbackPausesWhenBackgrounded: return false
        default: return true
        }
    }
    
    open func updateNowPlayingControl() {
        guard configuration.isNowPlayingEnabled else { return }
        nowPlayingSessionController.unregister(commands: AKRemoteCommand.all())
        nowPlayingSessionController.register(commands: remoteCommands)
        nowPlayingSessionController.enable(commands: remoteCommands)
    }
    
    open func setNowPlayingInfo() {
        guard configuration.isNowPlayingEnabled,
              let currentMedia = currentMedia else { return }
        let nowPlayableMetadata = AKNowPlayableMetadata(staticMetadata: currentMedia.staticMetadata,
                                                        dynamicMetadata: getNowPlayableDynamicMetadata())
        nowPlayingSessionController.setNowPlayingInfo(nowPlayableMetadata)
    }
    
    open func handleRemoteCommand(_ command: AKRemoteCommand, with event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        switch command {
        case .pause:
            if currentMedia == nil { return .noActionableNowPlayingItem }
            pause()
            guard state.isPaused else { return .commandFailed }
        case .play:
            if currentMedia == nil { return .noActionableNowPlayingItem }
            play()
            guard (state.isLoadingStateActive && autoPlay) || state.isPlaybackActive else { return .commandFailed }
        case .stop:
            if currentMedia == nil { return .noActionableNowPlayingItem }
            stop()
            guard state.isStopped else { return .commandFailed }
        case .togglePlayPause:
            if currentMedia == nil { return .noActionableNowPlayingItem }
            let lastState = state
            togglePlayPause()
            if lastState.isPlaybackInactive {
                guard (state.isLoadingStateActive && autoPlay) || state.isPlaybackActive else { return .commandFailed }
            } else {
                guard state.isPlaybackInactive else { return .commandFailed }
            }
        case .nextTrack:
            return .commandFailed
        case .previousTrack:
            return .commandFailed
        case .changePlaybackRate:
            guard let currentItem = currentItem,
                  let event = event as? MPChangePlaybackRateCommandEvent,
                  currentItem.canPlay(at: .custom(event.playbackRate)) else { return .commandFailed }
            rate = .custom(event.playbackRate)
        case .seekBackward:
            guard let currentItem = currentItem,
                  let event = event as? MPSeekCommandEvent,
                  currentItem.canPlayFastReverse else { return .commandFailed }
            play(at: event.type == .beginSeeking ? AKPlaybackRate(rate: -3) : AKPlaybackRate(rate: 1))
        case .seekForward:
            guard let currentItem = currentItem,
                  let event = event as? MPSeekCommandEvent,
                  currentItem.canPlayFastForward else { return .commandFailed }
            play(at: event.type == .beginSeeking ? AKPlaybackRate(rate: 3) : AKPlaybackRate(rate: 1))
        case .skipBackward:
            guard let currentItem = currentItem,
                  let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            guard currentItem.canSeek(to: CMTime(seconds: currentTime.seconds - event.interval, preferredTimescale: configuration.preferredTimeScale)) else {
                return .commandFailed
            }
            seek(toOffset: event.interval)
        case .skipForward:
            guard let currentItem = currentItem,
                  let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            guard currentItem.canSeek(to: CMTime(seconds: currentTime.seconds + event.interval, preferredTimescale: configuration.preferredTimeScale)) else {
                return .commandFailed
            }
            seek(toOffset: event.interval)
        case .changePlaybackPosition:
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            seek(to: event.positionTime)
        case .enableLanguageOption:
            guard let _ = event as? MPChangeLanguageOptionCommandEvent else { return .commandFailed }
            return .commandFailed
        case .disableLanguageOption:
            guard let _ = event as? MPChangeLanguageOptionCommandEvent else { return .commandFailed }
            return .commandFailed
        case .changeRepeatMode:
            guard let event = event as? MPChangeRepeatModeCommandEvent else { return .commandFailed }
            return .commandFailed
        case .changeShuffleMode:
            guard let event = event as? MPChangeShuffleModeCommandEvent else { return .commandFailed }
            return .commandFailed
        case .rating:
            guard let event = event as? MPRatingCommandEvent else { return .commandFailed }
            return .commandFailed
        case .like:
            guard let event = event as? MPFeedbackCommandEvent else { return .commandFailed }
            return .commandFailed
        case .dislike:
            guard let event = event as? MPFeedbackCommandEvent else { return .commandFailed }
            return .commandFailed
        case .bookmark:
            guard let event = event as? MPFeedbackCommandEvent else { return .commandFailed }
            return .commandFailed
        }
        return .success
    }
    
    // MARK: - Commands
    
    open func load(media: AKPlayable) {
        guard canPlay() else { return actionNotPermitted() }
        playerController.load(media: media)
    }
    
    open func load(media: AKPlayable,
                   autoPlay: Bool) {
        guard canPlay() else { return actionNotPermitted() }
        if autoPlay {
            return performPlaybackAction {
                playerController.load(media: media,
                                      autoPlay: autoPlay)
            }
        }
        playerController.load(media: media,
                              autoPlay: autoPlay)
    }
    
    open func load(media: AKPlayable,
                   autoPlay: Bool,
                   at position: CMTime) {
        guard canPlay() else { return actionNotPermitted() }
        if autoPlay {
            return performPlaybackAction {
                playerController.load(media: media,
                                      autoPlay: autoPlay,
                                      at: position)
            }
        }
        playerController.load(media: media,
                              autoPlay: autoPlay,
                              at: position)
    }
    
    open func load(media: AKPlayable,
                   autoPlay: Bool,
                   at position: Double) {
        guard canPlay() else { return actionNotPermitted() }
        if autoPlay {
            return performPlaybackAction {
                playerController.load(media: media,
                                      autoPlay: autoPlay,
                                      at: position)
            }
        }
        playerController.load(media: media,
                              autoPlay: autoPlay,
                              at: position)
    }
    
    open func play() {
        guard canPlay() else { return actionNotPermitted() }
        performPlaybackAction { playerController.play() }
    }
    
    open func play(at rate: AKPlaybackRate) {
        guard canPlay() else { return actionNotPermitted() }
        performPlaybackAction { playerController.play(at: rate) }
    }
    
    open func pause() {
        playerController.pause()
    }
    
    open func togglePlayPause() {
        switch state {
        case .loaded where !autoPlay, .paused, .stopped, .failed:
            guard canPlay() else { return actionNotPermitted() }
            performPlaybackAction { playerController.togglePlayPause() }
        default:
            playerController.togglePlayPause()
        }
    }
    
    open func stop() {
        playerStateSnapshot?.shouldResume = false
        playerController.stop()
    }
    
    open func seek(to time: CMTime,
                   toleranceBefore: CMTime,
                   toleranceAfter: CMTime,
                   completionHandler: @escaping (Bool) -> Void) {
        playerController.seek(to: time,
                              toleranceBefore: toleranceBefore,
                              toleranceAfter: toleranceAfter,
                              completionHandler: completionHandler)
    }
    
    open func seek(to time: CMTime,
                   toleranceBefore: CMTime,
                   toleranceAfter: CMTime) {
        playerController.seek(to: time,
                              toleranceBefore: toleranceBefore,
                              toleranceAfter: toleranceAfter)
    }
    
    open func seek(to time: CMTime,
                   completionHandler: @escaping (Bool) -> Void) {
        playerController.seek(to: time,
                              completionHandler: completionHandler)
    }
    
    open func seek(to time: CMTime) {
        playerController.seek(to: time)
    }
    
    open func seek(to time: Double,
                   completionHandler: @escaping (Bool) -> Void) {
        playerController.seek(to: time,
                              completionHandler: completionHandler)
    }
    
    open func seek(to time: Double) {
        playerController.seek(to: time)
    }
    
    open func seek(to date: Date,
                   completionHandler: @escaping (Bool) -> Void) {
        playerController.seek(to: date,
                              completionHandler: completionHandler)
    }
    
    open func seek(to date: Date) {
        playerController.seek(to: date)
    }
    
    open func seek(toOffset offset: Double) {
        playerController.seek(toOffset: offset)
    }
    
    open func seek(toOffset offset: Double,
                   completionHandler: @escaping (Bool) -> Void) {
        playerController.seek(toOffset: offset,
                              completionHandler: completionHandler)
    }
    
    open func seek(toPercentage percentage: Double,
                   completionHandler: @escaping (Bool) -> Void) {
        playerController.seek(toPercentage: percentage,
                              completionHandler: completionHandler)
    }
    
    open func seek(toPercentage percentage: Double) {
        playerController.seek(toPercentage: percentage)
    }
    
    open func step(by count: Int) {
        playerController.step(by: count)
    }
    
    open func fastForward() {
        guard canPlay() else { return actionNotPermitted() }
        performPlaybackAction { [unowned self] in
            playerController.fastForward()
        }
    }
    
    open func fastForward(at rate: AKPlaybackRate) {
        guard canPlay() else { return actionNotPermitted() }
        performPlaybackAction { [unowned self] in
            playerController.fastForward(at: rate)
        }
    }
    
    open func rewind() {
        guard canPlay() else { return actionNotPermitted() }
        performPlaybackAction { [unowned self] in
            playerController.rewind()
        }
    }
    
    open func rewind(at rate: AKPlaybackRate) {
        guard canPlay() else { return actionNotPermitted() }
        performPlaybackAction { [unowned self] in
            playerController.rewind(at: rate)
        }
    }
    
    // MARK: - Additional Helper Functions
    
    private func startObservers() {
        audioSessionInterruptionObserver.startObserving()
        audioSessionRouteChangesObserver.startObserving()
        audioSessionMediaServicesWereResetObserver.startObserving()
        applicationLifeCycleEventsObserver.startObserving()
    }
    
    private func stopObservers() {
        audioSessionInterruptionObserver.stopObserving()
        audioSessionRouteChangesObserver.stopObserving()
        audioSessionMediaServicesWereResetObserver.stopObserving()
        applicationLifeCycleEventsObserver.stopObserving()
    }
    
    private func setAudioSession(_ active: Bool) throws {
        guard active else {
            return try audioSessionService.activate(false,
                                                    options: configuration.audioSession.activeOptions)
        }
        
        try audioSessionService.setCategory(configuration.audioSession.category,
                                            mode: configuration.audioSession.mode,
                                            options: configuration.audioSession.categoryOptions)
        try audioSessionService.activate(true,
                                         options: configuration.audioSession.activeOptions)
    }
    
    private func setNowPlayingSessionActive() throws {
        guard nowPlayingSessionController.canBecomeActive() else { throw AKPlayerError.nowPlayingSessionFailure }
        Task.init { await nowPlayingSessionController.becomeActiveIfPossible() }
    }
    
    private func execute(block: () throws -> Void,
                         completion: (Bool) -> Void = { _ in }) {
        do {
            try block()
            return completion(true)
        } catch let error {
            delegate?.playerManager(self, didFailWith: error as! AKPlayerError)
        }
        return completion(false)
    }
    
    private func savePlayerStateSnapshot(playbackInterruptionReason: AKPlaybackInterruptionReason,
                                         shouldResume: Bool) {
        guard var snapshot = playerStateSnapshot else {
            playerStateSnapshot = AKPlayerStateSnapshot(state: state,
                                                        shouldResume: shouldResume,
                                                        applicationState: applicationLifeCycleEventsObserver.state,
                                                        playbackInterruptionReason: playbackInterruptionReason)
            return
        }
        
        snapshot.state = state
        snapshot.applicationState = applicationLifeCycleEventsObserver.state
        
        self.playerStateSnapshot = snapshot
    }
    
    private func clearPlayerStateSnapshot() {
        playerStateSnapshot = nil
    }
    
    private func getNowPlayableDynamicMetadata() -> AKNowPlayableDynamicMetadataProtocol? {
        guard let currentMedia = currentMedia else { return nil }
        let position = currentMedia.isLive() ? nil : currentItem?.currentTime().isValid ?? false ? Double(currentItem!.currentTime().seconds) : nil
        let duration = currentMedia.isLive() ? nil : currentItem?.duration.isValid ?? false ? Float(currentItem!.duration.seconds) : nil
        let playbackProgress = currentMedia.isLive() ? nil : (position != nil) && (duration != nil) ? Float(duration! / Float(currentItem!.currentTime().seconds)) : nil
        
        let nynamicMetadata = AKNowPlayableDynamicMetadata(rate: Double(rate.rate),
                                                           defaultRate: Double(defaultRate.rate),
                                                           position: position,
                                                           duration: duration,
                                                           currentLanguageOptions: nil,
                                                           availableLanguageOptionGroups: nil,
                                                           chapterCount: nil,
                                                           chapterNumber: nil,
                                                           creditsStartTime: nil,
                                                           currentPlaybackDate: nil,
                                                           playbackProgress: playbackProgress,
                                                           playbackQueueCount: nil,
                                                           playbackQueueIndex: nil,
                                                           serviceIdentifier: nil)
        return nynamicMetadata
    }
    
    private func actionNotPermitted() {
        delegate?.playerManager(self,
                                unavailableActionWith: .actionNotPermitted)
    }
    
    private func performPlaybackAction(action: () -> Void) {
        guard let snapshot = playerStateSnapshot else { return action() }
        if snapshot.playbackInterruptionReason.isLifeCycleEvent
            || snapshot.applicationState.isResignActiveOrBackground {
            execute {
                try setAudioSession(true)
            } completion: { finished in
                if finished {
                    action()
                }
            }
        } else {
            action()
        }
        clearPlayerStateSnapshot()
    }
}

// MARK: - AKAudioSessionInterruptionObserverDelegate

extension AKPlayerManager: AKAudioSessionInterruptionObserverDelegate {
    
    public func audioSessionInterruptionObserver(_ observer: AKAudioSessionInterruptionObserverProtocol,
                                                 didBeginInterruptionWith reason: AVAudioSession.InterruptionReason?,
                                                 for audioSession: AVAudioSession) {
        
        guard state.isLoadingStateActive
                || state.isPlaybackActive else { return }
        /* Audio session automatically pauses player, if not will be paused here.
         Update the UI to indicate that playback or recording has paused when it’s interrupted. Do not deactivate the audio session. */
        savePlayerStateSnapshot(playbackInterruptionReason: .audioSessionInterruption,
                                shouldResume: true)
        pause()
    }
    
    public func audioSessionInterruptionObserver(_ observer: AKAudioSessionInterruptionObserverProtocol,
                                                 didEndInterruptionWith shouldResume: Bool,
                                                 for audioSession: AVAudioSession) {
        
        guard configuration.playbackResumesWhenAudioSessionInterruptionEnded,
              let snapshot = playerStateSnapshot,
              snapshot.playbackInterruptionReason == .audioSessionInterruption,
              snapshot.shouldResume && shouldResume else { return }
        play()
    }
}

// MARK: - AKAudioSessionInterruptionObserverDelegate

extension AKPlayerManager: AKAudioSessionRouteChangesObserverDelegate {
    
    public func audioSessionRouteChangesObserver(_ observer: AKAudioSessionRouteChangesObserverProtocol,
                                                 didChangeRouteTo currentRoute: AVAudioSessionRouteDescription,
                                                 from previousRoute: AVAudioSessionRouteDescription?,
                                                 with reason: AVAudioSession.RouteChangeReason) {
        
        defer { isExternalAudioPlaybackDeviceConnected = observer.isExternalDeviceConnected() }
        
        guard isExternalAudioPlaybackDeviceConnected
                && !observer.isExternalDeviceConnected()
                && state.isLoadingStateActive
                || state.isPlaybackActive else {
            return
        }
        
        pause()
    }
}

// MARK: - AKAudioSessionMediaServicesResetObserverDelegate

extension AKPlayerManager: AKAudioSessionMediaServicesResetObserverDelegate {
    
    public func audioSessionMediaServicesResetObserver(_ observer: AKAudioSessionMediaServicesWereResetObserverProtocol,
                                                       mediaServicesWereResetFor audioSession: AVAudioSession) {
        stop()
    }
}

// MARK: - AKApplicationLifeCycleEventsObserverDelegate

extension AKPlayerManager: AKApplicationLifeCycleEventsObserverDelegate {
    
    public func applicationLifeCycleEventsObserver(_ observer: AKApplicationLifeCycleEventsObserverProtocol,
                                                   on event: AKApplicationLifeCycleEvent) {
        switch event {
        case .willResignActive:
            
            if configuration.playbackPausesWhenResigningActive {
                
                if state.isLoadingStateActive
                    || state.isPlaybackActive {
                    
                    savePlayerStateSnapshot(playbackInterruptionReason: .applicationResignActive,
                                            shouldResume: true)
                    pause()
                }
                
                execute { try self.setAudioSession(false) }
                
            } else {
                
                if (state.isLoadingStateActive && !autoPlay)
                    || state.isPlaybackInactive {
                    
                    savePlayerStateSnapshot(playbackInterruptionReason: .applicationResignActive,
                                            shouldResume: false)
                    execute { try self.setAudioSession(false) }
                }
            }
        case .didBecomeActive:
            
            guard configuration.playbackResumesWhenBecameActive,
                  let snapshot = playerStateSnapshot,
                  snapshot.playbackInterruptionReason.isLifeCycleEvent,
                  snapshot.shouldResume else { return }
            
            play()
            
        case .didEnterBackground:
            
            if configuration.playbackPausesWhenBackgrounded {
                
                if state.isLoadingStateActive
                    || state.isPlaybackActive {
                    
                    savePlayerStateSnapshot(playbackInterruptionReason: .applicationEnteredBackground,
                                            shouldResume: true)
                    pause()
                }
                
                execute { try self.setAudioSession(false) }
                
            } else {
                
                if (state.isLoadingStateActive && !autoPlay)
                    || state.isPlaybackInactive {
                    
                    savePlayerStateSnapshot(playbackInterruptionReason: .applicationEnteredBackground,
                                            shouldResume: false)
                    execute { try self.setAudioSession(false) }
                }
            }
        case .willEnterForeground:
            
            guard configuration.playbackResumesWhenEnteringForeground,
                  let snapshot = playerStateSnapshot,
                  snapshot.playbackInterruptionReason.isLifeCycleEvent,
                  snapshot.shouldResume else { return }
            
            play()
        }
    }
}

// MARK: - AKNowPlayingSessionControllerDelegate

extension AKPlayerManager: AKNowPlayingSessionControllerDelegate {
    
    public func nowPlayingSessionController(_ controller: AKNowPlayingSessionControllerProtocol,
                                            didReceive command: AKRemoteCommand,
                                            with event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        handleRemoteCommand(command, with: event)
    }
}

// MARK: - AKPlayerControllerDelegate

extension AKPlayerManager: AKPlayerControllerDelegate {
    
    public func playerController(_ playerController: AKPlayerControllerProtocol,
                                 didChangeStateTo state: AKPlayerState) {
        updateNowPlayingControl()
        setNowPlayingInfo()
        delegate?.playerManager(self,
                                didChangeStateTo: state)
    }
    
    public func playerController(_ playerController: AKPlayerControllerProtocol,
                                 didChangeMediaTo media: AKPlayable) {
        setNowPlayingInfo()
        delegate?.playerManager(self,
                                didChangeMediaTo: media)
    }
    
    public func playerController(_ playerController: AKPlayerControllerProtocol,
                                 didChangePlaybackRateTo newRate: AKPlaybackRate,
                                 from oldRate: AKPlaybackRate) {
        setNowPlayingInfo()
        delegate?.playerManager(self,
                                didChangePlaybackRateTo: newRate, from: oldRate)
    }
    
    public func playerController(_ playerController: AKPlayerControllerProtocol,
                                 didChangeCurrentTimeTo currentTime: CMTime,
                                 for media: AKPlayable) {
        setNowPlayingInfo()
        delegate?.playerManager(self,
                                didChangeCurrentTimeTo: currentTime,
                                for: media)
    }
    
    public func playerController(_ playerController: AKPlayerControllerProtocol,
                                 playerItemDidReachEnd endTime: CMTime,
                                 for media: AKPlayable) {
        setNowPlayingInfo()
        delegate?.playerManager(self,
                                playerItemDidReachEnd: endTime,
                                for: media)
    }
    
    public func playerController(_ playerController: AKPlayerControllerProtocol,
                                 didChangeVolumeTo volume: Float) {
        setNowPlayingInfo()
        delegate?.playerManager(self,
                                didChangeVolumeTo: volume)
    }
    
    public func playerController(_ playerController: AKPlayerControllerProtocol,
                                 didChangeMutedStatusTo isMuted: Bool) {
        setNowPlayingInfo()
        delegate?.playerManager(self,
                                didChangeMutedStatusTo: isMuted)
    }
    
    public func playerController(_ playerController: AKPlayerControllerProtocol,
                                 unavailableActionWith reason: AKPlayerUnavailableCommandReason) {
        setNowPlayingInfo()
        delegate?.playerManager(self,
                                unavailableActionWith: reason)
    }
    
    public func playerController(_ playerController: AKPlayerControllerProtocol,
                                 didFailWith error: AKPlayerError) {
        setNowPlayingInfo()
        delegate?.playerManager(self,
                                didFailWith: error)
    }
}
