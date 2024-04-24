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
import Combine

// https://developer.apple.com/documentation/avfoundation/media_playback/controlling_the_transport_behavior_of_a_player

public struct AKPlaybackRateChange {
    let oldRate: AKPlaybackRate
    let newRate: AKPlaybackRate
    let reason: AVPlayer.RateDidChangeReason
}

public protocol AKPlayerRateObserverProtocol {
    var player: AVPlayer { get }
    var playbackRatePublisher: AnyPublisher<AKPlaybackRateChange, Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerRateObserver: AKPlayerRateObserverProtocol {
    
    // MARK: - Properties
    
    public let player: AVPlayer
    
    public var playbackRatePublisher: AnyPublisher<AKPlaybackRateChange, Never> {
        return _playbackRatePublisher.eraseToAnyPublisher()
    }
    
    private var _playbackRatePublisher = PassthroughSubject<AKPlaybackRateChange, Never>()
    
    private var isObserving = false
    
    private var playbackRateObserver: NSKeyValueObservation?
    
    private var cancellables = Set<AnyCancellable>()
    
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
        
        NotificationCenter.default.publisher(for: AVPlayer.rateDidChangeNotification, object: player)
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [unowned self] notification in
                guard let userInfo = notification.userInfo,
                      let key = userInfo[AVPlayer.rateDidChangeReasonKey] as? String else {
                    return
                }
                
                let reason = AVPlayer.RateDidChangeReason(rawValue: key)
                let change = AKPlaybackRateChange(oldRate: oldRate,
                                                  newRate: newRate,
                                                  reason: reason)
                _playbackRatePublisher.send(change)
            }
            .store(in: &cancellables)
        
        isObserving = true
    }
    
    open func stopObserving() {
        guard isObserving else { return }
        playbackRateObserver?.invalidate()
        cancellables.removeAll()
        isObserving = false
    }
}
