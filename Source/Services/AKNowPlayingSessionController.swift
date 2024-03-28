//
//  AKRemoteCommandController.swift
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

import MediaPlayer

public protocol AKNowPlayingSessionControllerDelegate: AnyObject {
    func nowPlayingSessionController(_ controller: AKNowPlayingSessionControllerProtocol,
                                     didReceive command: AKRemoteCommand,
                                     with event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
}

public protocol AKNowPlayingSessionControllerProtocol {
    
    var nowPlayingSession: MPNowPlayingSession { get }
    var delegate: AKNowPlayingSessionControllerDelegate? { get }
    
    var playCommandHandler: AKRemoteCommandHandler { get }
    var pauseCommandHandler: AKRemoteCommandHandler { get }
    var stopCommandHandler: AKRemoteCommandHandler { get }
    var togglePlayPauseCommandHandler: AKRemoteCommandHandler { get }
    var nextTrackCommandHandler: AKRemoteCommandHandler { get }
    var previousTrackCommandHandler: AKRemoteCommandHandler { get }
    var changeRepeatModeCommandHandler: AKRemoteCommandHandler { get }
    var changeShuffleModeCommandHandler: AKRemoteCommandHandler { get }
    var changePlaybackRateCommandHandler: AKRemoteCommandHandler { get }
    var seekBackwardCommandHandler: AKRemoteCommandHandler { get }
    var seekForwardCommandHandler: AKRemoteCommandHandler { get }
    var skipBackwardCommandHandler: AKRemoteCommandHandler { get }
    var skipForwardCommandHandler: AKRemoteCommandHandler { get }
    var changePlaybackPositionCommandHandler: AKRemoteCommandHandler { get }
    var ratingCommandHandler: AKRemoteCommandHandler { get }
    var likeCommandHandler: AKRemoteCommandHandler { get }
    var dislikeCommandHandler: AKRemoteCommandHandler { get }
    var bookmarkCommandHandler: AKRemoteCommandHandler { get }
}

public class AKNowPlayingSessionController: AKNowPlayingSessionControllerProtocol {
    
    // MARK: - Properties
    
    public let nowPlayingSession: MPNowPlayingSession
    private var commandTargetPointers: [String: Any] = [:]
    
    public weak var delegate: AKNowPlayingSessionControllerDelegate?
    
    public lazy var playCommandHandler: AKRemoteCommandHandler = playCommandHandler(event:)
    public lazy var pauseCommandHandler: AKRemoteCommandHandler = pauseCommandHandler(event:)
    public lazy var stopCommandHandler: AKRemoteCommandHandler = stopCommandHandler(event:)
    public lazy var togglePlayPauseCommandHandler: AKRemoteCommandHandler = togglePlayPauseCommandCommandHandler(event:)
    public lazy var nextTrackCommandHandler: AKRemoteCommandHandler = nextTrackCommandHandler(event:)
    public lazy var previousTrackCommandHandler: AKRemoteCommandHandler = previousTrackCommandHandler(event:)
    public lazy var changeRepeatModeCommandHandler: AKRemoteCommandHandler = changeRepeatModeCommandHandler(event:)
    public lazy var changeShuffleModeCommandHandler: AKRemoteCommandHandler = changeShuffleModeCommandHandler(event:)
    public lazy var changePlaybackRateCommandHandler: AKRemoteCommandHandler = changePlaybackRateCommandHandler(event:)
    public lazy var seekBackwardCommandHandler: AKRemoteCommandHandler = seekBackwardCommandHandler(event:)
    public lazy var seekForwardCommandHandler: AKRemoteCommandHandler = seekForwardCommandHandler(event:)
    public lazy var skipBackwardCommandHandler: AKRemoteCommandHandler = skipBackwardCommandHandler(event:)
    public lazy var skipForwardCommandHandler: AKRemoteCommandHandler = skipForwardCommandHandler(event:)
    public lazy var changePlaybackPositionCommandHandler: AKRemoteCommandHandler = changePlaybackPositionCommandHandler(event:)
    public lazy var ratingCommandHandler: AKRemoteCommandHandler = ratingCommandHandler(event:)
    public lazy var likeCommandHandler: AKRemoteCommandHandler = likeCommandHandler(event:)
    public lazy var dislikeCommandHandler: AKRemoteCommandHandler = dislikeCommandHandler(event:)
    public lazy var bookmarkCommandHandler: AKRemoteCommandHandler = bookmarkCommandHandler(event:)
    
