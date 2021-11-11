//
//  AKAudioSessionInterruptionObservingService.swift
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

// Ref: https://developer.apple.com/documentation/avfaudio/avaudiosession/responding_to_audio_session_interruptions, https://developer.apple.com/documentation/avfaudio/avaudiosession/1616596-interruptionnotification

import AVFoundation

public protocol AKAudioSessionInterruptionObservingServiceable {
    var onInterruptionBegan: (() -> Void)? { get set }
    var onInterruptionEnded: ((_ shouldResume: Bool) -> Void)? { get set }
    
    func startRespondingOnInterruption()
    func stopRespondingOnInterruption()
}

open class AKAudioSessionInterruptionObservingService: AKAudioSessionInterruptionObservingServiceable {
    
    // MARK: - Properties
    
    public let audioSession: AVAudioSession
    
    open var onInterruptionBegan: (() -> Void)?
    open var onInterruptionEnded: ((_ shouldResume: Bool) -> Void)?
    
    // MARK: - Init
    
    public init(audioSession: AVAudioSession) {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        self.audioSession = audioSession
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
        stopRespondingOnInterruption()
    }
    
    public func startRespondingOnInterruption() {
        /* A notification that’s posted when an audio interruption occurs. */
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_ :)), name: AVAudioSession.interruptionNotification, object: audioSession)
    }
    
    public func stopRespondingOnInterruption() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: audioSession)
    }
    
    /* A notification that’s posted when an audio interruption occurs. */
    
    @objc open func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                  return
              }
        
        // Switch over the interruption type.
        switch type {
        case .began:
            // An interruption began. Update the UI as needed.
            onInterruptionBegan?()
        case .ended:
            // An interruption ended. Resume playback, if appropriate.
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Interruption ended. Playback should resume.
                onInterruptionEnded?(true)
            } else {
                // Interruption ended. Playback should not resume.
                onInterruptionEnded?(false)
            }
        default: ()
        }
    }
}

public protocol AKAudioSessionInterruptionEventProducible: AKEventProducer {
    var audioSession: AVAudioSession { get }
    var isInterrupted: Bool { get }
}

open class AKAudioSessionInterruptionEventProducer: AKAudioSessionInterruptionEventProducible {
    
    public enum AudioSessionInterruptionEvent: AKEvent {
        case interruptionBegan
        case interruptionEnded(shouldResume: Bool)
    }
    
    public typealias Event = AudioSessionInterruptionEvent
    
    // MARK: - Properties
    
    weak public var eventListener: AKEventListener?
    
    public let audioSession: AVAudioSession
    
    private var listening = false
    
    public private(set) var isInterrupted: Bool = false
    
    // MARK: - Init
    
    public init(audioSession: AVAudioSession) {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        self.audioSession = audioSession
    }
    
    deinit {
        stopProducingEvents()
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
    }
    
    public func startProducingEvents() {
        guard !listening else { return }
        
        /* A notification that’s posted when an audio interruption occurs. */
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_ :)), name: AVAudioSession.interruptionNotification, object: audioSession)
        
        listening = true
    }
    
    public func stopProducingEvents() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: audioSession)
        
        listening = false
    }
    
    /* A notification that’s posted when an audio interruption occurs. */
    
    @objc open func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                  return
              }
        
        // Switch over the interruption type.
        switch type {
        case .began:
            // An interruption began. Update the UI as needed.
            isInterrupted = true
            eventListener?.onEvent(AudioSessionInterruptionEvent.interruptionBegan, generetedBy: self)
        case .ended:
            // An interruption ended. Resume playback, if appropriate.
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            isInterrupted = false
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Interruption ended. Playback should resume.
                eventListener?.onEvent(AudioSessionInterruptionEvent.interruptionEnded(shouldResume: true), generetedBy: self)
            } else {
                // Interruption ended. Playback should not resume.
                eventListener?.onEvent(AudioSessionInterruptionEvent.interruptionEnded(shouldResume: false), generetedBy: self)
            }
        default: break
        }
    }
}
