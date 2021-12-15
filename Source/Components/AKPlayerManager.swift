//
//  AKPlayerManager.swift
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
import Foundation
import MediaPlayer

final class AKPlayerManager: NSObject, AKPlayerManagerProtocol {
    
    // MARK: - Properties
    
    private(set) var currentMedia: AKPlayable? {
        didSet {
            guard let media = currentMedia else { assertionFailure("Media should available"); return }
            plugins?.forEach({$0.playerPlugin(didChanged: media)})
        }
    }
    
    var currentItem: AVPlayerItem? {
        return currentMedia?.playerItem
    }
    
    var currentTime: CMTime {
        return player.currentTime()
    }
    
    var duration: CMTime? {
        return currentItem?.duration
    }
    
    var state: AKPlayerState {
        return controller.state
    }
    
    var rate: AKPlaybackRate {
        get { return _rate }
        set { changePlaybackRate(with: newValue) }
    }
    
    var volume: Float {
        get { return player.volume }
        set { player.volume = newValue }
    }
    
    var isMuted: Bool {
        get { return player.isMuted }
        set { player.isMuted = newValue }
    }
    
    var isPlaying: Bool {
        get { return state == .buffering
            || state == .playing
            || state == .waitingForNetwork
        }
    }
    
    var isAutoPlay: Bool {
        get { return state == .loading && (controller as? AKLoadingState)?.autoPlay ?? false
            || state == .loaded && (controller as? AKLoadedState)?.autoPlay ?? false
        }
    }
    
    var isSeeking: Bool {
        return !(requestedSeekingTime == nil)
    }
    
    var error: Error? {
        return (controller as? AKFailedState)?.error
    }
    
    private(set) var configuration: AKPlayerConfiguration
    
    private(set) var controller: AKPlayerStateControllerProtocol! {
        get {
            guard let controller = _controller else { preconditionFailure("Call `prepare` before performing any action") }
            return controller
        }set {
            _controller = newValue
            controller.stateDidChange()
            delegate?.playerManager(didStateChange: controller.state)
            UIApplication.shared.isIdleTimerDisabled = configuration.idleTimerDisabledForStates.contains(controller.state)
        }
    }
    
    weak var delegate: AKPlayerManagerDelegate?
    
    var plugins: [AKPlayerPlugin]? {
        return _plugins.allObjects.compactMap({($0 as? AKPlayerPlugin)})
    }
    
    private(set) var playingBeforeInterruption: Bool = false
    
    private(set) var playbackInterruptionReason: AKPlaybackInterruptionReason = .none
    
    var remoteCommands: [AKRemoteCommand] = []
    
    private(set) var requestedSeekingTime: CMTime?
    
    let player: AVPlayer
    
    private var _controller: AKPlayerStateControllerProtocol!
    
    private var _rate: AKPlaybackRate = .normal
    
    private var _plugins = NSHashTable<AnyObject>.weakObjects()
    
    let audioSessionService: AKAudioSessionServiceable
    
    private(set) var playerNowPlayingMetadataService: AKPlayerNowPlayingMetadataServiceable?
    
    private(set) var remoteCommandController: AKRemoteCommandController?
    
    private(set) var audioSessionInterruptionEventProducer: AKAudioSessionInterruptionEventProducible!
    
    private(set) var playerRateEventProducer: AKPlayerRateEventProducible!
    
    private(set) var managingAudioOutputEventProducer: AKManagingAudioOutputEventProducible!
    
    private(set) var routeChangeEventProducer: AKRouteChangeEventProducible!
    
    private(set) var mediaServicesResetEventProducer: AKMediaServicesResetEventProducible!
    
    private(set) var applicationEventProducer: AKApplicationEventProducible!
    
    // MARK: - Init
    
    init(player: AVPlayer,
         plugins: [AKPlayerPlugin],
         configuration: AKPlayerConfiguration,
         audioSessionService: AKAudioSessionServiceable = AKAudioSessionService(),
         remoteCommandController: AKRemoteCommandController = AKRemoteCommandController()) {
        self.player = player
        self.configuration = configuration
        self.audioSessionService = audioSessionService
        self.remoteCommandController = remoteCommandController
        super.init()
        
        plugins.forEach({self._plugins.add($0)})
        
        if configuration.isNowPlayingEnabled {
            playerNowPlayingMetadataService = AKPlayerNowPlayingMetadataService()
            remoteCommandController.manager = self
        }
    }
    
    deinit {
        _plugins.removeAllObjects()
        playerNowPlayingMetadataService?.clearNowPlayingPlaybackInfo()
        remoteCommandController?.disable(commands: AKRemoteCommand.all())
    }
    
