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

public protocol AKRemoteCommandControllable {
    var handlePlayCommand: AKRemoteCommandHandler { get }
    var handlePauseCommand: AKRemoteCommandHandler { get }
    var handleStopCommand: AKRemoteCommandHandler { get }
    var handleTogglePlayPauseCommand: AKRemoteCommandHandler { get }
    var handleNextTrackCommand: AKRemoteCommandHandler { get }
    var handlePreviousTrackCommand: AKRemoteCommandHandler { get }
    var handleChangeRepeatModeCommand: AKRemoteCommandHandler { get }
    var handleChangeShuffleModeCommand: AKRemoteCommandHandler { get }
    var handleChangePlaybackRateCommand: AKRemoteCommandHandler { get }
    var handleSeekBackwardCommand: AKRemoteCommandHandler { get }
    var handleSeekForwardCommand: AKRemoteCommandHandler { get }
    var handleSkipBackwardCommand: AKRemoteCommandHandler { get }
    var handleSkipForwardCommand: AKRemoteCommandHandler { get }
    var handleChangePlaybackPositionCommand: AKRemoteCommandHandler { get }
    var handleRatingCommand: AKRemoteCommandHandler { get }
    var handleLikeCommand: AKRemoteCommandHandler { get }
    var handleDislikeCommand: AKRemoteCommandHandler { get }
    var handleBookmarkCommand: AKRemoteCommandHandler { get }
}

public class AKRemoteCommandController: AKRemoteCommandControllable {
    
    // MARK: - Properties
    
    private let center: MPRemoteCommandCenter
    private var commandTargetPointers: [String: Any] = [:]
    unowned internal var manager: AKPlayerManagerProtocol!
    
    public lazy var handlePlayCommand: AKRemoteCommandHandler = playCommandHandler(event:)
    public lazy var handlePauseCommand: AKRemoteCommandHandler = pauseCommandHandler(event:)
    public lazy var handleStopCommand: AKRemoteCommandHandler = stopCommandHandler(event:)
    public lazy var handleTogglePlayPauseCommand: AKRemoteCommandHandler = togglePlayPauseCommandCommandHandler(event:)
    public lazy var handleNextTrackCommand: AKRemoteCommandHandler = nextTrackCommandHandler
    public lazy var handlePreviousTrackCommand: AKRemoteCommandHandler = previousTrackCommandHandler
    public lazy var handleChangeRepeatModeCommand: AKRemoteCommandHandler = changeRepeatModeCommandHandler
    public lazy var handleChangeShuffleModeCommand: AKRemoteCommandHandler = changeShuffleModeCommandHandler
    public lazy var handleChangePlaybackRateCommand: AKRemoteCommandHandler = changePlaybackRateCommandHandler(event:)
    public lazy var handleSeekBackwardCommand: AKRemoteCommandHandler = seekBackwardCommandHandler(event:)
    public lazy var handleSeekForwardCommand: AKRemoteCommandHandler = seekForwardCommandHandler(event:)
    public lazy var handleSkipBackwardCommand: AKRemoteCommandHandler = skipBackwardCommandHandler(event:)
    public lazy var handleSkipForwardCommand: AKRemoteCommandHandler = skipForwardCommandHandler(event:)
    public lazy var handleChangePlaybackPositionCommand: AKRemoteCommandHandler = changePlaybackPositionCommandHandler(event:)
    public lazy var handleRatingCommand: AKRemoteCommandHandler = ratingCommandHandler(event:)
    public lazy var handleLikeCommand: AKRemoteCommandHandler = likeCommandHandler(event:)
    public lazy var handleDislikeCommand: AKRemoteCommandHandler = dislikeCommandHandler(event:)
    public lazy var handleBookmarkCommand: AKRemoteCommandHandler = bookmarkCommandHandler(event:)
    
    // MARK: - Init
    
    public init(remoteCommandCenter: MPRemoteCommandCenter = MPRemoteCommandCenter.shared()) {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        self.center = remoteCommandCenter
    }
    
    deinit {
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
    }
    
    // MARK: - Additional Helper Functions
    
    internal func enable(commands: [AKRemoteCommand]) {
        disable(commands: AKRemoteCommand.all())
        commands.forEach { (command) in
            self.enable(command: command)
            
        }
    }
    
    internal func disable(commands: [AKRemoteCommand]) {
        commands.forEach { (command) in
            self.disable(command: command)
        }
    }
    
