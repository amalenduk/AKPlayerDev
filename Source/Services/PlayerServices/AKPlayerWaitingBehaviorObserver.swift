//
//  AKPlayerWaitingBehaviorObserver.swift
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

public protocol AKPlayerWaitingBehaviorObserverDelegate: AnyObject {
    func playerWaitingBehaviorObserver(_ observer: AKPlayerWaitingBehaviorObserverProtocol,
                                       didChangeTimeControlStatusTo status: AVPlayer.TimeControlStatus,
                                       for player: AVPlayer)
}

public protocol AKPlayerWaitingBehaviorObserverProtocol {
    var player: AVPlayer { get }
    var delegate: AKPlayerWaitingBehaviorObserverDelegate? { get set }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerWaitingBehaviorObserver: AKPlayerWaitingBehaviorObserverProtocol {
    
    // MARK: - Properties
    
    public let player: AVPlayer
    
    public weak var delegate: AKPlayerWaitingBehaviorObserverDelegate?
    
    private var isObserving = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(with player: AVPlayer) {
        self.player = player
    }
    
    deinit {
        stopObserving()
    }
    
    public func startObserving() {
        guard !isObserving else { return }
        /*
         Create an observer to toggle the play/pause button control icon to
         reflect the playback state of the player's `timeControlStatus` property.
         */
        player.publisher(for: \.timeControlStatus,
                         options: [.initial, .new])
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] status in
            guard let delegate = delegate else { return }
            delegate.playerWaitingBehaviorObserver(self,
                                                   didChangeTimeControlStatusTo: player.timeControlStatus,
                                                   for: player)
        }
        .store(in: &cancellables)
        
        isObserving = true
    }
    
    public func stopObserving() {
        guard isObserving else { return }
        
        cancellables.forEach({ $0.cancel() })
        
        isObserving = false
    }
}
