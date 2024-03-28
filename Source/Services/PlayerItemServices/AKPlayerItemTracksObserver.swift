//
//  AKPlayerItemTracksObserver.swift
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

public protocol AKPlayerItemTracksObserverDelegate: AnyObject {
    func playerItemTracksObserver(_ observer: AKPlayerItemTracksObserverProtocol,
                                  didLoad tracks: [AVPlayerItemTrack],
                                  for playerItem: AVPlayerItem)
}

public protocol AKPlayerItemTracksObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var delegate: AKPlayerItemTracksObserverDelegate? { get set }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerItemTracksObserver: AKPlayerItemTracksObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public weak var delegate: AKPlayerItemTracksObserverDelegate?
    
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
        
        playerItem.publisher(for: \.tracks,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] tracks in
            guard let delegate = delegate else { return }
            delegate.playerItemTracksObserver(self,
                                              didLoad: tracks,
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