    // MARK: - Init
    
    public init(players: [AVPlayer]) {
        nowPlayingSession = MPNowPlayingSession(players: players)
    }
    
    deinit {
        unregister(commands: AKRemoteCommand.all())
        clearNowPlayingPlaybackInfo()
        delegate = nil
        print("Deinit called from ", #file)
    }
    
    public func addPlayer(_ player: AVPlayer) {
        nowPlayingSession.addPlayer(player)
    }
    
    public func removePlayer(_ player: AVPlayer) {
        nowPlayingSession.addPlayer(player)
    }
    
    public func becomeActiveIfPossible() async -> Bool {
        return await nowPlayingSession.becomeActiveIfPossible()
    }
    
    public func canBecomeActive() -> Bool {
        return nowPlayingSession.canBecomeActive
    }
    
    public func register(commands: [AKRemoteCommand]) {
        commands.forEach { (command) in
            commandTargetPointers[String(describing: command)] = self.register(command.registration)
        }
    }
    
    public func unregister(commands: [AKRemoteCommand]) {
        commands.forEach { (command) in
            self.unregister(command.registration)
        }
    }
    
    internal func enable(commands: [AKRemoteCommand]) {
        commands.forEach { (command) in
            self.enable(command.registration)
        }
    }
    
    internal func disable(commands: [AKRemoteCommand]) {
        commands.forEach { (command) in
            self.disable(command.registration)
        }
    }
    
    private func enable<Command: AKRemoteCommandRegistrable>(_ command: Command) {
        nowPlayingSession.remoteCommandCenter[keyPath: command.command].isEnabled = true
    }
    
    private func disable<Command: AKRemoteCommandRegistrable>(_ command: Command) {
        nowPlayingSession.remoteCommandCenter[keyPath: command.command].isEnabled = true
    }
    
    private func register<Command: AKRemoteCommandRegistrable>(_ command: Command) -> Any {
        return nowPlayingSession.remoteCommandCenter[keyPath: command.command].addTarget(handler: self[keyPath: command.handler])
    }
    
    private func unregister<Command: AKRemoteCommandRegistrable>(_ command: Command) {
        nowPlayingSession.remoteCommandCenter[keyPath: command.command].removeTarget(commandTargetPointers[String(describing: command)])
    }
    
    public func setNowPlayingInfo(_ metadata: AKNowPlayableMetadata?) {
        guard let metadata = metadata,
              let nowPlayingInfo = metadata.getNowPlayingInfo() else { return clearNowPlayingPlaybackInfo() }
        
        nowPlayingSession.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    public func clearNowPlayingPlaybackInfo() {
        nowPlayingSession.nowPlayingInfoCenter.nowPlayingInfo = nil
    }
    
    // MARK: - Additional Helper Functions
    
    private func playCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func pauseCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func stopCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func togglePlayPauseCommandCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func nextTrackCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func previousTrackCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func changeRepeatModeCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func changeShuffleModeCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func changePlaybackRateCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func seekBackwardCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func seekForwardCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func skipBackwardCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func skipForwardCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func changePlaybackPositionCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func ratingCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func likeCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func dislikeCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
    
    private func bookmarkCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return delegate?.nowPlayingSessionController(self,
                                                     didReceive: .play, with: event) ?? .commandFailed
    }
}
