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

public protocol AKPlayerItemReadinessObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var statusPublisher: AnyPublisher<(status: AVPlayerItem.Status, error: AKPlayerError?), Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerItemReadinessObserver: AKPlayerItemReadinessObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public var statusPublisher: AnyPublisher<(status: AVPlayerItem.Status, error: AKPlayerError?), Never> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    private var statusSubject = PassthroughSubject<(status: AVPlayerItem.Status, error: AKPlayerError?), Never>()
    
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
        
        playerItem.publisher(for: \.status,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] status in
            statusSubject.send((status, (status == .failed) ? .playerItemLoadingFailed(reason: .statusLoadingFailed(error: playerItem.error!)) : nil))
        })
        .store(in: &cancellables)
    }
    
    open func stopObserving() {
        guard isObserving else { return }
        cancellables.removeAll()
        isObserving = false
    }
}
