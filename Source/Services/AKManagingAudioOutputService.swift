//
//  AKManagingAudioOutputEventProducer.swift
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

public protocol AKManagingAudioOutputEventProducible: AKEventProducer {
    var player: AVPlayer { get }
}

open class AKManagingAudioOutputEventProducer: AKManagingAudioOutputEventProducible {
    
    public enum ManagingAudioOutputEvent: AKEvent {
        case volumeChanged(_ volume: Float)
        case isMuted(_ isMuted: Bool)
    }
    
    // MARK: - Properties
    
    public let player: AVPlayer
    
    open weak var eventListener: AKEventListener?
    
    private var listening = false
    
    /**
     The `NSKeyValueObservation` for the KVO on `\AVPlayerItem.volume`.
     */
    private var playerVolumeObserver: NSKeyValueObservation!
    
    /**
     The `NSKeyValueObservation` for the KVO on `\AVPlayerItem.volume`.
     */
    private var playerIsMutedObserver: NSKeyValueObservation!
    
    // MARK: - Init
    
    public init(with player: AVPlayer) {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        self.player = player
    }
    
    deinit {
        stopProducingEvents()
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
    }
    
    open func startProducingEvents() {
        guard !listening else { return }
        
        /*
         Register as an observer of the player's volume property
         */
        playerVolumeObserver = player.observe(\.volume, options: [.initial, .new], changeHandler: { [unowned self] (_, change) in
            eventListener?.onEvent(ManagingAudioOutputEvent.volumeChanged(change.newValue!), generetedBy: self)
        })
        
        /*
         Register as an observer of the player's isMuted property
         */
        playerIsMutedObserver = player.observe(\.isMuted, options: [.initial, .new], changeHandler: { [unowned self] (_, change) in
            eventListener?.onEvent(ManagingAudioOutputEvent.isMuted(change.newValue!), generetedBy: self)
        })
        
        listening = true
    }
    
    open func stopProducingEvents() {
        guard listening else { return }
        
        playerVolumeObserver.invalidate()
        playerIsMutedObserver.invalidate()
        
        listening = false
    }
}
