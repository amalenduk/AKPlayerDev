//
//  AKSteppingThroughMediaEventProducer.swift
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

public protocol AKSteppingThroughMediaEventProducible: AKEventProducer {
    var playerItem: AVPlayerItem { get }
}

open class AKSteppingThroughMediaEventProducer: AKSteppingThroughMediaEventProducible {
    
    public enum SteppingThroughMediaEvent: AKEvent {
        case canStepForward(Bool)
        case canStepBackward(Bool)
    }
    
    // MARK: - Properties
    
    open weak var eventListener: AKEventListener?
    
    public var playerItem: AVPlayerItem
    
    private var listening = false
    
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
    
    public init(with playerItem: AVPlayerItem) {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        self.playerItem = playerItem
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
        stopProducingEvents()
    }
    
    // MARK: - Additional Helper Functions
    
    open func canStep(byCount stepCount: Int) -> (canStep: Bool, reason: AKPlayerUnavailableActionReason?) {
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
    
    open func startProducingEvents() {
        guard !listening else { return }
        
        playerItemCanStepForwardObserver = playerItem.observe(\AVPlayerItem.canStepForward, options: [.initial, .new]) { [unowned self] (_, change) in
            eventListener?.onEvent(SteppingThroughMediaEvent.canStepForward(change.newValue!), generetedBy: self)
        }
        
        playerItemCanStepBackwardObserver = playerItem.observe(\AVPlayerItem.canStepBackward, options: [.initial, .new]) { [unowned self] (_, change) in
            eventListener?.onEvent(SteppingThroughMediaEvent.canStepBackward(change.newValue!), generetedBy: self)
        }
        
        listening = true
    }
    
    open func stopProducingEvents() {
        guard listening else { return }
        
        playerItemCanStepForwardObserver?.invalidate()
        playerItemCanStepBackwardObserver?.invalidate()
        
        listening = false
    }
    
}
