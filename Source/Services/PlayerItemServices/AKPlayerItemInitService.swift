//
//  AKPlayerItemInitService.swift
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

/*
 https://developer.apple.com/documentation/avfoundation/avasynchronouskeyvalueloading
 https://developer.apple.com/documentation/avfoundation/avasset
 https://developer.apple.com/documentation/avfoundation/avplayeritem
 https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/MediaPlaybackGuide/Contents/Resources/en.lproj/ExploringAVFoundation/ExploringAVFoundation.html
 */

import AVFoundation

public protocol AKPlayerItemInitServiceProtocol {
    var media: AKPlayable { get }
    
    func initialize() async throws -> AVPlayerItem
    func cancelInitialization()
}

open class AKPlayerItemInitService: AKPlayerItemInitServiceProtocol {
    
    // MARK: - Properties
    
    public unowned let media: AKPlayable
    
    private var asset: AVURLAsset?
    
    // MARK: - Init
    
    public init(with media: AKPlayable) {
        self.media = media
    }
    
    deinit {
        print("Deinit called from ", #file)
    }
    
    // MARK: - Additional Helper Functions
    
    open func initialize() async throws -> AVPlayerItem {
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         */
        let asset: AVURLAsset = AVURLAsset(url: media.url,
                                           options: media.assetInitializationOptions)
        self.asset = asset
        
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        try await loadPropertyValues(for: asset)
        
        /* At this point we're ready to set up for playback of the asset. */
        return createPlayerItem(with: asset)
    }
    
    open func cancelInitialization() {
        guard let asset = asset else { return }
        asset.cancelLoading()
    }
    
    private func loadPropertyValues(for asset: AVURLAsset) async throws {
        /*
         You can initialize an instance of the player item with the asset
         if the `playable` property value equals `true`.
         
         If the `hasProtectedContent` property value equals `true`, the
         asset contains protected content and can't be played.
         */
        /* Use the AVAsset playable property to detect whether the asset can be played. */
        do {
            let (isPlayable, hasProtectedContent) = try await asset.load(.isPlayable, .hasProtectedContent)
            try checkAssetPlayability(isPlayable: isPlayable,
                                      hasProtectedContent: hasProtectedContent)
        } catch (let error) {
            if let err = error as? URLError,
               err.code  == URLError.Code.notConnectedToInternet {
                throw AKPlayerError.assetLoadingFailed(reason: .notConnectedToInternet(error: err))
            } else {
                throw AKPlayerError.assetLoadingFailed(reason: .propertyKeyLoadingFailed(error: error))
            }
        }
    }
    
    private func checkAssetPlayability(isPlayable: Bool,
                                       hasProtectedContent: Bool) throws {
        guard isPlayable else { throw AKPlayerError.assetLoadingFailed(reason: .notPlayable) }
        guard !hasProtectedContent else { throw AKPlayerError.assetLoadingFailed(reason: .protectedContent) }
    }
    
    private func createPlayerItem(with asset: AVURLAsset) -> AVPlayerItem {
        // Create a new AVPlayerItem with the asset and an
        // array of asset keys to be automatically loaded
        let playerItem: AVPlayerItem
        if let automaticallyLoadedAssetKeys = media.automaticallyLoadedAssetKeys {
            playerItem = AVPlayerItem(asset: asset,
                                      automaticallyLoadedAssetKeys: automaticallyLoadedAssetKeys)
        } else {
            playerItem = AVPlayerItem(asset: asset)
        }
        return playerItem
    }
}
