//
//  AKPlayerAudioBehaviorObserver.swift
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

public protocol AKPlayerAudioBehaviorObserverDelegate: AnyObject {
    func audioBehaviorObserver(_ observer: AKPlayerAudioBehaviorObserverProtocol,
                               didChangeVolumeTo volume: Float,
                               for player: AVPlayer)
    func audioBehaviorObserver(_ observer: AKPlayerAudioBehaviorObserverProtocol,
                               didChangeMutedStatusTo isMuted: Bool,
                               for player: AVPlayer)
}

public protocol AKPlayerAudioBehaviorObserverProtocol {
    var player: AVPlayer { get }
    var delegate: AKPlayerAudioBehaviorObserverDelegate? { get set }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerAudioBehaviorObserver: AKPlayerAudioBehaviorObserverProtocol {
    
    // MARK: - Properties
    
    public let player: AVPlayer
    
    public weak var delegate: AKPlayerAudioBehaviorObserverDelegate?
    
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
        
        /*
         Register as an observer of the player's volume property
         */
        player.publisher(for: \.volume,
                         options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] volume in
            guard let delegate = delegate else { return }
            delegate.audioBehaviorObserver(self,
                                           didChangeVolumeTo: volume,
                                           for: player)
        }
        .store(in: &cancellables)
        
        /*
         Register as an observer of the player's isMuted property
         */
        player.publisher(for: \.isMuted,
                         options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] isMuted in
            guard let delegate = delegate else { return }
            delegate.audioBehaviorObserver(self,
                                           didChangeMutedStatusTo: isMuted,
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
