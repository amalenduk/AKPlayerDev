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

public protocol AKPlayerItemTimingInformationObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var durationPublisher: AnyPublisher<CMTime, Never> { get }
    var timebasePublisher: AnyPublisher<CMTimebase?, Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerItemTimingInformationObserver: AKPlayerItemTimingInformationObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public var durationPublisher: AnyPublisher<CMTime, Never> {
        return _durationPublisher.eraseToAnyPublisher()
    }
    
    public var timebasePublisher: AnyPublisher<CMTimebase?, Never> {
        return _timebasePublisher.eraseToAnyPublisher()
    }
    
    private var _durationPublisher = PassthroughSubject<CMTime, Never>()
    private var _timebasePublisher = PassthroughSubject<CMTimebase?, Never>()
    
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
        
        playerItem.publisher(for: \.duration,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] duration in
            _durationPublisher.send(duration)
        })
        .store(in: &cancellables)
        
        
        playerItem.publisher(for: \.timebase,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] timebase in
            _timebasePublisher.send(timebase)
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
