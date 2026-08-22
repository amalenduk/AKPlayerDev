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

// https://hls-js.netlify.app/demo/

import AVFoundation
import AKPlayer
import UIKit
import Combine

class SimpleVideoViewController: UIViewController {
    
    // MARK: - Outlates
    
    @IBOutlet weak private var stateLabel: UILabel!
    @IBOutlet weak private var currentTimeLabel: UILabel!
    @IBOutlet weak private var durationLabel: UILabel!
    @IBOutlet weak private var rateLabel: UILabel!
    @IBOutlet weak private var playerVideoLayer: AKPlayerView!
    @IBOutlet weak private var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak private var debugMessageLabel: UILabel!
    @IBOutlet weak private var timeSlider: AKProgressAndTimeRangesSlider!
    @IBOutlet weak private var rateButton: UIButton!
    @IBOutlet weak private var assetInfoButton: UIButton!
    @IBOutlet weak private var audioButton: UIButton!
    @IBOutlet weak private var subtitleButton: UIButton!
    @IBOutlet weak private var volumeSlider: UISlider!
    @IBOutlet weak private var autoPlaySwitch: UISwitch!
    @IBOutlet weak private var muteButton: UIButton!
    @IBOutlet weak private var stepBackwardButton: UIButton!
    @IBOutlet weak private var stepForwardButton: UIButton!
    
    let aVplayer = AVPlayer()
    
    private lazy var player: AKPlayer = {
        var configuration = AKPlayerConfiguration()
        configuration.isNowPlayingEnabled = true
        let player = AKPlayer(player: aVplayer, configuration: configuration, audioSessionService: audioSession)
        player.player.appliesMediaSelectionCriteriaAutomatically = true
        return player
    }()
    
