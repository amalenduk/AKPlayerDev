//
//  SimpleVideoViewController.swift
//  AKPlayer_Example
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

import SwiftUI
import AKPlayer
import AVFoundation
import Combine
import Foundation

public class SimpleVideoPlayerViewModel: NSObject, ObservableObject {
    public let aVplayer = AVPlayer()
    
    public lazy var player: AKPlayer = {
        var configuration = AKPlayerConfiguration()
        configuration.isNowPlayingEnabled = true
        let p = AKPlayer(player: aVplayer, configuration: configuration, audioSessionService: audioSession)
        p.player.appliesMediaSelectionCriteriaAutomatically = true
        p.delegate = self
        return p
    }()
    
    static let session = AVAudioSession.sharedInstance()
    let audioSession = AKAudioSessionService(audioSession: session)
    
    @Published public var stateDescription: String = ""
    @Published public var currentTime: Double = 0
    @Published public var duration: Double = 0
    @Published public var volume: Float = 1.0
    @Published public var isMuted: Bool = false
    @Published public var canStepForward: Bool = false
    @Published public var canStepBackward: Bool = false
    @Published public var debugInfo: String?
    @Published public var playbackRate: AKPlaybackRate = .normal
    @Published public var bufferedRanges: [ClosedRange<Double>] = []
    @Published public var isLoading: Bool = false
    @Published public var unavailableMessage: String?
    @Published public var lastLoadedMedia: AKMedia?
    @Published public var autoPlayEnabled: Bool = true
    // Media selection groups (audio / subtitles)
    @Published public var selectionGroups: [SelectionGroup] = []
    
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()
    private var clearUnavailableWorkItem: DispatchWorkItem?
    
    // Models for selection sheet
    public struct SelectionOption: Identifiable {
        public let id = UUID()
        public let title: String
        public let option: AVMediaSelectionOption?
        public let isSelected: Bool
    }
    
    public struct SelectionGroup: Identifiable {
        public let id = UUID()
        public let characteristic: AVMediaCharacteristic
        public let title: String
        public var options: [SelectionOption]
    }
    
    override public init() {
        super.init()
        try? player.prepare()
    }
    
    public func load(media: AKMedia, autoPlay: Bool) {
        media.delegate = self
        self.lastLoadedMedia = media
        player.load(media: media, autoPlay: autoPlay)
    }
    
    public func reload(autoPlay: Bool) {
        guard let m = lastLoadedMedia else { return }
        load(media: m, autoPlay: autoPlay)
    }
    
    // MARK: - Media selection
    public func refreshSelectionGroups() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let item = self.player.player.currentItem else {
                DispatchQueue.main.async { self.selectionGroups = [] }
                return
            }
            let asset = item.asset
            var groups: [SelectionGroup] = []
            let chars: [AVMediaCharacteristic] = [.audible, .legible]
            for c in chars {
                if let group = asset.mediaSelectionGroup(forMediaCharacteristic: c) {
                    let selected = item.selectedMediaOption(in: group)
                    var opts: [SelectionOption] = []
                    // Add an 'Auto / None' option
                    let autoSelected = (selected == nil)
                    opts.append(SelectionOption(title: "Auto", option: nil, isSelected: autoSelected))
                    for opt in group.options {
                        let name = opt.displayName ?? opt.extendedLanguageTag ?? opt.locale?.identifier ?? "Unknown"
                        let isSel = (selected == opt)
                        opts.append(SelectionOption(title: name, option: opt, isSelected: isSel))
                    }
                    let title = (c == .audible) ? "Audio" : "Subtitles"
                    groups.append(SelectionGroup(characteristic: c, title: title, options: opts))
                }
            }
            DispatchQueue.main.async { self.selectionGroups = groups }
        }
    }
    
    public func select(option: SelectionOption, in group: SelectionGroup) {
        DispatchQueue.main.async {
            guard let item = self.player.player.currentItem else { return }
            // find AVMediaSelectionGroup again
            guard let avGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: group.characteristic) else { return }
            item.select(option.option, in: avGroup)
            // refresh state
            self.refreshSelectionGroups()
        }
    }
    
    public func play() { player.play() }
    public func pause() { player.pause() }
    public func stop() { player.stop() }
    public func setVolume(_ v: Float) { player.volume = v; volume = v }
    public func toggleMute() { player.isMuted = !player.isMuted; isMuted = player.isMuted }
    public func seek(to seconds: Double) {
        player.seek(to: seconds)
    }
    public func step(by count: Int) { player.step(by: count) }
    public func seekOffset(_ offset: Double) { player.seek(toOffset: offset) }
    public func setRate(_ rate: AKPlaybackRate) { player.play(at: .custom(rate.rate)) }
    public func loadAndObserveCurrentTime() {
        // remove existing
        if let token = timeObserverToken { player.player.removeTimeObserver(token); timeObserverToken = nil }
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let dur = self.player.currentItem?.duration.seconds, dur.isFinite { self.duration = dur }
        }
    }
    deinit {
        if let token = timeObserverToken { player.player.removeTimeObserver(token) }
    }
}

