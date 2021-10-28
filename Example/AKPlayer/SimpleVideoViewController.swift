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

var vids = [
    [
        "name": "Big Buck Bunny",
        "description": "2008 ‧ Short/Comedy ‧ 12 mins",
        "imageUrl": "bbb",
        "videoSource": "https://cdn.theoplayer.com/video/big_buck_bunny/big_buck_bunny_metadata.m3u8"
    ],
    [
        "name": "Sintel",
        "description": "2010 ‧ Fantasy/Short ‧ 15 mins",
        "imageUrl": "sintel",
        "videoSource": "https://cdn.theoplayer.com/video/sintel/nosubs.m3u8"
    ],
    [
        "name": "Tears of Steel",
        "description": "2012 ‧ Short/Sci-fi ‧ 12 mins",
        "imageUrl": "tears",
        "videoSource": "https://cdn.theoplayer.com/video/tears_of_steel/index.m3u8"
    ],
    [
        "name": "Elephant's Dream",
        "description": "2006 ‧ Sci-fi/Short ‧ 11 mins",
        "imageUrl": "elephant",
        "videoSource": "https://cdn.theoplayer.com/video/elephants-dream/playlist.m3u8"
    ],
    [
        "name": "Caminandes Llama Drama",
        "description": "2013 ‧ Short/Comedy ‧ 3 mins",
        "imageUrl": "llama",
        "videoSource": "http://amssamples.streaming.mediaservices.windows.net/634cd01c-6822-4630-8444-8dd6279f94c6/CaminandesLlamaDrama4K.ism/manifest(format=m3u8-aapl-v3)"
    ]
]

class SimpleVideoViewController: UIViewController {
    
    // MARK: - Outlates
    
    @IBOutlet weak private var stateLabel: UILabel!
    @IBOutlet weak private var currentTimeLabel: UILabel!
    @IBOutlet weak private var durationLabel: UILabel!
    @IBOutlet weak private var rateLabel: UILabel!
    @IBOutlet weak private var playerVideoLayer: AKPlayerView!
    @IBOutlet weak private var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak private var debugMessageLabel: UILabel!
    @IBOutlet weak private var timeSlider: UISlider!
    @IBOutlet weak private var rateButton: UIButton!
    @IBOutlet weak private var assetInfoButton: UIButton!
    @IBOutlet weak private var audioButton: UIButton!
    @IBOutlet weak private var subtitleButton: UIButton!
    @IBOutlet weak private var volumeSlider: UISlider!
    @IBOutlet weak private var autoPlaySwitch: UISwitch!
    @IBOutlet weak private var muteButton: UIButton!
    @IBOutlet weak private var brightnessSlider: UISlider!
    @IBOutlet weak private var stepBackwardButton: UIButton!
    @IBOutlet weak private var stepForwardButton: UIButton!
    @IBOutlet weak var bufferProgressView: UIProgressView!
    
    private lazy var player: AKPlayer = {
        AKPlayerLogger.setup.domains = []
        var configuration = AKPlayerDefaultConfiguration()
        let rl1 = AVTextStyleRule(textMarkupAttributes: [kCMTextFormatDescriptionRect_Bottom as String: 100, kCMTextMarkupAttribute_BoldStyle as String: kCFBooleanTrue!])
        let rl2 = AVTextStyleRule(textMarkupAttributes: [kCMTextMarkupAttribute_UnderlineStyle as String: kCFBooleanTrue!])
        let rl3 = AVTextStyleRule(textMarkupAttributes: [kCMTextMarkupAttribute_BackgroundColorARGB as String: [1, 1, 0.5, 0.7]])
        let rl4 = AVTextStyleRule(textMarkupAttributes: [kCMTextMarkupAttribute_RelativeFontSize as String: 180])
        
        configuration.textStyleRules = [rl1!, rl2!, rl3!, rl4!]
        let player = AKPlayer(plugins: [self], configuration: configuration, remoteCommandController: AKRemoteCommandController())
        player.player.appliesMediaSelectionCriteriaAutomatically = true
        player.remoteCommands = AKRemoteCommand.playbackCommands + [.seekForward, .seekBackward, .changePlaybackPosition, .skipForward(preferredIntervals: [15]), .skipBackward(preferredIntervals: [15])]
        return player
    }()
    
