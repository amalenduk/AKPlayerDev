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
    
    internal private(set) var currentMedia: AKPlayable? {
        didSet {
            guard let media = currentMedia else { assertionFailure("Media should available"); return }
            plugins?.forEach({$0.playerPlugin(didChanged: media)})
        }
    }
    
    internal var currentItem: AVPlayerItem? {
        return player.currentItem
    }
    
    internal var currentTime: CMTime {
        return player.currentTime()
    }
    
    internal var itemDuration: CMTime? {
        return currentItem?.duration
    }
    
    internal unowned let player: AVPlayer
    
    internal var state: AKPlayer.State {
        return controller.state
    }
    
    internal var playbackRate: AKPlaybackRate {
        get { return _playbackRate }
        set { changePlaybackRate(with: newValue) }
    }
    
    private var _playbackRate: AKPlaybackRate = .normal
    
    internal var volume: Float {
        get { return player.volume }
        set { player.volume = newValue }
    }
    
    internal var isMuted: Bool {
        get { return player.isMuted }
        set { player.isMuted = newValue }
    }
    
    internal var isPlaying: Bool {
        get { return state == .buffering
            || state == .playing
            || state == .waitingForNetwork
            || state == .loading && (controller as? AKLoadingState)?.autoPlay ?? false
            || state == .loaded && (controller as? AKLoadedState)?.autoPlay ?? false
        }
    }
    
    internal var brightness: CGFloat {
        get { return UIScreen.main.brightness }
        set {
            UIScreen.main.brightness = (newValue >= 0 && newValue <= 1) ? newValue : brightness
            UIScreen.main.wantsSoftwareDimming = true
        }
    }
    
    var error: Error? {
        return (controller as? AKFailedState)?.error
    }
    
    private var _plugins = NSHashTable<AnyObject>.weakObjects()
    
    internal var plugins: [AKPlayerPlugin]? {
        return _plugins.allObjects.compactMap({($0 as? AKPlayerPlugin)})
    }
    
    internal private(set) var configuration: AKPlayerConfiguration
    
    internal private(set) var controller: AKPlayerStateControllable! {
        didSet {
            controller.stateChanged()
            delegate?.playerManager(didStateChange: controller.state)
            UIApplication.shared.isIdleTimerDisabled = configuration.idleTimerDisabledForStates.contains(controller.state)
        }
    }
    
    internal private(set) var audioSessionInterrupted: Bool = false
    
    internal weak var delegate: AKPlayerManagerDelegate?
    
    internal let audioSessionService: AKAudioSessionServiceable
    
    internal private(set) var playerNowPlayingMetadataService: AKPlayerNowPlayingMetadataServiceable?
    
    internal private(set) var remoteCommandsService: AKNowPlayableCommandService?
    
    internal private(set) var playerRateObservingService: AKPlayerRateObservingService!
    
    internal private(set) var audioSessionInterruptionObservingService: AKAudioSessionInterruptionObservingServiceable!
    
    internal private(set) var managingAudioOutputService: AKManagingAudioOutputService!

    internal private(set) var screenBrightnessObservingService: AKScreenBrightnessObservingService!
    
    internal private(set) var playingBeforeInterruption: Bool = false
    
    // MARK: - Init
    
    internal init(player: AVPlayer,
                  plugins: [AKPlayerPlugin],
                  configuration: AKPlayerConfiguration,
                  audioSessionService: AKAudioSessionServiceable = AKAudioSessionService()) {
        self.player = player
        self.configuration = configuration
        self.audioSessionService = audioSessionService
        super.init()
        plugins.forEach({self._plugins.add($0)})
        
        setAudioSessionActivate(true)
        setAudioSessionCategory()
        startPlaybackRateObserving()
        startManagingAudioOutputService()
        startScreenBrightnessObserving()
        
        if configuration.isNowPlayingEnabled {
            playerNowPlayingMetadataService = AKPlayerNowPlayingMetadataService()
            remoteCommandsService = AKNowPlayableCommandService(with: self,
                                                                configuration: configuration)
            remoteCommandsService?.enable()
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterInBackground(_ :)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        defer {
            controller = AKInitState(manager: self)
        }
    }
    
    deinit {
        _plugins.removeAllObjects()
        AKNowPlayableCommand.allCases.forEach({$0.removeHandler()})
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification,
                                                  object: nil)
        UIScreen.main.wantsSoftwareDimming = false
    }
    
    internal func change(_ controller: AKPlayerStateControllable) {
        self.controller = controller
    }
    
    // MARK: - Observers
    
    @objc func didEnterInBackground(_ notification: Notification) {
        if configuration.pauseInBackground
            && isPlaying { pause() }
    }
    
    // MARK: - Commands
    
    internal func load(media: AKPlayable) {
        currentMedia = media
        controller.load(media: media)
    }
    
    internal func load(media: AKPlayable,
                       autoPlay: Bool) {
        currentMedia = media
        controller.load(media: media,
                        autoPlay: autoPlay)
    }
    
    internal func load(media: AKPlayable,
                       autoPlay: Bool,
                       at position: CMTime) {
        currentMedia = media
        controller.load(media: media,
                        autoPlay: autoPlay,
                        at: position)
    }
    
    internal func load(media: AKPlayable,
                       autoPlay: Bool,
                       at position: Double) {
        currentMedia = media
        controller.load(media: media,
                        autoPlay: autoPlay,
                        at: position)
    }
    
    internal func play() {
        controller.play()
    }
    
    internal func pause() {
        controller.pause()
    }
    
    internal func stop() {
        controller.stop()
    }
    
    internal func seek(to time: CMTime,
                       completionHandler: @escaping (Bool) -> Void) {
        guard let item = currentItem else { unaivalableCommand(reason: .loadMediaFirst);
            completionHandler(false); return }
        
        let seekingThroughMediaService = AKSeekingThroughMediaService(with: item,
                                                                      configuration: configuration)
        let result = seekingThroughMediaService.boundedTime(time)
        
        if let seekTime = result.time {
            controller.seek(to: seekTime,
                            completionHandler: completionHandler)
        } else if let reason = result.reason {
            unaivalableCommand(reason: reason)
            completionHandler(false)
        } else {
            assertionFailure("BoundedPosition should return at least value or reason")
        }
    }
    
    internal func seek(to time: CMTime) {
        guard let item = currentItem else { unaivalableCommand(reason: .loadMediaFirst); return }
        
        let seekingThroughMediaService = AKSeekingThroughMediaService(with: item,
                                                                      configuration: configuration)
        let result = seekingThroughMediaService.boundedTime(time)
        
        if let seekTime = result.time {
            controller.seek(to: seekTime)
        } else if let reason = result.reason {
            unaivalableCommand(reason: reason)
        } else {
            assertionFailure("BoundedPosition should return at least value or reason")
        }
    }
    
    internal func seek(to time: Double,
                       completionHandler: @escaping (Bool) -> Void) {
        seek(to: CMTime(seconds: time,
                        preferredTimescale: configuration.preferredTimescale),
             completionHandler: completionHandler)
    }
    
    internal func seek(to time: Double) {
        seek(to: CMTime(seconds: time,
                        preferredTimescale: configuration.preferredTimescale))
    }
    
    internal func seek(offset: Double) {
        let position = currentTime.seconds + offset
        seek(to: position)
    }
    
    internal func seek(offset: Double,
                       completionHandler: @escaping (Bool) -> Void) {
        let position = currentTime.seconds + offset
        seek(to: position,
             completionHandler: completionHandler)
    }
    
    internal func seek(toPercentage value: Double,
                       completionHandler: @escaping (Bool) -> Void) {
        seek(to: (itemDuration?.seconds ?? 0) * value,
             completionHandler: completionHandler)
    }
    
    internal func seek(toPercentage value: Double) {
        seek(to: (itemDuration?.seconds ?? 0) * value)
    }
    
    internal func step(byCount stepCount: Int) {
        guard let item = currentItem else { unaivalableCommand(reason: .loadMediaFirst); return }
        
        let stepService = AKSteppingThroughMediaService(with: item)

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
    
    private func startPlaybackRateObserving() {
        playerRateObservingService = AKPlayerRateObservingService(with: player)
        playerRateObservingService?.onChangePlaybackRate = { [unowned self] playbackRate in
            AKPlayerLogger.shared.log(message: "Rate changed \(playbackRate.rate)",
                                      domain: .service)
            setNowPlayingPlaybackInfo()
        }
    }
    
    private func changePlaybackRate(with rate: AKPlaybackRate) {
        if rate == _playbackRate { return }
        defer {
            delegate?.playerManager(didPlaybackRateChange: playbackRate)
        }
        if rate.rate == 0.0 {
            pause()
            _playbackRate = .normal
        }else {
            guard let item = currentItem else { _playbackRate = rate; return }
            if AKDeterminingPlaybackCapabilitiesService.itemCanBePlayed(at: rate, for: item) {
                _playbackRate = rate
                if controller.state == .buffering
                    || controller.state == .playing
                    || controller.state == .waitingForNetwork {
                    player.rate = rate.rate
                }
            }
        }
    }
    
    private func unaivalableCommand(reason: AKPlayerUnavailableActionReason) {
        delegate?.playerManager(unavailableAction: reason)
        AKPlayerLogger.shared.log(message: reason.description,
                                  domain: .unavailableCommand)
    }
    
    private func setAudioSessionActivate(_ active: Bool) {
        audioSessionService.activate(active)
    }
    
    private func setAudioSessionCategory() {
        audioSessionService.setCategory(configuration.audioSessionCategory,
                                        mode: configuration.audioSessionMode,
                                        options: configuration.audioSessionCategoryOptions)
    }
    
    public func setNowPlayingMetadata() {
        guard configuration.isNowPlayingEnabled,
              let playerNowPlayingMetadataService = playerNowPlayingMetadataService,
              let media = currentMedia else { return }
        if let staticMetadata = media.staticMetadata  {
            playerNowPlayingMetadataService.setNowPlayingMetadata(staticMetadata)
        }else {
            let assetMetadata = AKMediaMetadata(with: currentItem?.asset.commonMetadata ?? [])
            let metadata = AKNowPlayableStaticMetadata(assetURL: media.url,
                                                       mediaType: .video,
                                                       isLiveStream: media.isLive(),
                                                       title: assetMetadata.title ?? "AKPlayer",
                                                       artist: assetMetadata.artist,
                                                       artwork: MPMediaItemArtwork(boundsSize: CGSize(width: 50, height: 50), requestHandler: { size in
                                                        return (UIImage(data: assetMetadata.artwork ?? Data()) ?? UIImage())
                                                       }),
                                                       albumArtist: assetMetadata.artist,
                                                       albumTitle: assetMetadata.albumName)
            playerNowPlayingMetadataService.setNowPlayingMetadata(metadata)
        }
    }
    
    public func setNowPlayingPlaybackInfo() {
        guard configuration.isNowPlayingEnabled,
              let playerNowPlayingMetadataService = playerNowPlayingMetadataService else { return }
        let metadata = AKNowPlayableDynamicMetadata(rate: player.rate,
                                                    position: Float(currentTime.seconds),
                                                    duration: Float(player.currentItem?.duration.seconds ?? 0),
                                                    currentLanguageOptions: [],
                                                    availableLanguageOptionGroups: [])
        playerNowPlayingMetadataService.setNowPlayingPlaybackInfo(metadata)
    }
    
    private func startAudioSessionInterruptionObserving() {
        audioSessionInterruptionObservingService = AKAudioSessionInterruptionObservingService(audioSession: audioSessionService.audioSession)
        
        audioSessionInterruptionObservingService.onInterruptionBegan = { [unowned self] in
            playingBeforeInterruption = isPlaying
            audioSessionInterrupted = true
        }
        
        audioSessionInterruptionObservingService.onInterruptionEnded = { [unowned self] shouldResume in
            audioSessionInterrupted = false
            if playingBeforeInterruption
                && shouldResume
                && !audioSessionService.audioSession.secondaryAudioShouldBeSilencedHint{
                play()
            }
        }
    }
    
    private func startManagingAudioOutputService() {
        managingAudioOutputService = AKManagingAudioOutputService(with: player)
        
        managingAudioOutputService.onChangeVolume = { [unowned self] volume in
            delegate?.playerManager(didVolumeChange: volume,
                                    isMuted: isMuted)
            plugins?.forEach({$0.playerPlugin(didVolumeChange: volume,
                                              isMuted: isMuted)})
        }
        
        managingAudioOutputService.onChangePlayerIsMuted = { [unowned self] isMuted in
            delegate?.playerManager(didVolumeChange: volume,
                                    isMuted: isMuted)
            plugins?.forEach({$0.playerPlugin(didVolumeChange: volume,
                                              isMuted: isMuted)})
        }

        managingAudioOutputService.startObserving()
    }

    private func startScreenBrightnessObserving() {
        screenBrightnessObservingService = AKScreenBrightnessObservingService()

        screenBrightnessObservingService.onbBrightnessChange = { [unowned self] brightness in
            delegate?.playerManager(didBrightnessChange: brightness)
        }
    }
}
