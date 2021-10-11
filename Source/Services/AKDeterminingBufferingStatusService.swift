//
//  AKDeterminingBufferingStatusService.swift
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

final class AKDeterminingBufferingStatusService {
    
    // MARK: - Properties
    
    private let playerItem: AVPlayerItem
    private let configuration: AKPlayerConfiguration
    
    var onChangePlaybackLikelyToKeepUpStatus: ((_ flag: Bool) -> Void)?
    var onChangePlaybackBufferFullStatus: ((_ flag: Bool) -> Void)?
    var onChangePlaybackBufferEmptyStatus: ((_ flag: Bool) -> Void)?
    var onChangePlaybackBufferStatus: ((_ flag: Bool) -> Void)?
    
    private var timer: Timer?
    /**
     The `NSKeyValueObservation` for the KVO on
     `\AVPlayerItem.isPlaybackLikelyToKeepUp`.
     */
    private var playerItemIsPlaybackLikelyToKeepUpObserver: NSKeyValueObservation?
    
    /**
     The `NSKeyValueObservation` for the KVO on
     `\AVPlayerItem.isPlaybackBufferFull`.
     */
    private var playerItemIsPlaybackBufferFullObserver: NSKeyValueObservation?
    
    /**
     The `NSKeyValueObservation` for the KVO on
     `\AVPlayerItem.isPlaybackBufferEmpty`.
     */
    private var playerItemIsPlaybackBufferEmptyObserver: NSKeyValueObservation?
    
    // MARK: - Init
    
    init(with playerItem: AVPlayerItem,
         configuration: AKPlayerConfiguration) {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        self.playerItem = playerItem
        self.configuration = configuration
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
        playerItemIsPlaybackLikelyToKeepUpObserver?.invalidate()
        playerItemIsPlaybackBufferEmptyObserver?.invalidate()
        playerItemIsPlaybackBufferFullObserver?.invalidate()
        
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Additional Helper Functions
    
    func startObservationIsPlaybackBufferEmpty() {
        /*
         playerItemIsPlaybackLikelyToKeepUpObserver = playerItem.observe(\AVPlayerItem.isPlaybackLikelyToKeepUp, options: [.initial, .new]) { [unowned self] (item, _) in
         DispatchQueue.main.async {
         onChangePlaybackLikelyToKeepUpStatus?(item.isPlaybackLikelyToKeepUp)
         }
         }
         
         playerItemIsPlaybackBufferFullObserver = playerItem.observe(\AVPlayerItem.isPlaybackBufferFull, options: [.initial, .new]) { [unowned self] (item, _) in
         DispatchQueue.main.async {
         onChangePlaybackBufferFullStatus?(item.isPlaybackBufferFull)
         }
         }
         
         */
        
        playerItemIsPlaybackBufferEmptyObserver = playerItem.observe(\AVPlayerItem.isPlaybackBufferEmpty, options: [.initial, .new]) { [weak self] (item, _) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.onChangePlaybackBufferEmptyStatus?(item.isPlaybackBufferEmpty)
            }
        }
    }
    
    func startObservationWithTimeInterval() {
        
        var remainingTime: TimeInterval = configuration.bufferObservingTimeout
        
        timer = Timer.scheduledTimer(withTimeInterval: configuration.bufferObservingTimeInterval, repeats: true, block: { [unowned self] (_) in
            remainingTime -= configuration.bufferObservingTimeInterval
            
            if playerItem.isPlaybackBufferFull || playerItem.isPlaybackLikelyToKeepUp {
                timer?.invalidate()
                onChangePlaybackBufferStatus?(true)
            } else if remainingTime <= 0 {
                timer?.invalidate()
                onChangePlaybackBufferStatus?(false)
            }else {
                AKPlayerLogger.shared.log(message: "Remaining time: \(remainingTime)", domain: .service)
            }
        })
    }
    
    func stop(clearCallBacks flag: Bool) {
        if flag {
            onChangePlaybackLikelyToKeepUpStatus = nil
            onChangePlaybackBufferFullStatus = nil
            onChangePlaybackBufferEmptyStatus = nil
            onChangePlaybackBufferStatus = nil
        }
        playerItemIsPlaybackLikelyToKeepUpObserver?.invalidate()
        playerItemIsPlaybackBufferFullObserver?.invalidate()
        playerItemIsPlaybackBufferEmptyObserver?.invalidate()
        timer?.invalidate()
        timer = nil
    }
}