    var items: [Any] = []
    var reverseItems: [Any] = []
    var isTracking: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Simple Video"
        guard let videoLayer = playerVideoLayer.layer as? AVPlayerLayer else { return }
        videoLayer.player = player.player
        player.delegate = self
        player.prepare()
        
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
        
        bufferProgressView.progress = 0
        
        audioButton.isEnabled = false
        subtitleButton.isEnabled = false
        
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
    
    open func setSliderProgress(_ currentTime: CMTime, itemDuration: CMTime?) {
        guard !isTracking else { return }
        if let itemDuration = itemDuration, itemDuration.isValid && itemDuration.isNumeric, !timeSlider.isTracking {
            timeSlider.value = Float(currentTime.seconds / itemDuration.seconds)
        }
    }
    
    private func setDebugMessage(_ msg: String?) {
        debugMessageLabel.text = msg
        debugMessageLabel.alpha = 1.0
        UIView.animate(withDuration: 1.5) { self.debugMessageLabel.alpha = 0 }
    }
    
    @available(iOS 13.0, *)
    func reloadRateMenus() {
        let destruct = UIAction(title: "Cancel", attributes: .destructive) { _ in }
        items.removeAll()
        reverseItems.removeAll()
        
        for rate in AKPlaybackRate.allCases {
            let action = UIAction(title: rate.rateTitle, identifier: UIAction.Identifier.init("\(rate.rate)"), state: rate == player.rate ? .on : .off) { [unowned self] _ in
                player.rate = rate
            }
            items.append(action)
        }
        
        for rate in AKPlaybackRate.allCases {
            let action = UIAction(title: ("-" + rate.rateTitle), identifier: UIAction.Identifier.init("\(-rate.rate)"), state: .off) { [unowned self] _ in
                player.rate = .custom(-rate.rate)
            }
            reverseItems.append(action)
        }
        
        let menu = UIMenu(title: "Rate", options: .displayInline, children: [destruct, UIMenu(title: "Rate", options: .displayInline, children: items as! [UIAction]), UIMenu(title: "Reverse", options: .destructive, children: reverseItems as! [UIAction])])
        
        if #available(iOS 14.0, *) {
            rateButton.menu = menu
            rateButton.showsMenuAsPrimaryAction = true
        }
    }
    
    @objc func audioButtonAction(_ sender: UIButton) {
        //        guard let audibleGroup =  player.currentMedia?.mediaSelection?.audibleGroup else { return }
        //        guard audibleGroup.options.count > 0 else { setDebugMessage("No tracks found"); return }
        //        let alert = UIAlertController(title: "Audio", message: "Select", preferredStyle: .actionSheet)
        //
        //        for option in audibleGroup.options {
        //            let action = UIAlertAction(title: option.displayName, style: .default) { (_) in
        //                self.player.currentMedia?.mediaSelection?.select(mediaSelectionOption: option, for: .audible)
        //            }
        //            alert.addAction(action)
        //        }
        //
        //        if audibleGroup.allowsEmptySelection {
        //            let action = UIAlertAction(title: "Off", style: .default) { (_) in
        //                self.player.currentMedia?.mediaSelection?.select(mediaSelectionOption: nil, for: .audible)
        //            }
        //            alert.addAction(action)
        //        }
        //        let destruct = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        //        alert.addAction(destruct)
        //        present(alert, animated: true, completion: nil)
    }
    
    @objc func subtitleButtonAction(_ sender: UIButton) {
        //        guard let legibleGroup =  player.currentMedia?.mediaSelection?.legibleGroup else { return }
        //        guard legibleGroup.options.count > 0 else { setDebugMessage("No subtitles found"); return }
        //        let alert = UIAlertController(title: "Subtitle", message: "Select", preferredStyle: .actionSheet)
        //
        //        for option in legibleGroup.options {
        //            let action = UIAlertAction(title: option.displayName, style: .default) { (_) in
        //                self.player.currentMedia?.mediaSelection?.select(mediaSelectionOption: option, for: .legible)
        //            }
        //            alert.addAction(action)
        //        }
        //
        //        if legibleGroup.allowsEmptySelection {
        //            let action = UIAlertAction(title: "Off", style: .default) { (_) in
        //                self.player.currentMedia?.mediaSelection?.select(mediaSelectionOption: nil, for: .legible)
        //            }
        //            alert.addAction(action)
        //        }
        //        let destruct = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        //        alert.addAction(destruct)
        //
        //        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - User Interactions
    
    @IBAction func updateNowPlayingInfoButtonActon(_ sender: Any) {
        player.setNowPlayingMetadata()
        player.setNowPlayingPlaybackInfo()
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
        player.seek(to: CMTime(seconds: ((player.duration?.seconds ?? 0) * Double(slider.value)), preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            self.isTracking = false
        }
    }
    
    @objc func progressSliderDidChangedValue(_ slider: UISlider) {
    }
    
    @IBAction func play(_ sender: UIButton) {
        player.play()
    }
    
    @IBAction func pause(_ sender: UIButton) {
        player.pause()
    }
    
    @IBAction func stop(_ sender: Any) {
        player.stop()
    }
    
    @IBAction func load(_ sender: Any) {
        let url =  URL(string: "https://aac.saavncdn.com/951/92ebdad19552d2313e99532f5a6345f8_320.mp4")!//"https://cdn.theoplayer.com/video/tears_of_steel/index.m3u8")!
        let staticMetadata = AKNowPlayableStaticMetadata(assetURL: url, mediaType: .video, isLiveStream: false, title: "Akplayer", artist: "Gualm habib, nazim amal kar || darun gaan", artwork: .image(UIImage(named: "artwork.example")!), albumArtist: "Amar maa", albumTitle: "Anik")
        let media = AKMedia(url: url, type: .clip, staticMetadata: staticMetadata)
        media.delegate = self
        player.load(media: media, autoPlay: autoPlaySwitch.isOn)
    }
    
    @IBAction func changeAudioTrackButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func brightnessSliderDidChageValue(_ sender: UISlider) {
    }
    
    @IBAction func changeSubtitleButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func stepForward(_ sender: UIButton) {
        player.step(byCount: 1)
    }
    
    @IBAction func stepBackward(_ sender: UIButton) {
        player.step(byCount: -1)
    }
    
    @IBAction func prevSeek(_ sender: UIButton) {
        player.seek(offset: -15)
    }
    
    @IBAction func nextSeek(_ sender: UIButton) {
        player.seek(offset: 15)
    }
    
    @IBAction func onChapTersAction(_ sender: Any) {
        // https://developer.apple.com/documentation/avfoundation/media_playback_and_selection/presenting_chapter_markers
        guard let asset = player.currentItem?.asset else { return }
        let languages = Locale.preferredLanguages
        let chapterMetadata = asset.chapterMetadataGroups(bestMatchingPreferredLanguages: languages)
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
    
    func akPlayer(_ player: AKPlayer, didChangeState state: AKPlayerState) {
        DispatchQueue.main.async {
            self.stateLabel.text = "State: " + state.description
            if state == .waitingForNetwork || state == .buffering || state == .loading {
                self.indicatorView.startAnimating()
            }else {
                self.indicatorView.stopAnimating()
            }
        }
    }
    
    func akPlayer(_ player: AKPlayer, didChangeCurrentTime currentTime: CMTime) {
        DispatchQueue.main.async {
            self.currentTimeLabel.text = "Current Timing: " + String(format: "%.2f", currentTime.seconds)
            self.setSliderProgress(currentTime, itemDuration: player.duration)
        }
    }
    
    func akPlayback(_ media: AKPlayable, didChangeItemDuration itemDuration: CMTime) {
        print("Duration change,", itemDuration.seconds)
        DispatchQueue.main.async {
            self.durationLabel.text = "Duration: " + String(format: "%.2f", itemDuration.seconds)
        }
    }
    
    func akPlayer(_ player: AKPlayer, unavailableAction reason: AKPlayerUnavailableActionReason) {
        DispatchQueue.main.async {
            self.setDebugMessage(reason.description)
        }
    }
    
    func akPlayer(_ player: AKPlayer, didItemPlayToEndTime endTime: CMTime) {
        
    }
    
    func akPlayer(_ player: AKPlayer, didFailedWith error: AKPlayerError) {
        DispatchQueue.main.async {
            self.setDebugMessage(error.localizedDescription)
        }
    }
    
    func akPlayer(_ player: AKPlayer, didChangeVolume volume: Float, isMuted: Bool) {
        volumeSlider.value = volume
        muteButton.isSelected = isMuted
        // print("Player did chaged volume")
    }
    
    func akPlayer(_ player: AKPlayer, didChangePlaybackRate playbackRate: AKPlaybackRate) {
        rateLabel.text = "Rate: \(playbackRate.rateTitle)"
        if #available(iOS 13.0, *) {
            reloadRateMenus()
        }
    }
    
}

// MARK: - AKPlaybackDelegate

extension SimpleVideoViewController: AKPlaybackDelegate {
    
    func akPlayer(_ player: AKPlayer, didChangeItemDuration itemDuration: CMTime) {
        print("Duration change,", itemDuration.seconds)
        DispatchQueue.main.async {
            self.durationLabel.text = "Duration: " + String(format: "%.2f", itemDuration.seconds)
        }
    }
    
    func akPlayback(_ media: AKPlayable, didChangeCanStepForwardStatus canStepForward: Bool) {
        stepForwardButton.isEnabled = canStepForward
    }
    
    func akPlayback(_ media: AKPlayable, didChangeCanStepBackwardStatus canStepBackward: Bool) {
        stepBackwardButton.isEnabled = canStepBackward
    }
    
    func akPlayback(_ media: AKPlayable, didChangeLoadedTimeRanges loadedTimeRanges: [NSValue]) {
        var availableDuration: Double {
            guard let timeRange = player.currentItem?.loadedTimeRanges.first?.timeRangeValue else {
                return 0.0
            }
            let startSeconds = timeRange.start.seconds
            let durationSeconds = timeRange.duration.seconds
            return startSeconds + durationSeconds
        }
        bufferProgressView.setProgress(Float(availableDuration)/Float(player.currentItem!.duration.seconds), animated: true)
    }
    
    func akPlayback(_ media: AKPlayable, didChangeTracks tracks: [AVPlayerItemTrack]) {
        print("Number of tracks got", tracks.count)
    }
}

// MARK: - AKPlayerPlugin

extension SimpleVideoViewController: AKPlayerPlugin {
    
    func playerPlugin(didInit player: AVPlayer) {
    }
    
    func playerPlugin(willStartLoading media: AKPlayable) {
    }
    
    func playerPlugin(didLoad media: AKPlayable, with duration: CMTime) {
        audioButton.isEnabled = true
        subtitleButton.isEnabled = true
    }
    
    func playerPlugin(didChanged media: AKPlayable) {
        audioButton.isEnabled = false
        subtitleButton.isEnabled = false
    }
    
    func playerPlugin(didFailed media: AKPlayable, with error: AKPlayerError) {
        audioButton.isEnabled = false
        subtitleButton.isEnabled = false
    }
}
