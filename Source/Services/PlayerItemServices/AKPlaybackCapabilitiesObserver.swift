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

public protocol AKPlaybackCapabilitiesObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var canPlayReversePublisher: AnyPublisher<Bool, Never> { get }
    var canPlayFastForwardPublisher: AnyPublisher<Bool, Never> { get }
    var canPlayFastReversePublisher: AnyPublisher<Bool, Never> { get }
    var canPlaySlowForwardPublisher: AnyPublisher<Bool, Never> { get }
    var canPlaySlowReversePublisher: AnyPublisher<Bool, Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKPlaybackCapabilitiesObserver: AKPlaybackCapabilitiesObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public var canPlayReversePublisher: AnyPublisher<Bool, Never> {
        return _canPlayReversePublisher.eraseToAnyPublisher()
    }
    
    public var canPlayFastForwardPublisher: AnyPublisher<Bool, Never> {
        return _canPlayFastForwardPublisher.eraseToAnyPublisher()
    }
    
    public var canPlayFastReversePublisher: AnyPublisher<Bool, Never> {
        return _canPlayFastReversePublisher.eraseToAnyPublisher()
    }
    
    public var canPlaySlowForwardPublisher: AnyPublisher<Bool, Never> {
        return _canPlaySlowForwardPublisher.eraseToAnyPublisher()
    }
    
    public var canPlaySlowReversePublisher: AnyPublisher<Bool, Never> {
        return _canPlaySlowReversePublisher.eraseToAnyPublisher()
    }
    
    private var _canPlayReversePublisher = PassthroughSubject<Bool, Never>()
    private var _canPlayFastForwardPublisher = PassthroughSubject<Bool, Never>()
    private var _canPlayFastReversePublisher = PassthroughSubject<Bool, Never>()
    private var _canPlaySlowForwardPublisher = PassthroughSubject<Bool, Never>()
    private var _canPlaySlowReversePublisher = PassthroughSubject<Bool, Never>()
    
    private var isObserving = false
    
    private var cancellables = Set<AnyCancellable>()
    
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
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] canPlayReverse in
            _canPlayReversePublisher.send(canPlayReverse)
        })
        .store(in: &cancellables)
        
        playerItem.publisher(for: \.canPlayFastForward,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] canPlayFastForward in
            _canPlayFastForwardPublisher.send(canPlayFastForward)
        })
        .store(in: &cancellables)
        
        playerItem.publisher(for: \.canPlayFastReverse,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] canPlayFastReverse in
            _canPlayFastReversePublisher.send(canPlayFastReverse)
        })
        .store(in: &cancellables)
        
        playerItem.publisher(for: \.canPlaySlowForward,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] canPlaySlowForward in
            _canPlaySlowForwardPublisher.send(canPlaySlowForward)
        })
        .store(in: &cancellables)
        
        playerItem.publisher(for: \.canPlaySlowReverse,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] canPlaySlowReverse in
            _canPlaySlowReversePublisher.send(canPlaySlowReverse)
        })
        .store(in: &cancellables)
        
        isObserving = true
    }
    
    open func stopObserving() {
        guard isObserving else { return }
        cancellables.removeAll()
        isObserving = false
    }
}
