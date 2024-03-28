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

public protocol AKRemoteCommandRegistrable {
    associatedtype Command: MPRemoteCommand
    
    var command: KeyPath<MPRemoteCommandCenter, Command> { get }
    var handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler> { get }
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

public extension AKRemoteCommand {
    
    var registration: any AKRemoteCommandRegistrable {
        switch self {
        case .play: return AKPlaybackRemoteCommand.play
        case .pause: return AKPlaybackRemoteCommand.pause
        case .stop: return AKPlaybackRemoteCommand.stop
        case .togglePlayPause: return AKPlaybackRemoteCommand.togglePlayPause
        case .nextTrack: return AKNavigatingBetweenTracksCommand.nextTrack
        case .previousTrack: return AKNavigatingBetweenTracksCommand.previousTrack
        case .changeRepeatMode: return AKChangeRepeatModeCommand.changeRepeatMode
        case .changeShuffleMode: return AKChangeShuffleModeCommand.changeShuffleMode
        case .changePlaybackRate: return AKChangePlaybackRateCommand.changePlaybackRate
        case .seekBackward: return AKNavigatingTrackContentsCommand.seekBackward
        case .seekForward: return AKNavigatingTrackContentsCommand.seekForward
        case .skipBackward: return AKSkipIntervalCommand.skipBackward
        case .skipForward: return AKSkipIntervalCommand.skipForward
        case .changePlaybackPosition: return AKChangePlaybackPositionCommand.changePlaybackPosition
        case .rating: return AKChangePlaybackPositionCommand.changePlaybackPosition
        case .like: return AKRatingMediaItemsCommand.like
        case .dislike: return AKRatingMediaItemsCommand.dislike
        case .bookmark: return AKRatingMediaItemsCommand.bookmark
        case .enableLanguageOption: return AKRatingMediaItemsCommand.bookmark
        case .disableLanguageOption: return AKRatingMediaItemsCommand.bookmark
        }
    }
}

public struct AKPlaybackRemoteCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPRemoteCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let play = AKPlaybackRemoteCommand(command: \MPRemoteCommandCenter.playCommand,
                                                     handler: \AKNowPlayingSessionController.playCommandHandler)
    public static let pause = AKPlaybackRemoteCommand(command: \MPRemoteCommandCenter.pauseCommand,
                                                      handler: \AKNowPlayingSessionController.pauseCommandHandler)
    public static let stop = AKPlaybackRemoteCommand(command: \MPRemoteCommandCenter.stopCommand,
                                                     handler: \AKNowPlayingSessionController.stopCommandHandler)
    public static let togglePlayPause = AKPlaybackRemoteCommand(command: \MPRemoteCommandCenter.togglePlayPauseCommand,
                                                                handler: \AKNowPlayingSessionController.togglePlayPauseCommandHandler)
}

public struct AKNavigatingBetweenTracksCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPRemoteCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let nextTrack = AKNavigatingBetweenTracksCommand(command: \MPRemoteCommandCenter.nextTrackCommand,
                                                                   handler: \AKNowPlayingSessionController.nextTrackCommandHandler)
    public static let previousTrack = AKNavigatingBetweenTracksCommand(command: \MPRemoteCommandCenter.previousTrackCommand,
                                                                       handler: \AKNowPlayingSessionController.previousTrackCommandHandler)
    
}

public struct AKNavigatingTrackContentsCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPRemoteCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let seekBackward = AKNavigatingTrackContentsCommand(command: \MPRemoteCommandCenter.seekBackwardCommand,
                                                                      handler: \AKNowPlayingSessionController.seekBackwardCommandHandler)
    
    public static let seekForward = AKNavigatingTrackContentsCommand(command: \MPRemoteCommandCenter.seekForwardCommand,
                                                                     handler: \AKNowPlayingSessionController.seekForwardCommandHandler)
}

public struct AKSkipIntervalCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPSkipIntervalCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let skipBackward = AKSkipIntervalCommand(command: \MPRemoteCommandCenter.skipBackwardCommand,
                                                           handler: \AKNowPlayingSessionController.skipBackwardCommandHandler)
    
    public static let skipForward = AKSkipIntervalCommand(command: \MPRemoteCommandCenter.skipForwardCommand,
                                                          handler: \AKNowPlayingSessionController.skipForwardCommandHandler)
    
    func set(preferredIntervals: [NSNumber]) {
        MPRemoteCommandCenter.shared()[keyPath: command].preferredIntervals = preferredIntervals
    }
}

public struct AKChangePlaybackRateCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPChangePlaybackRateCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let changePlaybackRate = AKChangePlaybackRateCommand(command: \MPRemoteCommandCenter.changePlaybackRateCommand,
                                                                       handler: \AKNowPlayingSessionController.changePlaybackRateCommandHandler)
}

public struct AKChangePlaybackPositionCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPChangePlaybackPositionCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let changePlaybackPosition = AKChangePlaybackPositionCommand(command: \MPRemoteCommandCenter.changePlaybackPositionCommand,
                                                                               handler: \AKNowPlayingSessionController.changePlaybackPositionCommandHandler)
}

public struct AKRatingCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPRatingCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let rating = AKRatingCommand(command: \MPRemoteCommandCenter.ratingCommand,
                                               handler: \AKNowPlayingSessionController.ratingCommandHandler)
}

public struct AKRatingMediaItemsCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPFeedbackCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let like = AKRatingMediaItemsCommand(command: \MPRemoteCommandCenter.likeCommand,
                                                       handler: \AKNowPlayingSessionController.likeCommandHandler)
    public static let dislike = AKRatingMediaItemsCommand(command: \MPRemoteCommandCenter.dislikeCommand,
                                                          handler: \AKNowPlayingSessionController.dislikeCommandHandler)
    public static let bookmark = AKRatingMediaItemsCommand(command: \MPRemoteCommandCenter.bookmarkCommand,
                                                           handler: \AKNowPlayingSessionController.seekBackwardCommandHandler)
}

public struct AKChangeRepeatModeCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPChangeRepeatModeCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let changeRepeatMode = AKChangeRepeatModeCommand(command: \MPRemoteCommandCenter.changeRepeatModeCommand,
                                                                   handler: \AKNowPlayingSessionController.changeRepeatModeCommandHandler)
}

public struct AKChangeShuffleModeCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPChangeShuffleModeCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let changeShuffleMode = AKChangeShuffleModeCommand(command: \MPRemoteCommandCenter.changeShuffleModeCommand,
                                                                     handler: \AKNowPlayingSessionController.changeShuffleModeCommandHandler)
}

public struct AKLanguageOptionCommand: AKRemoteCommandRegistrable {
    
    public typealias Command = MPRemoteCommand
    public let command: KeyPath<MPRemoteCommandCenter, Command>
    public let handler: KeyPath<AKNowPlayingSessionController, AKRemoteCommandHandler>
    
    public static let enableLanguageOption = AKLanguageOptionCommand(command: \MPRemoteCommandCenter.enableLanguageOptionCommand,
                                                                     handler: \AKNowPlayingSessionController.changeShuffleModeCommandHandler)
    public static let disableLanguageOption = AKLanguageOptionCommand(command: \MPRemoteCommandCenter.disableLanguageOptionCommand,
                                                                      handler: \AKNowPlayingSessionController.changeShuffleModeCommandHandler)
}
