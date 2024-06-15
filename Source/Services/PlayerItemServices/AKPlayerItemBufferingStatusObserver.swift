//
//  AKPlayerItemBufferingStatusObserver.swift
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
 https://developer.apple.com/documentation/avfoundation/avplayeritem/1390348-isplaybacklikelytokeepup
 */

import AVFoundation
import Combine

public protocol AKPlayerItemBufferingStatusObserverProtocol {
    var playerItem: AVPlayerItem { get }
    
    var playbackLikelyToKeepUpPublisher: AnyPublisher<Bool, Never> { get }
    var playbackBufferFullPublisher: AnyPublisher<Bool, Never> { get }
    var playbackBufferEmptyPublisher: AnyPublisher<Bool, Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerItemBufferingStatusObserver: AKPlayerItemBufferingStatusObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public var playbackLikelyToKeepUpPublisher: AnyPublisher<Bool, Never> {
        playbackLikelyToKeepUpSubject.eraseToAnyPublisher()
    }
    
    public var playbackBufferFullPublisher: AnyPublisher<Bool, Never> {
        playbackBufferFullSubject.eraseToAnyPublisher()
    }
    
    public var playbackBufferEmptyPublisher: AnyPublisher<Bool, Never> {
        playbackBufferEmptySubject.eraseToAnyPublisher()
    }
    
    private var playbackLikelyToKeepUpSubject: PassthroughSubject<Bool, Never> = PassthroughSubject<Bool, Never>()
    
    private var playbackBufferFullSubject: PassthroughSubject<Bool, Never> = PassthroughSubject<Bool, Never>()
    
    private var playbackBufferEmptySubject: PassthroughSubject<Bool, Never> = PassthroughSubject<Bool, Never>()
    
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
        
        playerItem.publisher(for: \.isPlaybackLikelyToKeepUp,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] isPlaybackLikelyToKeepUp in
            playbackLikelyToKeepUpSubject.send(isPlaybackLikelyToKeepUp)
        })
        .store(in: &cancellables)
        
        playerItem.publisher(for: \.isPlaybackBufferFull,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] isPlaybackBufferFull in
            playbackBufferFullSubject.send(isPlaybackBufferFull)
        })
        .store(in: &cancellables)
        
        playerItem.publisher(for: \.isPlaybackBufferEmpty,
                             options: [.initial, .new])
        .receive(on: DispatchQueue.global(qos: .background))
        .sink(receiveValue: { [unowned self] isPlaybackBufferEmpty in
            playbackBufferEmptySubject.send(isPlaybackBufferEmpty)
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
