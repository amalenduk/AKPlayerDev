//
//  AKPlayerItemTimingInformationObserver.swift
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

public protocol AKPlayerItemTimingInformationObserverDelegate: AnyObject {
    func playerItemTimingInformationObserver(_ observer: AKPlayerItemTimingInformationObserverProtocol,
                                             didChangeDurationTo duration: CMTime,
                                             for playerItem: AVPlayerItem)
    func accessingTimingInformationObserver(_ observer: AKPlayerItemTimingInformationObserverProtocol,
                                            didChangeTimebaseTo timebase: CMTimebase?,
                                            for playerItem: AVPlayerItem)
}

public protocol AKPlayerItemTimingInformationObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var delegate: AKPlayerItemTimingInformationObserverDelegate? { get set }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerItemTimingInformationObserver: AKPlayerItemTimingInformationObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public weak var delegate: AKPlayerItemTimingInformationObserverDelegate?
    
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
        
        playerItem.publisher(for: \.duration,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] duration in
            guard let delegate = delegate else { return }
            delegate.playerItemTimingInformationObserver(self,
                                                         didChangeDurationTo: duration,
                                                         for: playerItem)
        })
        .store(in: &subscriptions)
        
        
        playerItem.publisher(for: \.timebase,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] timebase in
            guard let delegate = delegate else { return }
            delegate.accessingTimingInformationObserver(self,
                                                        didChangeTimebaseTo: timebase,
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