    var items: [Any] = []
    var reverseItems: [Any] = []
    var isTracking: Bool = false
    static let session = AVAudioSession.sharedInstance()
    let audioSession = AKAudioSessionService(audioSession: session)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Simple Video"
        guard let videoLayer = playerVideoLayer.layer as? AVPlayerLayer else { return }
        playerVideoLayer.player = aVplayer
        videoLayer.player = player.player
        player.delegate = self
        do {
            try player.prepare()
        } catch {
            print(error.localizedDescription)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterInBackground(_ :)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterInForeground(_ :)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        if #available(iOS 13.0, *) {
            reloadRateMenus()
        } else {
            rateButton.addTarget(self, action: #selector(rateChangeButtonAction(_ :)), for: .touchUpInside)
        }
        timeSlider.addTarget(self, action: #selector(progressSliderDidStartTracking(_ :)), for: [.touchDown])
        timeSlider.addTarget(self, action: #selector(progressSliderDidEndTracking(_ :)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
        timeSlider.addTarget(self, action: #selector(progressSliderDidChangedValue(_ :)), for: [.valueChanged])
        
        timeSlider.minimumValue = 0
        timeSlider.maximumValue = 1
        timeSlider.value = 0
        
        volumeSlider.value = player.volume
        
        muteButton.setTitle("Mute", for: .normal)
        muteButton.setTitle("Muted", for: .selected)
        
        muteButton.isSelected = player.isMuted
        
        audioButton.addTarget(self, action: #selector(audioButtonAction(_ :)), for: .touchUpInside)
        subtitleButton.addTarget(self, action: #selector(subtitleButtonAction(_ :)), for: .touchUpInside)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // MARK: - Additional Helpers
    
    open func setSliderProgress(_ currentTime: Double, itemDuration: Double) {
        guard !isTracking else { return }
        if !timeSlider.isTracking {
            timeSlider.value = Float(currentTime / itemDuration)
        }
    }
    
    private func setDebugMessage(_ msg: String?) {
        debugMessageLabel.text = msg
        debugMessageLabel.alpha = 1.0
        UIView.animate(withDuration: 1.5) { self.debugMessageLabel.alpha = 0 }
    }
    
    func reloadRateMenus() {
        let destruct = UIAction(title: "Cancel", attributes: .destructive) { _ in }
        items.removeAll()
        reverseItems.removeAll()
        
        for rate in AKPlaybackRate.allCases {
            let action = UIAction(title: rate.rateTitle, identifier: UIAction.Identifier.init("\(rate.rate)"), state: rate == player.rate ? .on : .off) { [unowned self] _ in
                // player.rate = rate
                player.play(at: .custom(rate.rate))
            }
            items.append(action)
        }
        
        for rate in AKPlaybackRate.allCases {
            let action = UIAction(title: ("-" + rate.rateTitle), identifier: UIAction.Identifier.init("\(-rate.rate)"), state: .off) { [unowned self] _ in
                // player.rate = .custom(-rate.rate)
                player.play(at: .custom(rate.rate))
            }
            reverseItems.append(action)
        }
        
        let menu = UIMenu(title: "Rate", options: .displayInline, children: [destruct, UIMenu(title: "Rate", options: .displayInline, children: items as! [UIAction]), UIMenu(title: "Reverse", options: .destructive, children: reverseItems as! [UIAction])])
        
        if #available(iOS 14.0, *) {
            rateButton.menu = menu
            rateButton.showsMenuAsPrimaryAction = true
        }
    }

    // Public API to load media programmatically
    public func load(media: AKMedia, autoPlay: Bool) {
        media.delegate = self
        player.load(media: media, autoPlay: autoPlay)
    }
    
    @objc func audioButtonAction(_ sender: UIButton) {
        guard let asset = self.player.currentItem?.asset else { return }
        Task {
            let group = try await asset.loadMediaSelectionGroup(for: .audible)
            
            guard let group, group.options.count > 0 else { setDebugMessage("No tracks found"); return }
            let alert = UIAlertController(title: "Audio", message: "Select", preferredStyle: .actionSheet)
            
            for option in group.options {
                let action = UIAlertAction(title: option.displayName, style: .default) { (_) in
                    self.player.currentMedia?.playerItem?.select(option, in: group)
                }
                alert.addAction(action)
            }
            
            if group.allowsEmptySelection {
                let action = UIAlertAction(title: "Off", style: .default) { (_) in
                    self.player.currentMedia?.playerItem?.select(nil, in: group)
                }
                alert.addAction(action)
            }
            let destruct = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
            alert.addAction(destruct)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func subtitleButtonAction(_ sender: UIButton) {
        guard let asset = self.player.currentItem?.asset else { return }
        Task {
            let group = try await asset.loadMediaSelectionGroup(for: .legible)
            
            guard let group, group.options.count > 0 else { setDebugMessage("No subtitles found"); return }
            let alert = UIAlertController(title: "Subtitle", message: "Select", preferredStyle: .actionSheet)
            
            for option in group.options {
                let action = UIAlertAction(title: option.displayName, style: .default) { (_) in
                    self.player.currentMedia?.playerItem?.select(option, in: group)
                }
                alert.addAction(action)
            }
            
            if group.allowsEmptySelection {
                let action = UIAlertAction(title: "Off", style: .default) { (_) in
                    self.player.currentMedia?.playerItem?.select(nil, in: group)
                }
                alert.addAction(action)
            }
            let destruct = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
            alert.addAction(destruct)
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - User Interactions
    
    @IBAction func updateNowPlayingInfoButtonActon(_ sender: Any) {
        player.currentItem?.textStyleRules = nil
    }
    
    @objc func rateChangeButtonAction(_ sender: UIButton) {
        player.rate = player.rate.next
    }
    
    @IBAction func infoButtonAction(_ sender: Any) {
        //        let vc = storyboard?.instantiateViewController(withIdentifier: "AssetInfoViewController") as! AssetInfoViewController
        //        let navVc = UINavigationController(rootViewController: vc)
        //        vc.assetInfo = AKMediaMetadata(with: player.currentItem?.asset.commonMetadata ?? [])
        //        present(navVc, animated: true, completion: nil)
        // print(CMTIME_IS_POSITIVEINFINITY(player.currentTime))
    }
    
    @objc func progressSliderDidStartTracking(_ slider: UISlider) {
        isTracking = true
    }
    
    @objc func progressSliderDidEndTracking(_ slider: UISlider) {
        if player.currentMedia?.isLive() ?? false {
            player.seek(to: CMTimeMakeWithSeconds((player.currentMedia!.getLivePosition().seconds * Double(slider.value)), preferredTimescale: CMTimeScale(NSEC_PER_SEC))) { _ in
                self.isTracking = false
            }
        } else {
            player.seek(to: CMTimeMakeWithSeconds(((player.currentItem?.duration.seconds ?? 0) * Double(slider.value)), preferredTimescale: CMTimeScale(NSEC_PER_SEC))) { _ in
                self.isTracking = false
            }
        }
    }
    
    @objc func progressSliderDidChangedValue(_ slider: UISlider) {
        //        let time = CMTimeMakeWithSeconds(((player.currentItem?.duration.seconds ?? 0) * Double(slider.value)), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        //        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
        //            self.isTracking = false
        //        }
    }
    
    @IBAction func play(_ sender: UIButton) {
        player.play()
        
        
        print(player.state)
    }
    
    @IBAction func pause(_ sender: UIButton) {
        player.pause()
    }
    
    @IBAction func stop(_ sender: Any) {
        player.stop()
    }
    
    @IBAction func load(_ sender: Any) {
        guard let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8") else { return }
        let headers = ["User-Agent": "AVPlayer/1.0"]
        let staticMetadata = AKNowPlayableStaticMetadata(assetURL: url, mediaType: .video, isLiveStream: false, title:"Akplayer", artist:"Akplayer", artwork: .image(UIImage(named: "artwork.example")!), albumArtist: "Amar maa", albumTitle: "Anik")
        let media = AKMedia(url: url, type: .clip, assetInitializationOptions: ["AVURLAssetHTTPHeaderFieldsKey": headers], automaticallyLoadedAssetKeys: [.duration,
                                                                                                                                                          .creationDate,
                                                                                                                                                .lyrics,
                                                                                                                                                          .isPlayable,
                                                                                                                                                          .metadata,
                                                                                                                                                          .commonMetadata,
                                                                                                                                                          .metadata,
                                                                                                                                                          .availableMetadataFormats,
                                                                                                                                                          .availableMediaCharacteristicsWithMediaSelectionOptions],
                            staticMetadata: staticMetadata)
        media.delegate = self
        player.load(media: media, autoPlay: autoPlaySwitch.isOn)
    }
    
    @IBAction func testButtonAction(_ sender: Any) {
        //        NotificationCenter.default.post(
        //            name: AVAudioSession.routeChangeNotification,
        //            object: AVAudioSession.sharedInstance(),
        //            userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue])
        
        //        NotificationCenter.default.post(
        //            name: AVAudioSession.interruptionNotification,
        //            object: SimpleVideoViewController.session,
        //            userInfo: [
        //                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue,
        //                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
        //            ])
        
        //player.player.replaceCurrentItem(with: nil)
        try? audioSession.audioSession.setActive(false)
        //        print(CMTimeGetSeconds(player.currentMedia!.getLivePosition()) , "", CMTimeGetSeconds(player.currentMedia!.currentTime), player.currentMedia!.configuredTimeOffsetFromLive.seconds)
        //        player.seek(to: player.currentMedia!.getLivePosition().seconds - 0.01)
        
        
    }
    
    @IBAction func testTwoButtonAction(_ sender: Any) {
        //        NotificationCenter.default.post(
        //            name: AVAudioSession.interruptionNotification,
        //            object: SimpleVideoViewController.session,
        //            userInfo: [
        //                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
        //                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
        //            ])
        
        player.player.play()
        
        // player.addBoundaryTimeObserver(for: [CMTime(seconds: 100, preferredTimescale: CMTimeScale(NSEC_PER_SEC))])
        //player.player.replaceCurrentItem(with: nil)
    }
    
    @IBAction func changeAudioTrackButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func brightnessSliderDidChageValue(_ sender: UISlider) {
    }
    
    @IBAction func changeSubtitleButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func stepForward(_ sender: UIButton) {
        player.step(by: 1)
    }
    
    @IBAction func stepBackward(_ sender: UIButton) {
        player.step(by: -1)
    }
    
    @IBAction func prevSeek(_ sender: UIButton) {
        player.seek(toOffset: -15)
    }
    
    @IBAction func nextSeek(_ sender: UIButton) {
        player.seek(toOffset: 15)
    }
    
    @IBAction func onChapTersAction(_ sender: Any) {
        
    }
    
    @IBAction func enableNowPlayingInfo(_ sender: Any) {
        
    }
    
    @IBAction func disableNowPlayingInfo(_ sender: Any) {
    }
    
    // MARK: - Observers
    
    @objc func didEnterInBackground(_ notification: Notification) {
        playerVideoLayer.player = nil
    }
    
    @IBAction func muteUnMuteAction(_ sender: Any) {
        muteButton.isSelected = !muteButton.isSelected
        player.isMuted = muteButton.isSelected
    }
    
    @IBAction func volumeSliderChanged(_ sender: UISlider) {
        player.volume = sender.value
    }
    
    @objc func didEnterInForeground(_ notification: Notification) {
        playerVideoLayer.player = player.player
    }
    
}

// MARK: - AKPlayerDelegate


extension SimpleVideoViewController: AKPlayerDelegate {
    
    func akPlayer(_ player: AKPlayer, didChangeMediaTo media: AKPlayable) {
    }
    
    func akPlayer(_ player: AKPlayer, didChangeVolumeTo volume: Float) {
        volumeSlider.value = volume
    }
    
    func akPlayer(_ player: AKPlayer, didChangeMutedStatusTo isMuted: Bool) {
        muteButton.isSelected = isMuted
    }
    
    func akPlayer(_ player: AKPlayer, didChangeStateTo state: AKPlayerState) {
        DispatchQueue.main.async {
            self.stateLabel.text = "State: " + state.description
            if state == .waitingForNetwork || state == .buffering || state == .loading {
                self.indicatorView.startAnimating()
            }else {
                self.indicatorView.stopAnimating()
            }
        }
    }
    
    func akPlayer(_ player: AKPlayer, didChangeCurrentTimeTo currentTime: CMTime, for media: AKPlayable) {
        DispatchQueue.main.async {
            if media.isLive() {
                self.currentTimeLabel.text = "Current Timing: " + "\(player.seekPosition?.time.stringValue ?? currentTime.stringValue)"
                
                self.currentTimeLabel.textColor = media.isLivePositionCloseToLive() ? .red : .green
                
                self.setSliderProgress(player.seekPosition?.time.seconds ?? currentTime.seconds, itemDuration: media.getLivePosition().seconds)
            } else {
                self.currentTimeLabel.text = "Current Timing: " + "\(currentTime.seconds)"
                self.setSliderProgress(player.seekPosition?.time.seconds ?? currentTime.seconds, itemDuration: player.currentItem?.duration.seconds ?? 0)
            }
        }
    }
    
    func akPlayer(_ player: AKPlayer, didInvokeBoundaryTimeObserverAt time: CMTime, for media: AKPlayable) {
    }
    
    
    func akPlayer(_ player: AKPlayer, didReachEndAt time: CMTime, for media: AKPlayable) {
    }
    
    
    func akPlayer(_ player: AKPlayer, didEncounterUnavailableAction reason: AKPlayerUnavailableCommandReason) {
        DispatchQueue.main.async {
            self.setDebugMessage(reason.description)
        }
    }
    
    func akPlayer(_ player: AKPlayer, didFailWith error: AKPlayerError) {
        DispatchQueue.main.async {
            self.setDebugMessage(error.localizedDescription)
        }
    }
    
    func akPlayer(_ player: AKPlayer, didChangePlaybackRateTo newRate: AKPlaybackRate, from oldRate: AKPlaybackRate) {
        rateLabel.text = "Rate: \(newRate.rateTitle)"
        if #available(iOS 13.0, *) {
            reloadRateMenus()
        }
    }
}

// MARK: - AKPlaybackDelegate

extension SimpleVideoViewController: AKMediaDelegate {
    
    func akMedia(_ media: AKPlayable, didChangeItemDuration itemDuration: CMTime) {
        DispatchQueue.main.async {
            if media.isLive() {
                self.durationLabel.text = "Duration: " + "Live"
            } else {
                self.durationLabel.text = "Duration: " + itemDuration.stringValue
            }
        }
    }
    
    func akMedia(_ media: AKPlayable, didChangeCanStepForwardStatus canStepForward: Bool) {
        DispatchQueue.main.async {
            // self.stepForwardButton.isEnabled = canStepForward
        }
        
    }
    
    func akMedia(_ media: AKPlayable, didChangeCanStepBackwardStatus canStepBackward: Bool) {
        DispatchQueue.main.async {
            // self.stepBackwardButton.isEnabled = canStepBackward
        }
        
    }
    
    func akMedia(_ media: AKPlayable, didChangeLoadedTimeRanges loadedTimeRanges: [NSValue]) {
        var availableDuration: Double {
            guard let timeRange = player.currentItem?.loadedTimeRanges.first?.timeRangeValue else {
                return 0.0
            }
            let startSeconds = timeRange.start.seconds
            let durationSeconds = timeRange.duration.seconds
            return startSeconds + durationSeconds
        }
        DispatchQueue.main.async {
            self.timeSlider.itemDuration = self.player.currentItemDuration
            self.timeSlider.loadedTimeRanges = loadedTimeRanges.map { $0.timeRangeValue }
        }
    }
    
    func akMedia(_ media: AKPlayable,
                 didChangeSeekableTimeRanges seekableTimeRanges: [NSValue]) {
    }
    
    func akPlayback(_ media: AKPlayable, didChangeTracks tracks: [AVPlayerItemTrack]) {
    }
}
