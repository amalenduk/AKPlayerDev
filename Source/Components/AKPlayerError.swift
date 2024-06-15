//
//  AKPlayerError.swift
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

public enum AKPlayerError: Error, Equatable {
    case noItemToPlay
    case itemFailedToPlayToEndTime
    case playerCanNoLongerPlay(error: Error?)
    
    case assetLoadingFailed(reason: AssetLoadingFailureReason)
    case playerItemLoadingFailed(reason: PlayerItemLoadingFailureReason)
    case playerItemFailedToPlay(reason: PlayerItemFailedToPlayReason)
    
    case audioSessionFailure(reason: AudioSessionFailureReason)
    case nowPlayingSessionFailure
    
    public enum AudioSessionFailureReason {
        case failedToActivate(error: Error) // Error occurred while activating audio session.
        case failedToDeactivate(error: Error) // Error occurred while deactivating audio session.
        case failedToSetCategory(error: Error) // Error occurred while setting category for audio session.
    }
    
    public enum AssetLoadingFailureReason {
        case notPlayable
        case protectedContent
        case propertyKeyLoadingFailed(error: Error)
        case notConnectedToInternet(error: Error)
        case assetInitializationFailed(error: Error)
    }
    
    public enum PlayerItemLoadingFailureReason {
        case statusLoadingFailed(error: Error)
        case invalidAsset
    }
    
    public enum PlayerItemFailedToPlayReason {
        case failedToPlayToEndTime(error: Error)
    }
}

public func == (lhs: AKPlayerError, rhs: AKPlayerError) -> Bool {
    switch (lhs, rhs) {
    case (.noItemToPlay, .noItemToPlay),
        (.playerCanNoLongerPlay, .playerCanNoLongerPlay),
        (.assetLoadingFailed, .assetLoadingFailed),
        (.playerItemLoadingFailed, .playerItemLoadingFailed),
        (.playerItemFailedToPlay, .playerItemFailedToPlay),
        (.audioSessionFailure, .audioSessionFailure),
        (.nowPlayingSessionFailure, .nowPlayingSessionFailure):
        return true
    default:
        return false
    }
}

extension AKPlayerError.AudioSessionFailureReason: LocalizedError {
    
    public var localizedDescription: String {
        switch self {
        case .failedToActivate(error: let error):
            return NSLocalizedString("Failed to activate audio session with error: \(error.localizedDescription)",
                                     comment: "Error description for failedToActivate")
        case .failedToDeactivate(error: let error):
            return NSLocalizedString("Failed to deactivate audio session with error: \(error.localizedDescription)",
                                     comment: "Error description for failedToDeactivate")
        case .failedToSetCategory(error: let error):
            return NSLocalizedString("Failed to set category for audio session with error: \(error.localizedDescription)",
                                     comment: "Error description for failedToSetCategory")
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .failedToActivate, .failedToDeactivate, .failedToSetCategory:
            return localizedDescription
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .failedToActivate, .failedToDeactivate, .failedToSetCategory:
            return localizedDescription
        }
    }
}

extension AKPlayerError.PlayerItemLoadingFailureReason: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .statusLoadingFailed(error: let error):
            return NSLocalizedString("The AVPlayerItem status has failed with error: \(error.localizedDescription)",
                                     comment: "This error occurs when the status of the AVPlayerItem is .failed, indicating that there was an issue with the player item that prevented it from playing successfully.")
        case .invalidAsset:
            return "Not a valid asset"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .statusLoadingFailed:
            return localizedDescription
        case .invalidAsset:
            return localizedDescription
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .statusLoadingFailed:
            return localizedDescription
        case .invalidAsset:
            return localizedDescription
        }
    }
}

extension AKPlayerError.PlayerItemFailedToPlayReason: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .failedToPlayToEndTime(let error):
            return "AVPlayerItem failed to play to end time with error: \(error.localizedDescription)"
        }
    }
}

