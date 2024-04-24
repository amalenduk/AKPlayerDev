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

public protocol AKPlayerAudioBehaviorObserverProtocol {
    var player: AVPlayer { get }
    var volumePublisher: AnyPublisher<Float, Never> { get }
    var muteStatusPublisher: AnyPublisher<Bool, Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerAudioBehaviorObserver: AKPlayerAudioBehaviorObserverProtocol {
    
    // MARK: - Properties
    
    public let player: AVPlayer
    
    public var volumePublisher: AnyPublisher<Float, Never> {
        return _volumePublisher.eraseToAnyPublisher()
    }
    
    public var muteStatusPublisher: AnyPublisher<Bool, Never> {
        return _muteStatusPublisher.eraseToAnyPublisher()
    }
    
    private var _volumePublisher = PassthroughSubject<Float, Never>()
    private var _muteStatusPublisher = PassthroughSubject<Bool, Never>()
    
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
        .receive(on: DispatchQueue.global(qos: .background))
        .sink { [unowned self] volume in
            _volumePublisher.send(volume)
        }
        .store(in: &cancellables)
        
        /*
         Register as an observer of the player's isMuted property
         */
        player.publisher(for: \.isMuted,
                         options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink { [unowned self] isMuted in
            _muteStatusPublisher.send(isMuted)
        }
        .store(in: &cancellables)
        
        isObserving = true
    }
    
    open func stopObserving() {
        guard isObserving else { return }
        cancellables.removeAll()
        isObserving = false
    }
}