extension SimpleVideoPlayerViewModel: AKPlayerDelegate {
    public func akPlayer(_ player: AKPlayer, didChangeStateTo state: AKPlayerState) {
        DispatchQueue.main.async {
            self.stateDescription = state.description
            self.isLoading = (state == .waitingForNetwork || state == .buffering || state == .loading)
        }
    }
    public func akPlayer(_ player: AKPlayer, didChangeCurrentTimeTo currentTime: CMTime, for media: AKPlayable) {
        DispatchQueue.main.async { self.currentTime = currentTime.seconds }
    }
    public func akPlayer(_ player: AKPlayer, didChangePlaybackRateTo newRate: AKPlaybackRate, from oldRate: AKPlaybackRate) {
        DispatchQueue.main.async { self.playbackRate = newRate }
    }
    public func akPlayer(_ player: AKPlayer, didInvokeBoundaryTimeObserverAt time: CMTime, for media: AKPlayable) {}
    public func akPlayer(_ player: AKPlayer, didReachEndAt time: CMTime, for media: AKPlayable) {}
    public func akPlayer(_ player: AKPlayer, didEncounterUnavailableAction reason: AKPlayerUnavailableCommandReason) {
        DispatchQueue.main.async {
            // cancel any pending clear
            self.clearUnavailableWorkItem?.cancel()
            self.unavailableMessage = reason.description
            // schedule auto-clear after 3 seconds
            let work = DispatchWorkItem { [weak self] in
                DispatchQueue.main.async { self?.unavailableMessage = nil }
            }
            self.clearUnavailableWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
        }
    }
    public func akPlayer(_ player: AKPlayer, didFailWith error: AKPlayerError) {}
    public func akPlayer(_ player: AKPlayer, didChangeVolumeTo volume: Float) {}
    public func akPlayer(_ player: AKPlayer, didChangeMutedStatusTo isMuted: Bool) {}
}

extension SimpleVideoPlayerViewModel: AKMediaDelegate {
    public func akMedia(_ media: AKPlayable, didChangeItemDuration itemDuration: CMTime) {
        DispatchQueue.main.async {
            if itemDuration.isNumeric && itemDuration.seconds.isFinite {
                self.duration = itemDuration.seconds
            }
        }
    }
    public func akMedia(_ media: AKPlayable, didChangeCanStepForwardStatus canStepForward: Bool) {}
    public func akMedia(_ media: AKPlayable, didChangeCanStepBackwardStatus canStepBackward: Bool) {}
    public func akMedia(_ media: AKPlayable, didChangeLoadedTimeRanges loadedTimeRanges: [NSValue]) {
        DispatchQueue.main.async {
            guard self.duration > 0 else { self.bufferedRanges = []; return }
            let ranges = loadedTimeRanges.compactMap { (ns: NSValue) -> ClosedRange<Double>? in
                let tr = ns.timeRangeValue
                let start = tr.start.seconds
                let end = tr.start.seconds + tr.duration.seconds
                guard start.isFinite && end.isFinite else { return nil }
                return start...end
            }
            self.bufferedRanges = ranges
        }
    }
    public func akMedia(_ media: AKPlayable, didChangeSeekableTimeRanges seekableTimeRanges: [NSValue]) {}
    public func akPlayback(_ media: AKPlayable, didChangeTracks tracks: [AVPlayerItemTrack]) {}
}
