//
//  AKDeterminingPlaybackCapabilitiesService.swift
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

final class AKDeterminingPlaybackCapabilitiesService {
    
    // MARK: - Properties
    
    private let playerItem: AVPlayerItem
    var onChangeCanPlayReverseCallback: ((Bool) -> Void)?
    var onChangeCanPlayFastForwardCallback: ((Bool) -> Void)?
    var onChangeCanPlayFastReverseCallback: ((Bool) -> Void)?
    var onChangeCanPlaySlowForwardCallback: ((Bool) -> Void)?
    var onChangeCanPlaySlowReverseCallback: ((Bool) -> Void)?

    /**
     The `NSKeyValueObservation` for the KVO on
     `\AVPlayerItem.canPlayReverse`.
     */
    private var playerItemCanPlayReverseObserver: NSKeyValueObservation?

    /**
     The `NSKeyValueObservation` for the KVO on
     `\AVPlayerItem.canPlayFastForward`.
     */
    private var playerItemCanPlayFastForwardObserver: NSKeyValueObservation?

    /**
     The `NSKeyValueObservation` for the KVO on
     `\AVPlayerItem.canPlayFastReverse`.
     */
    private var playerItemCanPlayFastReverseObserver: NSKeyValueObservation?

    /**
     The `NSKeyValueObservation` for the KVO on
     `\AVPlayerItem.canPlaySlowForward`.
     */
    private var playerItemCanPlaySlowForwardObserver: NSKeyValueObservation?

    /**
     The `NSKeyValueObservation` for the KVO on
     `\AVPlayerItem.canPlaySlowReverse`.
     */
    private var playerItemCanPlaySlowReverseObserver: NSKeyValueObservation?
    
    // MARK: - Init
    
    init(with playerItem: AVPlayerItem) {
        AKPlayerLogger.shared.log(message: "Init",
                                  domain: .lifecycleService)
        self.playerItem = playerItem
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit",
                                  domain: .lifecycleService)
        playerItemCanPlayReverseObserver?.invalidate()
        playerItemCanPlayFastForwardObserver?.invalidate()
        playerItemCanPlayFastReverseObserver?.invalidate()
        playerItemCanPlaySlowForwardObserver?.invalidate()
        playerItemCanPlaySlowReverseObserver?.invalidate()
    }

    // MARK: - Additional Helper Functions

    class func itemCanBePlayed(at rate: AKPlaybackRate, for playerItem: AVPlayerItem) -> Bool {
        switch rate.rate {
        case 0.0...:
            switch rate.rate {
            case 2.0...:
                return (playerItem.canPlayFastForward)
            case 1.0..<2.0:
                return(true)
            case 0.0..<1.0:
                return(playerItem.canPlaySlowForward)
            default:
                assertionFailure("Implement condition")
            }
        case ..<0.0:
            switch rate.rate {
            case -1.0:
                return(playerItem.canPlayReverse)
            case -1.0..<0.0:
                return(playerItem.canPlaySlowReverse)
            case ..<(-1.0):
                return(playerItem.canPlayFastReverse)
            default:
                assertionFailure("Implement condition")
            }
        default:
            assertionFailure("Implement condition")
        }
        assertionFailure("Implement condition")
        return false
    }

    func startObserving() {
        /*
         Register as an observer of the player item's canPlayReverse property
         */
        playerItemCanPlayReverseObserver = playerItem.observe(\AVPlayerItem.canPlayReverse, options: [.initial, .new]) { [unowned self] (item, _) in
            onChangeCanPlayReverseCallback?(item.canPlayReverse)
        }

        /*
         Register as an observer of the player item's canPlayFastForward property
         */
        playerItemCanPlayFastForwardObserver = playerItem.observe(\AVPlayerItem.canPlayFastForward, options: [.initial, .new]) { [unowned self] (item, _) in
            onChangeCanPlayFastForwardCallback?(item.canPlayFastForward)
        }

        /*
         Register as an observer of the player item's canPlayFastReverse property
         */
        playerItemCanPlayFastReverseObserver = playerItem.observe(\AVPlayerItem.canPlayFastReverse, options: [.initial, .new]) { [unowned self] (item, _) in
            onChangeCanPlayFastReverseCallback?(item.canPlayFastReverse)
        }

        /*
         Register as an observer of the player item's canPlaySlowForward property
         */
        playerItemCanPlaySlowForwardObserver = playerItem.observe(\AVPlayerItem.canPlaySlowForward, options: [.initial, .new]) { [unowned self] (item, _) in
            onChangeCanPlaySlowForwardCallback?(item.canPlaySlowForward)
        }

        /*
         Register as an observer of the player item's canPlaySlowReverse property
         */
        playerItemCanPlaySlowReverseObserver = playerItem.observe(\AVPlayerItem.canPlaySlowReverse, options: [.initial, .new]) { [unowned self] (item, _) in
            onChangeCanPlaySlowReverseCallback?(item.canPlaySlowReverse)
        }
    }
}
