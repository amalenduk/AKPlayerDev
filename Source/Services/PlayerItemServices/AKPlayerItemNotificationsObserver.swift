//
//  AKPlayerItemNotificationsObserver.swift
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

public protocol AKPlayerItemNotificationsObserverProtocol {
    var playerItem: AVPlayerItem { get }

    var playerItemDidPlayToEndTimePublisher: AnyPublisher<CMTime, Never> { get }
    var playerItemFailedToPlayToEndTimePublisher: AnyPublisher<AKPlayerError, Never> { get }
    var playerItemPlaybackStalledPublisher: AnyPublisher<Void, Never> { get }
    var playerItemTimeJumpedPublisher: AnyPublisher<Void, Never> { get }
    var playerItemMediaSelectionDidChangePublisher: AnyPublisher<Void, Never> { get }
    var playerItemRecommendedTimeOffsetFromLiveDidChangePublisher: AnyPublisher<CMTime, Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerItemNotificationsObserver: AKPlayerItemNotificationsObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    private var isObserving = false
    
    private var cancellables = Set<AnyCancellable>()
    
    public var playerItemDidPlayToEndTimePublisher: AnyPublisher<CMTime, Never> {
        _playerItemDidPlayToEndTimePublisher.eraseToAnyPublisher()
    }
    private let _playerItemDidPlayToEndTimePublisher = PassthroughSubject<CMTime, Never>()
    
    public var playerItemFailedToPlayToEndTimePublisher: AnyPublisher<AKPlayerError, Never> {
        _playerItemFailedToPlayToEndTimePublisher.eraseToAnyPublisher()
    }
    private let _playerItemFailedToPlayToEndTimePublisher = PassthroughSubject<AKPlayerError, Never>()
    
    public var playerItemPlaybackStalledPublisher: AnyPublisher<Void, Never> {
        _playerItemPlaybackStalledPublisher.eraseToAnyPublisher()
    }
    private let _playerItemPlaybackStalledPublisher = PassthroughSubject<Void, Never>()
    
    public var playerItemTimeJumpedPublisher: AnyPublisher<Void, Never> {
        _playerItemTimeJumpedPublisher.eraseToAnyPublisher()
    }
    private let _playerItemTimeJumpedPublisher = PassthroughSubject<Void, Never>()
    
    public var playerItemMediaSelectionDidChangePublisher: AnyPublisher<Void, Never> {
        _playerItemMediaSelectionDidChangePublisher.eraseToAnyPublisher()
    }
    private let _playerItemMediaSelectionDidChangePublisher = PassthroughSubject<Void, Never>()
    
    public var playerItemRecommendedTimeOffsetFromLiveDidChangePublisher: AnyPublisher<CMTime, Never> {
        _playerItemRecommendedTimeOffsetFromLiveDidChangePublisher.eraseToAnyPublisher()
    }
    private let _playerItemRecommendedTimeOffsetFromLiveDidChangePublisher = PassthroughSubject<CMTime, Never>()
    
    // MARK: - Init
    
    public init(playerItem: AVPlayerItem) {
        self.playerItem = playerItem
    }
    
    deinit {
        stopObserving()
    }
    
    open func startObserving() {
        guard !isObserving else { return }
        
        /* When the player item has played to its end time */
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { [weak self] _ in
                guard let self else { return }
                _playerItemDidPlayToEndTimePublisher.send(playerItem.currentTime())
            }
            .store(in: &cancellables)
        
        /* When the player item has failed to play to its end time */
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
            .sink { [weak self] notification in
                guard let self,
                      let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError else { return }
                _playerItemFailedToPlayToEndTimePublisher.send(AKPlayerError.playerItemFailedToPlay(reason: .failedToPlayToEndTime(error: error)))
            }
            .store(in: &cancellables)
        
        /* A notification that’s posted when some media doesn’t arrive in time to continue playback.
         
         The notification’s object is the player item whose playback is unable to continue due to network delays. Streaming-media playback continues once the player receives a sufficient amount of data. File-based playback doesn’t continue.
         */
        NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled, object: playerItem)
            .sink { [weak self] _ in
                guard let self else { return }
                _playerItemPlaybackStalledPublisher.send()
            }
            .store(in: &cancellables)
        
        /* A notification the system posts when a player item’s time changes discontinuously. */
        NotificationCenter.default.publisher(for: AVPlayerItem.timeJumpedNotification, object: playerItem)
            .sink { [weak self] _ in
                guard let self else { return }
                _playerItemTimeJumpedPublisher.send()
            }
            .store(in: &cancellables)
        
        /* A notification the player item posts when its media selection changes. */
        NotificationCenter.default.publisher(for: AVPlayerItem.mediaSelectionDidChangeNotification, object: playerItem)
            .sink { [weak self] _ in
                guard let self else { return }
                _playerItemMediaSelectionDidChangePublisher.send()
            }
            .store(in: &cancellables)
        
        /* A notification the player item posts when its offset from the live time changes. */
        NotificationCenter.default.publisher(for: AVPlayerItem.recommendedTimeOffsetFromLiveDidChangeNotification, object: playerItem)
            .sink { [weak self] _ in
                guard let self else { return }
                _playerItemRecommendedTimeOffsetFromLiveDidChangePublisher.send(playerItem.recommendedTimeOffsetFromLive)
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
