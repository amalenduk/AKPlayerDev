//
//  AKRemoteCommand.swift
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

import Foundation
import MediaPlayer

public typealias AKRemoteCommandHandler = (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus

public protocol AKRemoteCommandProtocol {
    associatedtype RemoteCommand: MPRemoteCommand
    var id: String { get }
    var commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand> { get }
    var handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler> { get }
}

public enum AKRemoteCommand {
    
    case play,
         pause,
         stop,
         togglePlayPause
    case nextTrack,
         previousTrack,
         changeRepeatMode,
         changeShuffleMode
    case changePlaybackRate(supportedPlaybackRates: [NSNumber]),
         seekBackward,
         seekForward,
         skipBackward(preferredIntervals: [NSNumber]),
         skipForward(preferredIntervals: [NSNumber]),
         changePlaybackPosition
    case rating,
         like,
         dislike
    case bookmark
    case enableLanguageOption,
         disableLanguageOption
    
    public static var playbackCommands: [AKRemoteCommand] {
        return [.play,
                .pause,
                .stop,
                .togglePlayPause]
    }
    
    public static var navigatingBetweenTracksCommands: [AKRemoteCommand] {
        return [.nextTrack,
                .previousTrack,
                .changeRepeatMode,
                .changeShuffleMode]
    }
    
    public static var navigatingTrackContentsCommands: [AKRemoteCommand] {
        return [.changePlaybackRate(supportedPlaybackRates: AKPlaybackRate.allCases.map({NSNumber(value: $0.rate)})),
                .seekBackward,
                .seekForward,
                .skipBackward(preferredIntervals: [15.0]),
                .skipForward(preferredIntervals: [15.0]),
                .changePlaybackPosition]
    }
    
    public static var ratingMediaItemsCommands: [AKRemoteCommand] {
        return [.rating,
                .like,
                .dislike]
    }
    
    public static var bookmarkingMediaItemsCommands: [AKRemoteCommand] {
        return [.bookmark]
    }
    
    public static var enablingLanguageOptionsCommands: [AKRemoteCommand] {
        return [.enableLanguageOption,
                .disableLanguageOption]
    }
    
    /**
     All values in an array for convenience.
     Don't use for associated values.
     */
    static internal func all() -> [AKRemoteCommand] {
        return [
            .play,
            .pause,
            .stop,
            .togglePlayPause,
            .nextTrack,
            .previousTrack,
            .changeRepeatMode,
            .changeShuffleMode,
            .changePlaybackRate(supportedPlaybackRates: []),
            .seekBackward,
            .seekForward,
            .skipBackward(preferredIntervals: []),
            .skipForward(preferredIntervals: []),
            .changePlaybackPosition,
            .rating,
            .like,
            .dislike,
            .bookmark,
            .enableLanguageOption,
            .disableLanguageOption,
        ]
    }
}

public struct AKPlaybackRemoteCommand: AKRemoteCommandProtocol {
    
    public static let play = AKPlaybackRemoteCommand(id: "Play", commandKeyPath: \MPRemoteCommandCenter.playCommand, handlerKeyPath: \AKRemoteCommandController.handlePlayCommand)
    
    public static let pause = AKPlaybackRemoteCommand(id: "Pause", commandKeyPath: \MPRemoteCommandCenter.pauseCommand, handlerKeyPath: \AKRemoteCommandController.handlePauseCommand)
    
    public static let stop = AKPlaybackRemoteCommand(id: "Stop", commandKeyPath: \MPRemoteCommandCenter.stopCommand, handlerKeyPath: \AKRemoteCommandController.handleStopCommand)
    
    public static let togglePlayPause = AKPlaybackRemoteCommand(id: "TogglePlayPause", commandKeyPath: \MPRemoteCommandCenter.togglePlayPauseCommand, handlerKeyPath: \AKRemoteCommandController.handleTogglePlayPauseCommand)
    
    public typealias RemoteCommand = MPRemoteCommand
    
    public let id: String
    
    public let commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand>
    
    public let handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler>
}

public struct AKNavigatingBetweenTracksCommand: AKRemoteCommandProtocol {
    
    public static let nextTrack = AKNavigatingBetweenTracksCommand(id: "Next", commandKeyPath: \MPRemoteCommandCenter.nextTrackCommand, handlerKeyPath: \AKRemoteCommandController.handleNextTrackCommand)
    
    public static let previousTrack = AKNavigatingBetweenTracksCommand(id: "Previous", commandKeyPath: \MPRemoteCommandCenter.previousTrackCommand, handlerKeyPath: \AKRemoteCommandController.handlePreviousTrackCommand)
    
    public typealias RemoteCommand = MPRemoteCommand
    
    public let id: String
    
    public let commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand>
    
    public let handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler>
}

public struct AKNavigatingTrackContentsCommand: AKRemoteCommandProtocol {
    
    public static let seekBackward = AKNavigatingTrackContentsCommand(id: "Seek Backward", commandKeyPath: \MPRemoteCommandCenter.seekBackwardCommand, handlerKeyPath: \AKRemoteCommandController.handleSeekBackwardCommand)
    
    public static let seekForward = AKNavigatingTrackContentsCommand(id: "Seek Forward", commandKeyPath: \MPRemoteCommandCenter.seekForwardCommand, handlerKeyPath: \AKRemoteCommandController.handleSeekForwardCommand)
    
    public typealias RemoteCommand = MPRemoteCommand
    
    public let id: String
    
    public let commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand>
    
    public let handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler>
}

public struct AKSkipIntervalCommand: AKRemoteCommandProtocol {
    
    public static let skipBackward = AKSkipIntervalCommand(id: "Skip Backward", commandKeyPath: \MPRemoteCommandCenter.skipBackwardCommand, handlerKeyPath: \AKRemoteCommandController.handleSkipBackwardCommand)
    
    public static let skipForward = AKSkipIntervalCommand(id: "Skip Forward", commandKeyPath: \MPRemoteCommandCenter.skipForwardCommand, handlerKeyPath: \AKRemoteCommandController.handleSkipForwardCommand)
    
    public typealias RemoteCommand = MPSkipIntervalCommand
    
    public let id: String
    
    public let commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand>
    
    public let handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler>
    
    func set(preferredIntervals: [NSNumber]) -> AKSkipIntervalCommand {
        MPRemoteCommandCenter.shared()[keyPath: commandKeyPath].preferredIntervals = preferredIntervals
        return self
    }
}

public struct AKChangePlaybackRateCommand: AKRemoteCommandProtocol {
    
    public static let changePlaybackRate = AKChangePlaybackRateCommand(id: "Playback Rate", commandKeyPath: \MPRemoteCommandCenter.changePlaybackRateCommand, handlerKeyPath: \AKRemoteCommandController.handleChangePlaybackRateCommand)
    
    public typealias RemoteCommand = MPChangePlaybackRateCommand
    
    public let id: String
    
    public let commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand>
    
    public let handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler>
    
    func set(supportedPlaybackRates: [NSNumber]) -> AKChangePlaybackRateCommand {
        MPRemoteCommandCenter.shared().changePlaybackRateCommand.supportedPlaybackRates = supportedPlaybackRates
        return self
    }
}

public struct AKChangePlaybackPositionCommand: AKRemoteCommandProtocol {
    
    public static let changePlaybackPosition = AKChangePlaybackPositionCommand(id: "Change Playback Position", commandKeyPath: \MPRemoteCommandCenter.changePlaybackPositionCommand, handlerKeyPath: \AKRemoteCommandController.handleChangePlaybackPositionCommand)
    
    public typealias RemoteCommand = MPChangePlaybackPositionCommand
    
    public let id: String
    
    public let commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand>
    
    public let handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler>
}

public struct AKRatingCommand: AKRemoteCommandProtocol {
    
    public static let rating = AKRatingCommand(id: "Rating", commandKeyPath: \MPRemoteCommandCenter.ratingCommand, handlerKeyPath: \AKRemoteCommandController.handleRatingCommand)
    
    public typealias RemoteCommand = MPRatingCommand
    
    public let id: String
    
    public let commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand>
    
    public let handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler>
}

public struct AKRatingMediaItemsCommand: AKRemoteCommandProtocol {
    
    public static let like = AKRatingMediaItemsCommand(id: "Like", commandKeyPath: \MPRemoteCommandCenter.likeCommand, handlerKeyPath: \AKRemoteCommandController.handleLikeCommand)
    
    public static let dislike = AKRatingMediaItemsCommand(id: "Dislike", commandKeyPath: \MPRemoteCommandCenter.dislikeCommand, handlerKeyPath: \AKRemoteCommandController.handleDislikeCommand)
    
    public static let bookmark = AKRatingMediaItemsCommand(id: "Bookmark", commandKeyPath: \MPRemoteCommandCenter.bookmarkCommand, handlerKeyPath: \AKRemoteCommandController.handleSeekBackwardCommand)
    
    public typealias RemoteCommand = MPFeedbackCommand
    
    public let id: String
    
    public let commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand>
    
    public let handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler>
}

public struct AKChangeRepeatModeCommand: AKRemoteCommandProtocol {
    
    public static let changeRepeatMode = AKChangeRepeatModeCommand(id: "ChangeRepeatMode", commandKeyPath: \MPRemoteCommandCenter.changeRepeatModeCommand, handlerKeyPath: \AKRemoteCommandController.handleChangeRepeatModeCommand)
    
    public typealias RemoteCommand = MPChangeRepeatModeCommand
    
    public let id: String
    
    public let commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand>
    
    public let handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler>
}

public struct AKChangeShuffleModeCommand: AKRemoteCommandProtocol {
    
    public static let changeShuffleMode = AKChangeShuffleModeCommand(id: "ChangeShuffleMode", commandKeyPath: \MPRemoteCommandCenter.changeShuffleModeCommand, handlerKeyPath: \AKRemoteCommandController.handleChangeShuffleModeCommand)
    
    public typealias RemoteCommand = MPChangeShuffleModeCommand
    
    public let id: String
    
    public let commandKeyPath: KeyPath<MPRemoteCommandCenter, RemoteCommand>
    
    public let handlerKeyPath: KeyPath<AKRemoteCommandController, AKRemoteCommandHandler>
}
