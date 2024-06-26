//
//  AKPlayerItemBufferingStatusObserver.swift
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
 https://developer.apple.com/documentation/avfoundation/avplayeritem/1390348-isplaybacklikelytokeepup
 */

import AVFoundation
import Combine

public protocol AKPlayerItemBufferingStatusObserverDelegate: AnyObject {
    func playerItemBufferingStatusObserver(_ observer: AKPlayerItemBufferingStatusObserverProtocol,
                                           didChangePlaybackLikelyToKeepUpStatusTo isPlaybackLikelyToKeepUp: Bool,
                                           for playerItem: AVPlayerItem)
    func playerItemBufferingStatusObserver(_ observer: AKPlayerItemBufferingStatusObserverProtocol,
                                           didChangePlaybackBufferFullStatusTo isPlaybackBufferFull: Bool,
                                           for playerItem: AVPlayerItem)
    func playerItemBufferingStatusObserver(_ observer: AKPlayerItemBufferingStatusObserverProtocol,
                                           didChangePlaybackBufferEmptyStatusTo isPlaybackBufferEmpty: Bool,
                                           for playerItem: AVPlayerItem)
}

public extension AKPlayerItemBufferingStatusObserverDelegate {
    func playerItemBufferingStatusObserver(_ observer: AKPlayerItemBufferingStatusObserverProtocol,
                                           didChangePlaybackBufferEmptyStatusTo isPlaybackBufferEmpty: Bool,
                                           for playerItem: AVPlayerItem) { }
}

public protocol AKPlayerItemBufferingStatusObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var delegate: AKPlayerItemBufferingStatusObserverDelegate? { get set }
    
    func startObserving(with bufferObservingTimeout: TimeInterval,
                        bufferObservingTimeInterval: TimeInterval)
    func stopObserving()
}

open class AKPlayerItemBufferingStatusObserver: AKPlayerItemBufferingStatusObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public weak var delegate: AKPlayerItemBufferingStatusObserverDelegate?
    
    private var isObserving = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(with playerItem: AVPlayerItem) {
        self.playerItem = playerItem
    }
    
    deinit {
        stopObserving()
    }
    
    open func startObserving(with bufferObservingTimeout: TimeInterval,
                             bufferObservingTimeInterval: TimeInterval) {
        guard !isObserving else { return }
        
        
        playerItem.publisher(for: \.isPlaybackLikelyToKeepUp,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] isPlaybackLikelyToKeepUp in
            guard let delegate = delegate else { return }
            delegate.playerItemBufferingStatusObserver(self,
                                                       didChangePlaybackLikelyToKeepUpStatusTo: isPlaybackLikelyToKeepUp,
                                                       for: playerItem)
        })
        .store(in: &cancellables)
        
        playerItem.publisher(for: \.isPlaybackBufferFull,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] isPlaybackBufferFull in
            guard let delegate = delegate else { return }
            delegate.playerItemBufferingStatusObserver(self,
                                                       didChangePlaybackBufferFullStatusTo: isPlaybackBufferFull,
                                                       for: playerItem)
        })
        .store(in: &cancellables)
        
        playerItem.publisher(for: \.isPlaybackBufferEmpty,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] isPlaybackBufferEmpty in
            guard let delegate = delegate else { return }
            delegate.playerItemBufferingStatusObserver(self,
                                                       didChangePlaybackBufferEmptyStatusTo: isPlaybackBufferEmpty,
                                                       for: playerItem)
        })
        .store(in: &cancellables)
        
        isObserving = true
    }
    
    open func stopObserving() {
        guard isObserving else { return }
        
        cancellables.forEach({ $0.cancel() })
        
        isObserving = false
    }
}
