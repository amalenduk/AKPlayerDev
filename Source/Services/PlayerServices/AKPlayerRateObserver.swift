//
//  AKPlayerRateObserver.swift
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

public protocol AKPlayerRateObserverDelegate: AnyObject {
    func playerRateObserver(_ observer: AKPlayerRateObserverProtocol,
                            didChangePlaybackRateTo newRate: AKPlaybackRate,
                            from oldRate: AKPlaybackRate,
                            for player: AVPlayer,
                            with reason: AVPlayer.RateDidChangeReason)
}

public protocol AKPlayerRateObserverProtocol {
    var player: AVPlayer { get }
    var delegate: AKPlayerRateObserverDelegate? { get set }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerRateObserver: AKPlayerRateObserverProtocol {
    
    // MARK: - Properties
    
    public let player: AVPlayer
    
    public weak var delegate: AKPlayerRateObserverDelegate?
    
    private var isObserving = false
    
    private var playbackRateObserver: NSKeyValueObservation?
    
    private var oldRate: AKPlaybackRate!
    
    private var newRate: AKPlaybackRate!
    
    // MARK: - Init
    
    public init(with player: AVPlayer) {
        self.player = player
    }
    
    deinit {
        stopObserving()
    }
    
    open func startObserving() {
        guard !isObserving else { return }
        
        playbackRateObserver = player.observe(\AVPlayer.rate,
                                               options: [.old, .new, .initial],
                                               changeHandler: { [unowned self] player, change in
            guard let newValue = change.newValue,
                  let oldValue = change.oldValue else { return }
            
            newRate = AKPlaybackRate(rate: newValue)
            oldRate = AKPlaybackRate(rate: oldValue)
        })
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRateDidChangeNotification(_ :)),
                                               name: AVPlayer.rateDidChangeNotification,
                                               object: player)
        
        isObserving = true
    }
    
    open func stopObserving() {
        guard isObserving else { return }
        
        NotificationCenter.default.removeObserver(self,
                                                  name: AVPlayer.rateDidChangeNotification,
                                                  object: player)
        
        playbackRateObserver?.invalidate()
        
        isObserving = false
    }
    
    @objc private func handleRateDidChangeNotification(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let key = userInfo[AVPlayer.rateDidChangeReasonKey] as? String else {
            return
        }
        
        let reason = AVPlayer.RateDidChangeReason(rawValue: key)
        print("reason : ", reason, "Old: ", oldRate.rate, "New Rate: ", newRate.rate)
        delegate?.playerRateObserver(self,
                                     didChangePlaybackRateTo: newRate,
                                     from: oldRate,
                                     for: player,
                                     with: reason)
    }
}
