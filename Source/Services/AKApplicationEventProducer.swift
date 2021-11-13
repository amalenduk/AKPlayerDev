//
//  AKApplicationEventProducer.swift
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

public protocol AKApplicationEventProducible: AKEventProducer {
}

open class AKApplicationEventProducer: AKApplicationEventProducible {
    
    public enum ApplicationEvent: AKEvent {
        case willResignActive
        case didBecomeActive
        case didEnterBackground
        case willEnterForeground
    }
    
    // MARK: - Properties
    
    open weak var eventListener: AKEventListener?
    
    private var listening = false
    
    // MARK: - Init
    
    public init() {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
    }
    
    deinit {
        stopProducingEvents()
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
    }
    
    open func startProducingEvents() {
        guard !listening else { return }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleApplicationWillResignActive(_:)),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleApplicationDidBecomeActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleApplicationDidEnterBackground(_ :)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleApplicationWillEnterForeground(_ :)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
        
        listening = true
    }
    
    open func stopProducingEvents() {
        guard listening else { return }
        
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willResignActiveNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willEnterForegroundNotification,
                                                  object: nil)
        
        listening = false
    }
    
    @objc open func handleApplicationWillResignActive(_ notification: Notification) {
        eventListener?.onEvent(ApplicationEvent.willResignActive, generetedBy: self)
    }
    
    @objc open func handleApplicationDidBecomeActive(_ notification: Notification) {
        eventListener?.onEvent(ApplicationEvent.didBecomeActive, generetedBy: self)
    }
    
    @objc open func handleApplicationDidEnterBackground(_ notification: Notification) {
        eventListener?.onEvent(ApplicationEvent.didEnterBackground, generetedBy: self)
    }
    
    @objc open func handleApplicationWillEnterForeground(_ notification: Notification) {
        eventListener?.onEvent(ApplicationEvent.willEnterForeground, generetedBy: self)
    }
}
