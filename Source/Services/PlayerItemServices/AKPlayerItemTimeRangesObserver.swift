//
//  AKPlayerItemTimeRangesObserver.swift
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

public protocol AKPlayerItemTimeRangesObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var loadedTimeRangesPublisher: AnyPublisher<[NSValue], Never> { get }
    var seekableTimeRangesPublisher: AnyPublisher<[NSValue], Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerItemTimeRangesObserver: AKPlayerItemTimeRangesObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public var loadedTimeRangesPublisher: AnyPublisher<[NSValue], Never> {
        return _loadedTimeRangesPublisher.eraseToAnyPublisher()
    }
    
    public var seekableTimeRangesPublisher: AnyPublisher<[NSValue], Never> {
        return _seekableTimeRangesPublisher.eraseToAnyPublisher()
    }
    
    private var _loadedTimeRangesPublisher = PassthroughSubject<[NSValue], Never>()
    private var _seekableTimeRangesPublisher = PassthroughSubject<[NSValue], Never>()
    
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
        
        playerItem.publisher(for: \.loadedTimeRanges,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] loadedTimeRanges in
            _loadedTimeRangesPublisher.send(loadedTimeRanges)
        })
        .store(in: &cancellables)
        
        playerItem.publisher(for: \.seekableTimeRanges,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] seekableTimeRanges in
            _seekableTimeRangesPublisher.send(seekableTimeRanges)
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
