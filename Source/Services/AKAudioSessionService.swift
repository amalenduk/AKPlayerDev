//
//  AKAudioSessionService.swift
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

public protocol AKAudioSessionServiceable {
    var audioSession: AVAudioSession { get }
    func activate(_ active: Bool) -> Error?
    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions)
}

open class AKAudioSessionService: AKAudioSessionServiceable {
    
    // MARK: - Properties
    
    public let audioSession: AVAudioSession
    private var audioSessionInterruptionObservingService: AKAudioSessionInterruptionObservingServiceable!
    
    // MARK: - Init
    
    public init(audioSession: AVAudioSession = AVAudioSession.sharedInstance()) {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        self.audioSession = audioSession
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
    }
    
    @discardableResult open func activate(_ active: Bool) -> Error? {
        var err: Error?
        do {
            try audioSession.setActive(active, options: [])
            AKPlayerLogger.shared.log(message: "Active audio session: \(active)", domain: .service)
        } catch {
            err = error
            AKPlayerLogger.shared.log(message: "Active audio session: \(active) : \(error.localizedDescription)", domain: .error)
        }
        return err
    }
    
    open func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode = .default, options: AVAudioSession.CategoryOptions = []) {
        do {
            try audioSession.setCategory(category, mode: mode, options: options)
            AKPlayerLogger.shared.log(message: "Set audio session category to: \(category)", domain: .service)
        } catch let error {
            AKPlayerLogger.shared.log(message: "Set \(category) category: \(error.localizedDescription)", domain: .error)
        }
    }
    
    private func startAudioSessionInterruptionObserving() {
        audioSessionInterruptionObservingService = AKAudioSessionInterruptionObservingService(audioSession: audioSession)
        
        audioSessionInterruptionObservingService.onInterruptionBegan = { [unowned self] in
            activate(true)
        }
        
        audioSessionInterruptionObservingService.onInterruptionEnded = { [unowned self] shouldResume in
            activate(false)
        }
    }
}

