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

public protocol AKPlayerItemNotificationsObserverDelegate: AnyObject {
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didPlayToEndTimeAt time: CMTime,
                                         for playerItem: AVPlayerItem)
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didFailToPlayToEndTimeWith error: AKPlayerError,
                                         for playerItem: AVPlayerItem)
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didStallPlaybackFor playerItem: AVPlayerItem)
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didTimeJumpFor playerItem: AVPlayerItem)
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didChangeMediaSelectionFor playerItem: AVPlayerItem)
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didChangeRecommendedTimeOffsetFromLiveTo recommendedTimeOffsetFromLive: CMTime,
                                         for playerItem: AVPlayerItem)
}

extension AKPlayerItemNotificationsObserverDelegate {
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didTimeJumpFor playerItem: AVPlayerItem) { }
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didChangeMediaSelectionFor playerItem: AVPlayerItem) { }
    func playerItemNotificationsObserver(_ observer: AKPlayerItemNotificationsObserverProtocol,
                                         didChangeRecommendedTimeOffsetFromLiveTo recommendedTimeOffsetFromLive: CMTime,
                                         for playerItem: AVPlayerItem) { }
}

public protocol AKPlayerItemNotificationsObserverProtocol {
    var playerItem: AVPlayerItem { get }
    var delegate: AKPlayerItemNotificationsObserverDelegate? { get set }
    
    func startObserving()
    func stopObserving()
}

public final class AKPlayerItemNotificationsObserver: AKPlayerItemNotificationsObserverProtocol {
    
    // MARK: - Properties
    
    public let playerItem: AVPlayerItem
    
    public weak var delegate: AKPlayerItemNotificationsObserverDelegate?
    
    private var isObserving = false
    
    // MARK: - Init
    
    init(playerItem: AVPlayerItem) {
        self.playerItem = playerItem
    }
    
    deinit {
        stopObserving()
    }
    
    public func startObserving() {
        guard !isObserving else { return }
        
        /* When the player item has played to its end time */
        NotificationCenter.default.addObserver(self, selector:
                                                #selector(handlePlayerItemDidPlayToEndTimeNotification(_ :)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: playerItem)
        
        /* When the player item has failed to play to its end time */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePlayerItemFailedToPlayToEndTime(_ :)),
                                               name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
                                               object: playerItem)
        
        /* A notification that’s posted when some media doesn’t arrive in time to continue playback.
         
         The notification’s object is the player item whose playback is unable to continue due to network delays. Streaming-media playback continues once the player receives a sufficient amount of data. File-based playback doesn’t continue.
         */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePlayerItemPlaybackStalled(_ :)),
                                               name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                               object: playerItem)
        
        /* A notification the system posts when a player item’s time changes discontinuously. */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePlayerItemtTimeJumped(_ :)),
                                               name: AVPlayerItem.timeJumpedNotification,
                                               object: playerItem)
        
        /* A notification the player item posts when its media selection changes. */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMediaSelectionDidChange(_ :)),
                                               name: AVPlayerItem.mediaSelectionDidChangeNotification,
                                               object: playerItem)
        
        /* A notification the player item posts when its offset from the live time changes. */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRecommendedTimeOffsetFromLiveDidChange(_ :)),
                                               name: AVPlayerItem.recommendedTimeOffsetFromLiveDidChangeNotification,
                                               object: playerItem)
        
        isObserving = true
    }
    
    public func stopObserving() {
        guard isObserving else { return }
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: playerItem)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
                                                  object: playerItem)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                                  object: playerItem)
        NotificationCenter.default.removeObserver(self,
                                                  name: AVPlayerItem.timeJumpedNotification,
                                                  object: playerItem)
        NotificationCenter.default.removeObserver(self,
                                                  name: AVPlayerItem.mediaSelectionDidChangeNotification,
                                                  object: playerItem)
        NotificationCenter.default.removeObserver(self,
                                                  name: AVPlayerItem.recommendedTimeOffsetFromLiveDidChangeNotification,
                                                  object: playerItem)
        
        isObserving = false
    }
    
    /* Called when the player item has played to its end time. */
    @objc private func handlePlayerItemDidPlayToEndTimeNotification(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == playerItem,
              let delegate = delegate else { return }
        delegate.playerItemNotificationsObserver(self,
                                                 didPlayToEndTimeAt: item.currentTime(),
                                                 for: item)
    }
    
    /* When the player item has failed to play to its end time */
    @objc private func handlePlayerItemFailedToPlayToEndTime(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == playerItem,
              let delegate = delegate  else { return }
        
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError {
            delegate.playerItemNotificationsObserver(self,
                                                     didFailToPlayToEndTimeWith: AKPlayerError.playerItemFailedToPlay(reason: .failedToPlayToEndTime(error: error)),
                                                     for: item)
        } else {
            
            delegate.playerItemNotificationsObserver(self,
                                                     didFailToPlayToEndTimeWith: AKPlayerError.playerItemFailedToPlay(reason: .failedToPlayToEndTime(error: item.error!)),
                                                     for: item)
        }
    }
    
    /* A notification that’s posted when some media doesn’t arrive in time to continue playback. */
    @objc func handlePlayerItemPlaybackStalled(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == playerItem,
              let delegate = delegate  else { return }
        delegate.playerItemNotificationsObserver(self,
                                                 didStallPlaybackFor: item)
    }
    
    @objc func handlePlayerItemtTimeJumped(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == playerItem,
              let delegate = delegate  else { return }
        delegate.playerItemNotificationsObserver(self, didTimeJumpFor: item)
    }
    
    @objc func handleMediaSelectionDidChange(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == playerItem,
              let delegate = delegate  else { return }
        delegate.playerItemNotificationsObserver(self,
                                                 didChangeMediaSelectionFor: item)
    }
    
    @objc func handleRecommendedTimeOffsetFromLiveDidChange(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == playerItem,
              let delegate = delegate  else { return }
        delegate.playerItemNotificationsObserver(self,
                                                 didChangeRecommendedTimeOffsetFromLiveTo: item.recommendedTimeOffsetFromLive,
                                                 for: item)
    }
}
