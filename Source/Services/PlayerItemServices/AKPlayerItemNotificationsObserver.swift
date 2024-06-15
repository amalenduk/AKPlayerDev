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
    
    var didPlayToEndTimePublisher: AnyPublisher<CMTime, Never> { get }
    var failedToPlayToEndTimePublisher: AnyPublisher<AKPlayerError, Never> { get }
    var playbackStalledPublisher: AnyPublisher<Void, Never> { get }
    var timeJumpedPublisher: AnyPublisher<Void, Never> { get }
    var mediaSelectionDidChangePublisher: AnyPublisher<Void, Never> { get }
    var recommendedTimeOffsetFromLiveDidChangePublisher: AnyPublisher<CMTime, Never> { get }
    
    func startObserving()
    func stopObserving()
}

open class AKPlayerItemNotificationsObserver: AKPlayerItemNotificationsObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    private var isObserving = false
    
    private var cancellables = Set<AnyCancellable>()
    
    public var didPlayToEndTimePublisher: AnyPublisher<CMTime, Never> {
        didPlayToEndTimeSubject.eraseToAnyPublisher()
    }
    
    public var failedToPlayToEndTimePublisher: AnyPublisher<AKPlayerError, Never> {
        failedToPlayToEndTimeSubject.eraseToAnyPublisher()
    }
    
    public var playbackStalledPublisher: AnyPublisher<Void, Never> {
        playbackStalledSubject.eraseToAnyPublisher()
    }
    
    public var timeJumpedPublisher: AnyPublisher<Void, Never> {
        timeJumpedSubject.eraseToAnyPublisher()
    }
    
    public var mediaSelectionDidChangePublisher: AnyPublisher<Void, Never> {
        mediaSelectionDidChangeSubject.eraseToAnyPublisher()
    }
    
    public var recommendedTimeOffsetFromLiveDidChangePublisher: AnyPublisher<CMTime, Never> {
        recommendedTimeOffsetFromLiveDidChangeSubject.eraseToAnyPublisher()
    }
    
    private let didPlayToEndTimeSubject = PassthroughSubject<CMTime, Never>()
    private let failedToPlayToEndTimeSubject = PassthroughSubject<AKPlayerError, Never>()
    private let playbackStalledSubject = PassthroughSubject<Void, Never>()
    private let timeJumpedSubject = PassthroughSubject<Void, Never>()
    private let mediaSelectionDidChangeSubject = PassthroughSubject<Void, Never>()
    private let recommendedTimeOffsetFromLiveDidChangeSubject = PassthroughSubject<CMTime, Never>()
    
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
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] _ in
                guard let self else { return }
                didPlayToEndTimeSubject.send(playerItem.currentTime())
            }
            .store(in: &cancellables)
        
        /* When the player item has failed to play to its end time */
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] notification in
                guard let self,
                      let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError else { return }
                failedToPlayToEndTimeSubject.send(AKPlayerError.playerItemFailedToPlay(reason: .failedToPlayToEndTime(error: error)))
            }
            .store(in: &cancellables)
        
        /* A notification that’s posted when some media doesn’t arrive in time to continue playback.
         
         The notification’s object is the player item whose playback is unable to continue due to network delays. Streaming-media playback continues once the player receives a sufficient amount of data. File-based playback doesn’t continue.
         */
        NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled, object: playerItem)
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] _ in
                guard let self else { return }
                playbackStalledSubject.send()
            }
            .store(in: &cancellables)
        
        /* A notification the system posts when a player item’s time changes discontinuously. */
        NotificationCenter.default.publisher(for: AVPlayerItem.timeJumpedNotification, object: playerItem)
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] _ in
                guard let self else { return }
                timeJumpedSubject.send()
            }
            .store(in: &cancellables)
        
        /* A notification the player item posts when its media selection changes. */
        NotificationCenter.default.publisher(for: AVPlayerItem.mediaSelectionDidChangeNotification, object: playerItem)
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] _ in
                guard let self else { return }
                mediaSelectionDidChangeSubject.send()
            }
            .store(in: &cancellables)
        
        /* A notification the player item posts when its offset from the live time changes. */
        NotificationCenter.default.publisher(for: AVPlayerItem.recommendedTimeOffsetFromLiveDidChangeNotification, object: playerItem)
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] _ in
                guard let self else { return }
                recommendedTimeOffsetFromLiveDidChangeSubject.send(playerItem.recommendedTimeOffsetFromLive)
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
