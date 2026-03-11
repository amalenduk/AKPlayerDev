//
//  AKIdleState.swift
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

public class AKIdleState: AKBaseState {
    
    // MARK: - Properties
    
    // MARK: - Init
    
    public init(playerController: AKPlayerControllerProtocol) {
        super.init(playerController: playerController, state: .idle)
    }
    
    deinit { }
    
    public override func processStateChange() { }
    
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
                                                    didEncounterUnavailableAction: .loadMediaFirst)
    }
    
    public override func togglePlayPause() {
        playerController.delegate?.playerController(playerController,
                                                    didEncounterUnavailableAction: .loadMediaFirst)
    }
    
    public override func stop() {
        playerController.delegate?.playerController(playerController,
                                                    didEncounterUnavailableAction: .loadMediaFirst)
    }
    
    // MARK: - Additional Helper Functions
    
    private func change(_ controller: AKPlayerStateControllerProtocol) {
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