    func prepare() {
        audioSessionInterruptionEventProducer = AKAudioSessionInterruptionEventProducer(audioSession: audioSessionService.audioSession)
        playerRateEventProducer = AKPlayerRateEventProducer(with: player)
        managingAudioOutputEventProducer = AKManagingAudioOutputEventProducer(with: player)
        routeChangeEventProducer = AKRouteChangeEventProducer(audioSession: audioSessionService.audioSession)
        mediaServicesResetEventProducer = AKMediaServicesResetEventProducer(audioSession: audioSessionService.audioSession)
        applicationEventProducer = AKApplicationEventProducer()
        
        audioSessionInterruptionEventProducer.eventListener = self
        playerRateEventProducer.eventListener = self
        managingAudioOutputEventProducer.eventListener = self
        routeChangeEventProducer.eventListener = self
        mediaServicesResetEventProducer.eventListener = self
        applicationEventProducer.eventListener = self
        
        audioSessionService.activate(true,
                                     options: configuration.audioSession.activeOptions)
        audioSessionService.setCategory(configuration.audioSession.category,
                                        mode: configuration.audioSession.mode,
                                        options: configuration.audioSession.categoryOptions)
        
        startListeningEvents()
        controller = AKIdleState(manager: self)
    }
    
    func change(_ controller: AKPlayerStateControllerProtocol) {
        self.controller = controller
    }
    
    func startListeningEvents() {
        audioSessionInterruptionEventProducer.startProducingEvents()
        playerRateEventProducer.startProducingEvents()
        managingAudioOutputEventProducer.startProducingEvents()
        routeChangeEventProducer.startProducingEvents()
        mediaServicesResetEventProducer.startProducingEvents()
        applicationEventProducer.startProducingEvents()
    }
    
    func stopListeningEvents() {
        audioSessionInterruptionEventProducer.stopProducingEvents()
        playerRateEventProducer.stopProducingEvents()
        managingAudioOutputEventProducer.stopProducingEvents()
        routeChangeEventProducer.stopProducingEvents()
        mediaServicesResetEventProducer.stopProducingEvents()
        applicationEventProducer.stopProducingEvents()
    }
    
    // MARK: - Commands
    
    func load(media: AKPlayable) {
        currentMedia = media
        controller.load(media: media)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool) {
        currentMedia = media
        controller.load(media: media,
                        autoPlay: autoPlay)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: CMTime) {
        currentMedia = media
        controller.load(media: media,
                        autoPlay: autoPlay,
                        at: position)
    }
    
    func load(media: AKPlayable,
              autoPlay: Bool,
              at position: Double) {
        currentMedia = media
        controller.load(media: media,
                        autoPlay: autoPlay,
                        at: position)
    }
    
    func play() {
        controller.play()
    }
    
    func pause() {
        controller.pause()
    }
    
    func togglePlayPause() {
        controller.togglePlayPause()
    }
    
    func stop() {
        controller.stop()
    }
    
