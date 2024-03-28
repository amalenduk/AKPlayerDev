//
//  AKPlaybackCapabilitiesObserver.swift
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

/*
 Ref:
 https://developer.apple.com/documentation/avfoundation/avplayeritem/1385591-canplayreverse
 */

import AVFoundation
import Combine

public protocol AKPlaybackCapabilitiesObserverDelegate: AnyObject {
    func playbackCapabilitiesObserver(_ observer: AKPlaybackCapabilitiesObserverProtocol,
                                      didChangeCanPlayReverseStatusTo canPlayReverse: Bool,
                                      for playerItem: AVPlayerItem)
    func playbackCapabilitiesObserver(_ observer: AKPlaybackCapabilitiesObserverProtocol,
                                      didChangeCanPlayFastForwardStatusTo canPlayFastForward: Bool,
                                      for playerItem: AVPlayerItem)
    func playbackCapabilitiesObserver(_ observer: AKPlaybackCapabilitiesObserverProtocol,
                                      didChangeCanPlayFastReverseStatusTo canPlayFastReverse: Bool,
                                      for playerItem: AVPlayerItem)
    func playbackCapabilitiesObserver(_ observer: AKPlaybackCapabilitiesObserverProtocol,
                                      didChangeCanPlaySlowForwardStatusTo canPlaySlowForward: Bool,
                                      for playerItem: AVPlayerItem)
    func playbackCapabilitiesObserver(_ observer: AKPlaybackCapabilitiesObserverProtocol,
                                      didChangeCanPlaySlowReverseStatusTo canPlaySlowReverse: Bool,
                                      for playerItem: AVPlayerItem)
}

public protocol AKPlaybackCapabilitiesObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var delegate: AKPlaybackCapabilitiesObserverDelegate? { get set }
    
    func startObserving()
    func stopObserving()
}

open class AKPlaybackCapabilitiesObserver: AKPlaybackCapabilitiesObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public weak var delegate: AKPlaybackCapabilitiesObserverDelegate?
    
    private var isObserving = false
    
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(with playerItem: AVPlayerItem) {
        self.playerItem = playerItem
    }
    
    deinit {
        stopObserving()
    }
    
    open func startObserving() {
        guard !isObserving else { return }
        
        playerItem.publisher(for: \.canPlayReverse,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] canPlayReverse in
            guard let delegate = delegate else { return }
            delegate.playbackCapabilitiesObserver(self,
                                                  didChangeCanPlayReverseStatusTo: canPlayReverse,
                                                  for: playerItem)
        })
        .store(in: &subscriptions)
        
        playerItem.publisher(for: \.canPlayFastForward,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] canPlayFastForward in
            guard let delegate = delegate else { return }
            delegate.playbackCapabilitiesObserver(self,
                                                  didChangeCanPlayFastForwardStatusTo: canPlayFastForward,
                                                  for: playerItem)
        })
        .store(in: &subscriptions)
        
        playerItem.publisher(for: \.canPlayFastReverse,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] canPlayFastReverse in
            guard let delegate = delegate else { return }
            delegate.playbackCapabilitiesObserver(self,
                                                  didChangeCanPlayFastReverseStatusTo: canPlayFastReverse,
                                                  for: playerItem)
        })
        .store(in: &subscriptions)
        
        playerItem.publisher(for: \.canPlaySlowForward,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] canPlaySlowForward in
            guard let delegate = delegate else { return }
            delegate.playbackCapabilitiesObserver(self,
                                                  didChangeCanPlaySlowForwardStatusTo: canPlaySlowForward,
                                                  for: playerItem)
        })
        .store(in: &subscriptions)
        
        playerItem.publisher(for: \.canPlaySlowReverse,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] canPlaySlowReverse in
            guard let delegate = delegate else { return }
            delegate.playbackCapabilitiesObserver(self,
                                                  didChangeCanPlaySlowReverseStatusTo: canPlaySlowReverse,
                                                  for: playerItem)
        })
        .store(in: &subscriptions)
        
        isObserving = true
    }
    
    open func stopObserving() {
        guard isObserving else { return }
        subscriptions.forEach({ $0.cancel() })
        isObserving = false
    }
}
