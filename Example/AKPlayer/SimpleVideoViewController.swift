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
        AKPlayerLogger.setup.domains = [.lifecycleService]
        let configuration = AKPlayerDefaultConfiguration()
        let player = AKPlayer(plugins: [self], configuration: configuration)
        player.player.appliesMediaSelectionCriteriaAutomatically = true
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
        brightnessSlider.value = Float(player.brightness)
        
        muteButton.setTitle("Mute", for: .normal)
        muteButton.setTitle("Muted", for: .selected)
        
        muteButton.isSelected = player.isMuted
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        print("Deinit called")
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
            let action = UIAction(title: rate.rateTitle, identifier: UIAction.Identifier.init("\(rate.rate)"), state: rate == player.playbackRate ? .on : .off) { [unowned self] _ in
                player.playbackRate = rate
            }
            items.append(action)
        }
        
        for rate in AKPlaybackRate.allCases {
            let action = UIAction(title: ("-" + rate.rateTitle), identifier: UIAction.Identifier.init("\(-rate.rate)"), state: .off) { [unowned self] _ in
                player.playbackRate = .custom(-rate.rate)
            }
            reverseItems.append(action)
        }
        
        let menu = UIMenu(title: "Rate", options: .displayInline, children: [destruct, UIMenu(title: "Rate", options: .displayInline, children: items as! [UIAction]), UIMenu(title: "Reverse", options: .destructive, children: reverseItems as! [UIAction])])
        
        if #available(iOS 14.0, *) {
            rateButton.menu = menu
            rateButton.showsMenuAsPrimaryAction = true
        }
    }
    
    @available(iOS 13.0, *)
    func reloadAudioTracksMenu() {
        /*
         guard mediaSelectionService.availableOption(for: .audible).count > 0 else { setDebugMessage("No tracks found"); return }
         let destruct = UIAction(title: "Cancel", attributes: .destructive) { _ in }
         var items: [UIAction] = []
         
         for option in mediaSelectionService.availableOption(for: .audible) {
         let action = UIAction(title: option.displayName, identifier: UIAction.Identifier.init("\(option.locale?.currencyCode ?? option.displayName)"), state: .off) { [unowned self] _ in
         mediaSelectionService.select(mediaSelectionOption: option, for: .audible)
         }
         items.append(action)
         }
         
         items.append(UIAction(title: "Off", identifier: UIAction.Identifier.init("off"), state: .off) { [unowned self] _ in
         mediaSelectionService.select(mediaSelectionOption: nil, for: .audible)
         })
         
         let menu = UIMenu(title: "Tracks", options: .displayInline, children: [destruct] + items)
         
         if #available(iOS 14.0, *) {
         audioButton.menu = menu
         audioButton.showsMenuAsPrimaryAction = true
         }
         */
    }
    
    @available(iOS 13.0, *)
    func reloadSubtitleMenu() {
        /*
         let char: AVMediaCharacteristic = .legible
         let destruct = UIAction(title: "Cancel", attributes: .destructive) { _ in }
         var items: [UIAction] = []
         for option in mediaSelectionService.availableOption(for: char) {
         let action = UIAction(title: option.displayName, identifier: UIAction.Identifier.init("\(option.locale?.currencyCode ?? option.displayName)"), state: .off) { [unowned self] _ in
         mediaSelectionService.select(mediaSelectionOption: option, for: char)
         }
         items.append(action)
         }
         
         items.append(UIAction(title: "Off", identifier: UIAction.Identifier.init("off"), state: .off) { [unowned self] _ in
         mediaSelectionService.select(mediaSelectionOption: nil, for: char)
         
         })
         
         let menu = UIMenu(title: "Subtitles", options: .displayInline, children: [destruct] + items)
         
         if #available(iOS 14.0, *) {
         subtitleButton.menu = menu
         subtitleButton.showsMenuAsPrimaryAction = true
         }
         */
    }

    func convertTimedMetadataGroupsToChapters(groups: [AVTimedMetadataGroup]) -> [Chapter] {
        return groups.map { group in
            // Retrieve the title metadata items.
            let titleItems = AVMetadataItem.metadataItems(from: group.items,
                                                          filteredByIdentifier: .commonIdentifierTitle)

            // Retrieve the artwork metadata items.
            let artworkItems = AVMetadataItem.metadataItems(from: group.items,
                                                            filteredByIdentifier: .commonIdentifierArtwork)

            var title = "Default Title"
            var image = UIImage(named: "placeholder")!

            if let titleValue = titleItems.first?.stringValue {
                title = titleValue
            }

            if let imgData = artworkItems.first?.dataValue, let imageValue = UIImage(data: imgData) {
                image = imageValue
            }

            return Chapter(time: group.timeRange.start, title: title, image: image)
        }
    }
    
    // MARK: - User Interactions
    
    @IBAction func updateNowPlayingInfoButtonActon(_ sender: Any) {
        player.setNowPlayingMetadata()
        player.setNowPlayingPlaybackInfo()
    }
    
    @objc func rateChangeButtonAction(_ sender: UIButton) {
        player.playbackRate = player.playbackRate.next
    }
    
    @IBAction func infoButtonAction(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "AssetInfoViewController") as! AssetInfoViewController
        let navVc = UINavigationController(rootViewController: vc)
        vc.assetInfo = AKMediaMetadata(with: player.currentItem?.asset.commonMetadata ?? [])
        present(navVc, animated: true, completion: nil)
    }
    
    @objc func progressSliderDidStartTracking(_ slider: UISlider) {
        isTracking = true
    }
    
    @objc func progressSliderDidEndTracking(_ slider: UISlider) {
        player.seek(toPercentage: Double(slider.value)) { finished in
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
        let media = AKMedia(url: URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!, type: .clip)
        player.load(media: media, autoPlay: autoPlaySwitch.isOn)
    }
    
    @IBAction func changeAudioTrackButtonAction(_ sender: Any) {

    }
    
    @IBAction func brightnessSliderDidChageValue(_ sender: UISlider) {
        player.brightness = CGFloat(sender.value)
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
        convertTimedMetadataGroupsToChapters(groups: chapterMetadata).forEach { (chapter) in
            print(chapter.title, chapter.time, chapter.image)
        }
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

    func akPlayer(_ player: AKPlayer, didStateChange state: AKPlayer.State) {
        DispatchQueue.main.async {
            self.stateLabel.text = "State: " + state.description
            if state == .waitingForNetwork || state == .buffering || state == .loading {
                self.indicatorView.startAnimating()
            }else {
                self.indicatorView.stopAnimating()
            }
        }
    }
    
    func akPlayer(_ player: AKPlayer, didCurrentMediaChange media: AKPlayable) {
        
    }
    
    func akPlayer(_ player: AKPlayer, didCurrentTimeChange currentTime: CMTime) {
        DispatchQueue.main.async {
            self.currentTimeLabel.text = "Current Timing: " + String(format: "%.2f", currentTime.seconds)
            self.setSliderProgress(currentTime, itemDuration: player.itemDuration)
        }
    }
    
    func akPlayer(_ player: AKPlayer, didItemDurationChange itemDuration: CMTime) {
        DispatchQueue.main.async {
            self.durationLabel.text = "Duration: " + String(format: "%.2f", itemDuration.seconds)
        }

        print("itemDuration", itemDuration)
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
    
    func akPlayer(_ player: AKPlayer, didVolumeChange volume: Float, isMuted: Bool) {
        volumeSlider.value = volume
        muteButton.isSelected = isMuted
    }

    func akPlayer(_ player: AKPlayer, didBrightnessChange brightness: CGFloat) {
        print(brightness)
        brightnessSlider.value = Float(brightness)
    }
    
    func akPlayer(_ player: AKPlayer, didPlaybackRateChange playbackRate: AKPlaybackRate) {
        rateLabel.text = "Rate: \(playbackRate.rateTitle)"
        if #available(iOS 13.0, *) {
            reloadRateMenus()
        }
    }

    public func akPlayer(_ player: AKPlayer, didCanPlayReverseStatusChange canPlayReverse: Bool, for media: AKPlayable) {
        print("canPlayReverse", canPlayReverse)
    }

    public func akPlayer(_ player: AKPlayer, didCanPlayFastForwardStatusChange canPlayFastForward: Bool, for media: AKPlayable) {
        print("canPlayFastForward", canPlayFastForward)
    }

    public func akPlayer(_ player: AKPlayer, didCanPlayFastReverseStatusChange canPlayFastReverse: Bool, for media: AKPlayable) {
        print("canPlayFastReverse", canPlayFastReverse)
    }

    public func akPlayer(_ player: AKPlayer, didCanPlaySlowForwardStatusChange canPlaySlowForward: Bool, for media: AKPlayable) {
        print("canPlaySlowForward", canPlaySlowForward)
    }

    public func akPlayer(_ player: AKPlayer, didCanPlaySlowReverseStatusChange canPlaySlowReverse: Bool, for media: AKPlayable) {
        print("canPlaySlowReverse", canPlaySlowReverse)
    }

    func akPlayer(_ player: AKPlayer, didCanStepForwardStatusChange canStepForward: Bool, for media: AKPlayable) {
        stepForwardButton.isEnabled = canStepForward
    }

    func akPlayer(_ player: AKPlayer, didCanStepBackwardStatusChange canStepBackward: Bool, for media: AKPlayable) {
        stepBackwardButton.isEnabled = canStepBackward
    }

    func akPlayer(_ player: AKPlayer, didLoadedTimeRangesChange loadedTimeRanges: [NSValue], for media: AKPlayable) {
        print(loadedTimeRanges)
        var availableDuration: Double {
            guard let timeRange = player.currentItem?.loadedTimeRanges.first?.timeRangeValue else {
                return 0.0
            }
            let startSeconds = timeRange.start.seconds
            let durationSeconds = timeRange.duration.seconds
            return startSeconds + durationSeconds
        }
        print(availableDuration)
        if let seconds = loadedTimeRanges.first?.timeValue.seconds {
            bufferProgressView.setProgress(Float(availableDuration)/Float(player.currentItem!.duration.seconds), animated: true)
        }
    }
}

// MARK: - AKPlayerPlugin

extension SimpleVideoViewController: AKPlayerPlugin {
    
    func playerPlugin(didLoad media: AKPlayable, with duration: CMTime) {
        if #available(iOS 13.0, *) {
            reloadAudioTracksMenu()
            reloadSubtitleMenu()
        }
        print("  -------------duration", duration)
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

struct Chapter {
    var time: CMTime
    var title: String
    var image: UIImage

    init(time: CMTime, title: String, image: UIImage) {
        self.time = time
        self.title = title
        self.image = image
    }
}
