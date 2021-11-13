//
//  AKSilenceSecondaryAudioHintTypeEventProducer.swift
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

// Ref: https://developer.apple.com/documentation/avfaudio/avaudiosession/1616622-silencesecondaryaudiohintnotific

import AVFoundation

public protocol AKSilenceSecondaryAudioHinTypeEventProducible: AKEventProducer {
    var audioSession: AVAudioSession { get }
}

open class AKSilenceSecondaryAudioHintTypeEventProducer: AKSilenceSecondaryAudioHinTypeEventProducible {
    
    public enum SilenceSecondaryAudioHintEvent: AKEvent {
        case silenceSecondaryAudioHintTypeChanged(hintType: AVAudioSession.SilenceSecondaryAudioHintType)
    }
    
    // MARK: - Properties
    
    open weak var eventListener: AKEventListener?
    
    public let audioSession: AVAudioSession
    
    private var listening = false
    
    // MARK: - Init
    
    public init(audioSession: AVAudioSession) {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        self.audioSession = audioSession
    }
    
    deinit {
        stopProducingEvents()
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
    }
    
    open func startProducingEvents() {
        guard !listening else { return }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSecondaryAudio(_ :)),
                                               name: AVAudioSession.silenceSecondaryAudioHintNotification,
                                               object: audioSession)
        
        listening = true
    }
    
    open func stopProducingEvents() {
        guard listening else { return }
        
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.silenceSecondaryAudioHintNotification,
                                                  object: audioSession)
        
        listening = false
    }
    
    @objc open func handleSecondaryAudio(_ notification: Notification) {
        // Determine hint type
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
              let type = AVAudioSession.SilenceSecondaryAudioHintType(rawValue: typeValue) else {
                  return
              }
        eventListener?.onEvent(SilenceSecondaryAudioHintEvent.silenceSecondaryAudioHintTypeChanged(hintType: type),
                               generetedBy: self)
    }
}
