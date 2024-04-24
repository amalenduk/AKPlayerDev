//
//  AKSteppingThroughMediaObserver.swift
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

public protocol AKSteppingThroughMediaObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var canStepForwardPublisher: AnyPublisher<Bool, Never> { get }
    var canStepBackwardPublisher: AnyPublisher<Bool, Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKSteppingThroughMediaObserver: AKSteppingThroughMediaObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public var canStepForwardPublisher: AnyPublisher<Bool, Never> {
        return _canStepForwardPublisher.eraseToAnyPublisher()
    }
    
    public var canStepBackwardPublisher: AnyPublisher<Bool, Never> {
        return _canStepBackwardPublisher.eraseToAnyPublisher()
    }
    
    private var _canStepForwardPublisher = PassthroughSubject<Bool, Never>()
    private var _canStepBackwardPublisher = PassthroughSubject<Bool, Never>()
    
    private var isObserving = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(with playerItem: AVPlayerItem) {
        self.playerItem = playerItem
    }
    
    deinit {
        stopObserving()
    }
    
    // MARK: - Additional Helper Functions
    
    open func canStep(byCount count: Int) -> (canStep: Bool,
                                              reason: AKPlayerUnavailableCommandReason?) {
        var isForward: Bool {
            return count.signum() == 1
        }
        if isForward {
            if playerItem.canStepForward {
                return (true, nil)
            }else {
                return (false, .canNotStepForward)
            }
        } else {
            if playerItem.canStepForward {
                return (true, nil)
            } else {
                return (false, .canNotStepBackward)
            }
        }
    }
    
    open func startObserving() {
        guard !isObserving else { return }
        
        playerItem.publisher(for: \.canStepForward,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink { [unowned self] canStepForward in
            _canStepForwardPublisher.send(canStepForward)
        }
        .store(in: &cancellables)
        
        playerItem.publisher(for: \.canStepBackward,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink { [unowned self] canStepBackward in
            _canStepBackwardPublisher.send(canStepBackward)
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
