//
//  AKPlayerReadinessObserver.swift
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

// https://developer.apple.com/documentation/avfoundation/avplayer/1388096-status

import AVFoundation
import Combine

public protocol AKPlayerReadinessObserverDelegate: AnyObject {
    func playerReadinessObserver(_ observer: AKPlayerReadinessObserverProtocol,
                                 didChangeStatusTo status: AVPlayer.Status,
                                 for player: AVPlayer)
}

public protocol AKPlayerReadinessObserverProtocol {
    var player: AVPlayer { get }
    var delegate: AKPlayerReadinessObserverDelegate? { get set }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerReadinessObserver: AKPlayerReadinessObserverProtocol {
    
    // MARK: - Properties
    
    public let player: AVPlayer
    
    public weak var delegate: AKPlayerReadinessObserverDelegate?
    
    private var isObserving = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(with player: AVPlayer) {
        self.player = player
    }
    
    deinit {
        stopObserving()
    }
    
    open func startObserving() {
        guard !isObserving else { return }
        
        /* If a player reaches a failed state, you can’t use it for playback, and instead need to create a new instance. */
        
        /* The player’s status doesn’t indicate its readiness to play a specific player item. You should instead use the status property of AVPlayerItem to make that determination. */
        player.publisher(for: \.status,
                         options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] status in
            guard let delegate = delegate else { return }
            delegate.playerReadinessObserver(self,
                                             didChangeStatusTo: status,
                                             for: player)
        }
        .store(in: &cancellables)
        
        isObserving = true
    }
    
    open func stopObserving() {
        guard isObserving else { return }
        
        cancellables.forEach({ $0.cancel() })
        
        isObserving = false
    }
}

