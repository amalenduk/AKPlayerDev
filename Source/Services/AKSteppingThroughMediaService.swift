//
//  AKSteppingThroughMediaService.swift
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

final class AKSteppingThroughMediaService {
    
    // MARK: - Properties
    
    private unowned var playerItem: AVPlayerItem

    var onChangecanStepForwardCallback: ((Bool) -> Void)?
    var onChangecanStepBackwardCallback: ((Bool) -> Void)?

    /**
     The `NSKeyValueObservation` for the KVO on
     `\AVPlayerItem.canStepForward`.
     */
    private var playerItemCanStepForwardObserver: NSKeyValueObservation?

    /**
     The `NSKeyValueObservation` for the KVO on
     `\AVPlayerItem.canStepBackward`.
     */
    private var playerItemCanStepBackwardObserver: NSKeyValueObservation?
    
    // MARK: - Init
    
    init(with playerItem: AVPlayerItem) {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        self.playerItem = playerItem
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
    }
    
    // MARK: - Additional Helper Functions
    
    func canStep(byCount stepCount: Int) -> (canStep: Bool, reason: AKPlayerUnavailableActionReason?) {
        var isForward: Bool {
            return stepCount.signum() == 1
        }
        if isForward {
            if playerItem.canStepForward {
                return (true, nil)
            }else {
                return (false, .canNotStepForward)
            }
        }else {
            if playerItem.canStepForward {
                return (true, nil)
            }else {
                return (false, .canNotStepBackward)
            }
        }
    }

    func startObserving() {
        playerItemCanStepForwardObserver = playerItem.observe(\AVPlayerItem.canStepForward, options: [.initial, .new]) { [unowned self] (item, _) in
            onChangecanStepForwardCallback?(item.canStepForward)
        }

        playerItemCanStepBackwardObserver = playerItem.observe(\AVPlayerItem.canStepBackward, options: [.initial, .new]) { [unowned self] (item, _) in
            onChangecanStepBackwardCallback?(item.canStepBackward)
        }
    }
}