extension AKPlayerError.AssetLoadingFailureReason: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .notPlayable:
            return NSLocalizedString("Asset is not playable",
                                     comment: "The asset cannot be played because it is either not a supported format or it is corrupted.")
        case .protectedContent:
            return NSLocalizedString("Asset has protected content",
                                     comment: "The asset cannot be played because it is protected by digital rights management (DRM) technology.")
        case .propertyKeyLoadingFailed(error: let error):
            return "The asset property key failed to load with error: \(error.localizedDescription)"
        case .notConnectedToInternet(error: let error):
            return "The asset loading failed to load with error: \(error.localizedDescription)"
        case .assetInitializationFailed(error: let error):
            return "The asset initialization failed to load with error: \(error.localizedDescription)"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .notPlayable:
            return localizedDescription
        case .protectedContent:
            return localizedDescription
        case .propertyKeyLoadingFailed:
            return localizedDescription
        case .notConnectedToInternet:
            return localizedDescription
        case .assetInitializationFailed:
            return localizedDescription
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .notPlayable:
            return localizedDescription
        case .protectedContent:
            return localizedDescription
        case .propertyKeyLoadingFailed:
            return localizedDescription
        case .notConnectedToInternet:
            return localizedDescription
        case .assetInitializationFailed:
            return localizedDescription
        }
    }
}

extension AKPlayerError: LocalizedError {
    
    public var localizedDescription: String {
        switch self {
        case .noItemToPlay:
            return NSLocalizedString("The player item got nil",
                                     comment: "The player item got nil, reason may be the player's current item extermally fored to nil")
        case .itemFailedToPlayToEndTime:
            return NSLocalizedString("This player is unable to play the item till end possible reason can be no netwrok",
                                     comment: "This player is unable to play the item till end possible reason can be no netwrok")
        case .playerCanNoLongerPlay(error: let error):
            return NSLocalizedString("Player can no longer play media due to an error error:\n \(error?.localizedDescription ?? "No reason avialable")",
                                     comment: "Player can no longer play media")
        case .assetLoadingFailed(reason: let reason):
            return reason.localizedDescription
        case .playerItemLoadingFailed(reason: let reason):
            return reason.localizedDescription
        case .playerItemFailedToPlay(reason: let reason):
            return reason.localizedDescription
        case .audioSessionFailure(reason: let reason):
            return reason.localizedDescription
        case .nowPlayingSessionFailure:
            return NSLocalizedString("Failed to active now playing session",
                                     comment: "Failed to active now playing session")
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .noItemToPlay:
            return NSLocalizedString("The player item got nil",
                                     comment: "The player item got nil, reason may be the player's current item extermally fored to nil")
        case .itemFailedToPlayToEndTime:
            return NSLocalizedString("This player is unable to play the item till end possible reason can be no netwrok",
                                     comment: "This player is unable to play the item till end possible reason can be no netwrok")
        case .playerCanNoLongerPlay(error: let error):
            return NSLocalizedString("Player can no longer play media due to an error error:\n \(error?.localizedDescription ?? "No reason avialable")",
                                     comment: "Player can no longer play media")
        case .assetLoadingFailed(reason: let reason):
            return reason.localizedDescription
        case .playerItemLoadingFailed(reason: let reason):
            return reason.localizedDescription
        case .playerItemFailedToPlay(reason: let reason):
            return reason.localizedDescription
        case .audioSessionFailure(reason: let reason):
            return reason.localizedDescription
        case .nowPlayingSessionFailure:
            return NSLocalizedString("Failed to active now playing session",
                                     comment: "Failed to active now playing session")
        }
    }
}

// MARK: - Underlying Error

public extension AKPlayerError.AudioSessionFailureReason {
    var underlyingError: Error? {
        switch self {
        case .failedToActivate(error: let error):
            return error
        case .failedToDeactivate(error: let error):
            return error
        case .failedToSetCategory(error: let error):
            return error
        }
    }
}

public extension AKPlayerError.AssetLoadingFailureReason {
    var underlyingError: Error? {
        switch self {
        case .propertyKeyLoadingFailed(error: let error):
            return error
        case .notConnectedToInternet(error: let error):
            return error
        case .assetInitializationFailed(error: let error):
            return error
        default: return nil
        }
    }
}

public extension AKPlayerError.PlayerItemLoadingFailureReason {
    var underlyingError: Error? {
        switch self {
        case .statusLoadingFailed(error: let error):
            return error
        default: return nil
        }
    }
}

public extension AKPlayerError.PlayerItemFailedToPlayReason {
    var underlyingError: Error? {
        switch self {
        case .failedToPlayToEndTime(error: let error):
            return error
        }
    }
}

public extension AKPlayerError {
    var underlyingError: Error? {
        switch self {
        case .playerCanNoLongerPlay(error: let error):
            return error
        case .assetLoadingFailed(reason: let reason):
            return reason.underlyingError
        case .playerItemLoadingFailed(reason: let reason):
            return reason.underlyingError
        case .playerItemFailedToPlay(reason: let reason):
            return reason.underlyingError
        case .audioSessionFailure(reason: let reason):
            return reason.underlyingError
        default: return nil
        }
    }
}
