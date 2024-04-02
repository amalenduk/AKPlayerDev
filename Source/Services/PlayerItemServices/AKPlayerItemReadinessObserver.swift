//
//  AKPlayerItemReadinessObserver.swift
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

public protocol AKPlayerItemReadinessObserverDelegate: AnyObject {
    func playerItemReadinessObserver(_ observer: AKPlayerItemReadinessObserverProtocol,
                                     didChangeStatusTo status: AVPlayerItem.Status,
                                     for playerItem: AVPlayerItem,
                                     with error: AKPlayerError?)
}

public protocol AKPlayerItemReadinessObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var delegate: AKPlayerItemReadinessObserverDelegate? { get set }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerItemReadinessObserver: AKPlayerItemReadinessObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public weak var delegate: AKPlayerItemReadinessObserverDelegate?
    
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
        
        playerItem.publisher(for: \.status,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [unowned self] status in
            guard let delegate = delegate else { return }
            delegate.playerItemReadinessObserver(self,
                                                 didChangeStatusTo: status,
                                                 for: playerItem, 
                                                 with: status == .failed ? AKPlayerError.playerItemLoadingFailed(reason: .statusLoadingFailed(error: playerItem.error!)) : nil)
        })
        .store(in: &subscriptions)
    }
    
    open func stopObserving() {
        guard isObserving else { return }
        subscriptions.forEach({ $0.cancel() })
        isObserving = false
    }
}