    func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: @escaping (Bool) -> Void) {
        seek(to: time, with: (toleranceBefore, toleranceAfter), completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
        seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter) { (_) in }
    }
    
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void) {
        seek(to: time, with: nil, completionHandler: completionHandler)
    }
    
    func seek(to time: CMTime) {
        seek(to: time) { (_) in }
    }
    
    func seek(to time: Double,
              completionHandler: @escaping (Bool) -> Void) {
        seek(to: CMTime(seconds: time,
                        preferredTimescale: configuration.preferredTimescale),
             completionHandler: completionHandler)
    }
    
    func seek(to time: Double) {
        seek(to: time) { (finished) in }
    }
    
    func seek(to date: Date, completionHandler: @escaping (Bool) -> Void) {
        controller.seek(to: date, completionHandler: completionHandler)
    }
    
    func seek(to date: Date) {
        controller.seek(to: date)
    }
    
    func seek(offset: Double) {
        let position = currentTime.seconds + offset
        seek(to: position)
    }
    
    func seek(offset: Double,
              completionHandler: @escaping (Bool) -> Void) {
        let position = currentTime.seconds + offset
        seek(to: position,
             completionHandler: completionHandler)
    }
    
    func seek(toPercentage value: Double,
              completionHandler: @escaping (Bool) -> Void) {
        seek(to: (duration?.seconds ?? 0) * value,
             completionHandler: completionHandler)
    }
    
    func seek(toPercentage value: Double) {
        seek(to: ((duration?.seconds ?? 0) * value))
    }
    
    func step(byCount stepCount: Int) {
        guard let item = currentItem else { unaivalableCommand(reason: .loadMediaFirst); return }
        
        let stepService = AKSteppingThroughMediaEventProducer(with: item)
        
        let result = stepService.canStep(byCount: stepCount)
        
        if result.canStep {
            controller.step(byCount: stepCount)
        } else if let reason = result.reason {
            unaivalableCommand(reason: reason)
        } else {
            assertionFailure("BoundedPosition should return at least value or reason")
        }
    }
    
    // MARK: - Additional Helper Functions
    
    private func seek(to time: CMTime, with tolerance: (before: CMTime, after: CMTime)?,
                      completionHandler: @escaping (Bool) -> Void) {
        
        guard let item = currentItem else {
            unaivalableCommand(reason: .loadMediaFirst)
            completionHandler(false)
            return }
        
        item.cancelPendingSeeks()
        
        let seekingThroughMediaService = AKSeekingThroughMediaService(with: item,
                                                                      configuration: configuration)
        let result = seekingThroughMediaService.boundedTime(time)
        
        if let seekTime = result.time {
            requestedSeekingTime = seekTime
            if let tolerance = tolerance {
                controller.seek(to: seekTime, toleranceBefore: tolerance.before, toleranceAfter: tolerance.after) { [weak self] (finished) in
                    guard let strongSelf = self else { return }
                    strongSelf.requestedSeekingTime = nil
                    completionHandler(finished)
                }
            }else {
                controller.seek(to: seekTime) { [weak self] (finished) in
                    guard let strongSelf = self else { return }
                    strongSelf.requestedSeekingTime = nil
                    if !finished { strongSelf.delegate?.playerManager(didCurrentTimeChange: strongSelf.player.currentTime() )}
                    completionHandler(finished)
                }
            }
        } else if let reason = result.reason {
            unaivalableCommand(reason: reason)
            completionHandler(false)
        } else {
            assertionFailure("BoundedPosition should return at least value or reason")
        }
    }
    
    @discardableResult private func changePlaybackRate(with rate: AKPlaybackRate) -> Bool {
        if rate == _rate { return true }
        defer {
            delegate?.playerManager(didPlaybackRateChange: rate)
        }
        if rate.rate == 0.0 {
            pause()
            _rate = .normal
        }else {
            guard let item = currentItem else { _rate = rate; return  false }
            if AKDeterminingPlaybackCapabilitiesEventProducer.itemCanBePlayed(at: rate, for: item) {
                _rate = rate
                if controller.state == .buffering
                    || controller.state == .playing
                    || controller.state == .waitingForNetwork {
                    player.rate = rate.rate
                }
            }
        }
        return true
    }
    
    private func unaivalableCommand(reason: AKPlayerUnavailableActionReason) {
        delegate?.playerManager(unavailableAction: reason)
        AKPlayerLogger.shared.log(message: reason.description,
                                  domain: .unavailableCommand)
    }
    
    public func setNowPlayingMetadata() {
        guard configuration.isNowPlayingEnabled,
              let playerNowPlayingMetadataService = playerNowPlayingMetadataService,
              let remoteCommandController = remoteCommandController,
              let media = currentMedia else { return }
        remoteCommandController.enable(commands: remoteCommands)
        if let staticMetadata = media.staticMetadata  {
            playerNowPlayingMetadataService.setNowPlayingMetadata(staticMetadata)
        }else {
            let assetMetadata = AKMediaMetadata(with: currentItem?.asset.commonMetadata ?? [])
            var artwork: MPMediaItemArtwork?
            if let artworkData = assetMetadata.artwork, let image = UIImage(data: artworkData) {
                artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size in
                    return image
                })
            }
            let metadata = AKNowPlayableStaticMetadata(assetURL: media.url,
                                                       mediaType: .video,
                                                       isLiveStream: media.isLive(),
                                                       title: assetMetadata.title ?? "AKPlayer",
                                                       artist: assetMetadata.artist,
                                                       artwork: artwork == nil ? nil : .artwork(artwork!),
                                                       albumArtist: assetMetadata.artist,
                                                       albumTitle: assetMetadata.albumName)
            playerNowPlayingMetadataService.setNowPlayingMetadata(metadata)
        }
    }
    
    public func setNowPlayingPlaybackInfo() {
        guard configuration.isNowPlayingEnabled,
              let playerNowPlayingMetadataService = playerNowPlayingMetadataService else { return }
        var playbackRate: Float = 0
        let currentTime: Float = Float(player.currentTime().seconds)
        
        switch player.timeControlStatus {
        case .waitingToPlayAtSpecifiedRate, .paused:
            playbackRate = 0
        case .playing:
            playbackRate = 1
        @unknown default:
            // FIXME: - Need to add
            break
        }
        
        let metadata = AKNowPlayableDynamicMetadata(rate: playbackRate,
                                                    position: currentTime,
                                                    duration: (duration?.seconds == nil) ? nil : (Float(duration!.seconds) - 10),
                                                    currentLanguageOptions: [],
                                                    availableLanguageOptionGroups: [])
        playerNowPlayingMetadataService.setNowPlayingPlaybackInfo(metadata)
    }
    
    func handleRemoteCommand(command: AKRemoteCommand, with event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        switch command {
        case .pause:
            if isPlaying || state == .paused || state == .stopped || state == .failed {
                pause()
                return .success
            }
            return .commandFailed
        case .play:
            if state == .idle {
                return .noSuchContent
            }
            play()
            return .success
        case .stop:
            if isPlaying
                || state == .paused
                || state == .stopped {
                stop()
                return .success
            }
            return .commandFailed
        case .togglePlayPause:
            if state == .idle {
                return .noSuchContent
            }
            togglePlayPause()
            return .success
        case .nextTrack:
            return .commandFailed
        case .previousTrack:
            return .commandFailed
        case .changePlaybackRate:
            guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            guard !changePlaybackRate(with: .custom(event.playbackRate)) else { return .commandFailed }
        case .seekBackward:
            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
            guard !changePlaybackRate(with: event.type == .beginSeeking ? .custom(-3.0) : .normal) else { return .commandFailed }
        case .seekForward:
            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
            guard !changePlaybackRate(with: event.type == .beginSeeking ? .custom(3.0) : .normal) else { return .commandFailed }
        case .skipBackward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            seek(offset: -event.interval)
        case .skipForward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            seek(offset: event.interval)
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
}

// MARK: - AKEventListener

extension AKPlayerManager: AKEventListener {
    
    func onEvent(_ event: AKEvent, generetedBy eventProducer: AKEventProducer) {
        if let event = event as? AKAudioSessionInterruptionEventProducer.AudioSessionInterruptionEvent {
            switch event {
            case .interruptionBegan:
                playingBeforeInterruption = isPlaying
                switch controller.state {
                case .idle: break
                case .loading: pause()
                case .loaded: pause()
                case .buffering: pause()
                case .playing: pause()
                case .waitingForNetwork: pause()
                case .paused: break
                case .stopped: break
                case .failed: break
                }
            case .interruptionEnded(shouldResume: let shouldResume):
                if shouldResume
                    && playingBeforeInterruption
                    && .audioSessionInterrupted == playbackInterruptionReason {
                    play()
                }
            }
        } else if let event = event as? AKRouteChangeEventProducer.RouteChangeEvent {
            switch event {
            case .routeChanged(changeReason: let changeReason, currentRoute: _, previousRoute: _):
                print("Change reason : ", changeReason.rawValue)
            }
        } else if let _ = event as? AKMediaServicesResetEventProducer.MediaServicesResetEvent {
            
        } else if let event = event as? AKApplicationEventProducer.ApplicationEvent {
            switch event {
            case .willResignActive:
                if configuration.playbackPausesWhenResigningActive
                    && isPlaying {
                    playbackInterruptionReason = .applicationResignActive
                    playingBeforeInterruption = isPlaying
                    pause()
                }
            case .didBecomeActive:
                if configuration.playbackResumesWhenBecameActive
                    && !isPlaying
                    && .applicationResignActive == playbackInterruptionReason
                    && playingBeforeInterruption {
                    playbackInterruptionReason = .none
                    playingBeforeInterruption = false
                    play()
                }
            case .didEnterBackground:
                if configuration.playbackPausesWhenBackgrounded
                    && isPlaying {
                    playbackInterruptionReason = .applicationEnteredBackground
                    playingBeforeInterruption = isPlaying
                    pause()
                }
            case .willEnterForeground:
                if configuration.playbackResumesWhenEnteringForeground
                    && !isPlaying
                    && .applicationEnteredBackground == playbackInterruptionReason
                    && playingBeforeInterruption {
                    playbackInterruptionReason = .none
                    playingBeforeInterruption = false
                    play()
                }
            }
        } else if let event = event as? AKPlayerRateEventProducer.PlayerRateEvent {
            switch event {
            case .rateChanged(to: let newRate, from: let oldRate):
                AKPlayerLogger.shared.log(message: "Rate changed to \(newRate.rate) from \(oldRate.rate)",
                                          domain: .service)
                setNowPlayingPlaybackInfo()
            }
        } else if let event = event as? AKManagingAudioOutputEventProducer.ManagingAudioOutputEvent {
            switch event {
            case .volumeChanged(let volume):
                delegate?.playerManager(didVolumeChange: volume,
                                        isMuted: isMuted)
                plugins?.forEach({$0.playerPlugin(didVolumeChange: volume,
                                                  isMuted: isMuted)})
            case .isMuted(let isMuted):
                delegate?.playerManager(didVolumeChange: volume,
                                        isMuted: isMuted)
                plugins?.forEach({$0.playerPlugin(didVolumeChange: volume,
                                                  isMuted: isMuted)})
            }
        }
        
    }
}
