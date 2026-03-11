//
//  AKStoppedState.swift
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
import Combine

public class AKStoppedState: AKBaseState {
    
    // MARK: - Properties
    
    private var subscriptions: Set<AnyCancellable> = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol) {
        super.init(playerController: playerController, state: .stopped)
    }
    
    deinit {
        subscriptions.removeAll()
    }
    
    public override func processStateChange() {
        startObservingPlayerStatus()
        
        if !playerController.player.timeControlStatus.isPaused {
            playerController.player.pause()
        }
        
        playerController.currentMedia?.playerItem?.cancelPendingSeeks()
        playerController.player.replaceCurrentItem(with: nil)
    }
    
    // MARK: - Commands
    
    public override func play() {
        playerController.delegate?.playerController(playerController,
                                                    didEncounterUnavailableAction: .loadMediaFirst)
    }
    
    public override func play(at rate: AKPlaybackRate) {
        playerController.delegate?.playerController(playerController,
                                                    didEncounterUnavailableAction: .loadMediaFirst)
    }
    
    public override func pause() {
        playerController.delegate?.playerController(playerController,
                                                    didEncounterUnavailableAction: .alreadyStopped)
    }
    
    public override func togglePlayPause() {
        playerController.delegate?.playerController(playerController,
                                                    didEncounterUnavailableAction: .loadMediaFirst)
    }
    
    public override func stop() {
        playerController.delegate?.playerController(playerController,
                                                    didEncounterUnavailableAction: .alreadyStopped)
    }
    
    // MARK: - Additional Helper Functions
    
    private func startObservingPlayerStatus() {
        playerController.player.publisher(for: \.status)
            .prepend(playerController.player.status)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] status in
                guard status == .failed else { return }
                let controller = AKFailedState(playerController: playerController,
                                               error: .playerCanNoLongerPlay(error: playerController.player.error))
                change(controller)
            }.store(in: &subscriptions)
    }
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
        subscriptions.removeAll()
        playerController.change(controller)
    }
    
    public override func canSeek() -> (Bool, AKPlayerUnavailableCommandReason?) {
        return (false, .loadMediaFirst)
    }
    
    public override func canFastForward() -> (Bool, AKPlayerUnavailableCommandReason?) {
        return (false, .loadMediaFirst)
    }
    
    public override func canRewind() -> (Bool, AKPlayerUnavailableCommandReason?) {
        return (false, .loadMediaFirst)
    }
    
    public override func canStep() -> (Bool, AKPlayerUnavailableCommandReason?) {
        return (false, .loadMediaFirst)
    }
}