    private func enable(command: AKRemoteCommand) {
        switch command {
        
        case .pause:
            enableCommand(AKPlaybackRemoteCommand.pause)
        case .play:
            enableCommand(AKPlaybackRemoteCommand.play)
        case .stop:
            enableCommand(AKPlaybackRemoteCommand.stop)
        case .togglePlayPause:
            enableCommand(AKPlaybackRemoteCommand.togglePlayPause)
        case .nextTrack:
            enableCommand(AKNavigatingBetweenTracksCommand.nextTrack)
        case .previousTrack:
            enableCommand(AKNavigatingBetweenTracksCommand.previousTrack)
        case .changeRepeatMode:
            enableCommand(AKChangeRepeatModeCommand.changeRepeatMode)
        case .changeShuffleMode:
            enableCommand(AKChangeShuffleModeCommand.changeShuffleMode)
        case .changePlaybackRate(supportedPlaybackRates: let supportedPlaybackRates):
            enableCommand(AKChangePlaybackRateCommand.changePlaybackRate.set(supportedPlaybackRates: supportedPlaybackRates))
        case .seekBackward:
            enableCommand(AKNavigatingTrackContentsCommand.seekBackward)
        case .seekForward:
            enableCommand(AKNavigatingTrackContentsCommand.seekForward)
        case .skipBackward(preferredIntervals: let preferredIntervals):
            enableCommand(AKSkipIntervalCommand.skipBackward.set(preferredIntervals: preferredIntervals))
        case .skipForward(preferredIntervals: let preferredIntervals):
            enableCommand(AKSkipIntervalCommand.skipForward.set(preferredIntervals: preferredIntervals))
        case .changePlaybackPosition:
            enableCommand(AKChangePlaybackPositionCommand.changePlaybackPosition)
        case .rating:
            enableCommand(AKRatingCommand.rating)
        case .like:
            enableCommand(AKRatingMediaItemsCommand.like)
        case .dislike:
            enableCommand(AKRatingMediaItemsCommand.like)
        case .bookmark:
            enableCommand(AKRatingMediaItemsCommand.bookmark)
            break
        case .enableLanguageOption:
            break
        case .disableLanguageOption:
            break
        }
    }
    
    private func disable(command: AKRemoteCommand) {
        switch command {
        
        case .pause:
            disableCommand(AKPlaybackRemoteCommand.pause)
        case .play:
            disableCommand(AKPlaybackRemoteCommand.play)
        case .stop:
            disableCommand(AKPlaybackRemoteCommand.stop)
        case .togglePlayPause:
            disableCommand(AKPlaybackRemoteCommand.togglePlayPause)
        case .nextTrack:
            disableCommand(AKNavigatingBetweenTracksCommand.nextTrack)
        case .previousTrack:
            disableCommand(AKNavigatingBetweenTracksCommand.previousTrack)
        case .changeRepeatMode:
            disableCommand(AKChangeRepeatModeCommand.changeRepeatMode)
        case .changeShuffleMode:
            disableCommand(AKChangeShuffleModeCommand.changeShuffleMode)
        case .changePlaybackRate(supportedPlaybackRates: let supportedPlaybackRates):
            disableCommand(AKChangePlaybackRateCommand.changePlaybackRate.set(supportedPlaybackRates: supportedPlaybackRates))
        case .seekBackward:
            disableCommand(AKNavigatingTrackContentsCommand.seekBackward)
        case .seekForward:
            disableCommand(AKNavigatingTrackContentsCommand.seekForward)
        case .skipBackward(preferredIntervals: let preferredIntervals):
            disableCommand(AKSkipIntervalCommand.skipBackward.set(preferredIntervals: preferredIntervals))
        case .skipForward(preferredIntervals: let preferredIntervals):
            disableCommand(AKSkipIntervalCommand.skipForward.set(preferredIntervals: preferredIntervals))
        case .changePlaybackPosition:
            disableCommand(AKChangePlaybackPositionCommand.changePlaybackPosition)
        case .rating:
            disableCommand(AKRatingCommand.rating)
        case .like:
            disableCommand(AKRatingMediaItemsCommand.like)
        case .dislike:
            disableCommand(AKRatingMediaItemsCommand.like)
        case .bookmark:
            disableCommand(AKRatingMediaItemsCommand.bookmark)
        case .enableLanguageOption:
            break
        case .disableLanguageOption:
            break
        }
    }
    
    private func enableCommand<Command: AKRemoteCommandProtocol>(_ command: Command) {
        center[keyPath: command.commandKeyPath].isEnabled = true
        center[keyPath: command.commandKeyPath].addTarget(handler: self[keyPath: command.handlerKeyPath])
    }
    
    private func disableCommand<Command: AKRemoteCommandProtocol>(_ command: Command) {
        center[keyPath: command.commandKeyPath].isEnabled = false
        center[keyPath: command.commandKeyPath].removeTarget(commandTargetPointers[command.id])
    }
    
    private func playCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .play, with: event)
    }
    
    private func pauseCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .pause, with: event)
    }
    
    private func stopCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .stop, with: event)
    }
    
    private func togglePlayPauseCommandCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .togglePlayPause, with: event)
    }
    
    private func nextTrackCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .nextTrack, with: event)
    }
    
    private func previousTrackCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .previousTrack, with: event)
    }
    
    private func changeRepeatModeCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .changeRepeatMode, with: event)
    }
    
    private func changeShuffleModeCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .changeShuffleMode, with: event)
    }
    
    private func changePlaybackRateCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .changePlaybackRate(supportedPlaybackRates: []), with: event)
    }
    
    private func seekBackwardCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .seekBackward, with: event)
    }
    
    private func seekForwardCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .seekForward, with: event)
    }
    
    private func skipBackwardCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .skipBackward(preferredIntervals: []), with: event)
    }
    
    private func skipForwardCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .skipForward(preferredIntervals: []), with: event)
    }
    
    private func changePlaybackPositionCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .changePlaybackPosition, with: event)
    }
    
    private func ratingCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .rating, with: event)
    }
    
    private func likeCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .like, with: event)
    }
    
    private func dislikeCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .dislike, with: event)
    }
    
    private func bookmarkCommandHandler(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        return manager.handleRemoteCommand(command: .bookmark, with: event)
    }
}
