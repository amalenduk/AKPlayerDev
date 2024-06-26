//
//  AKMediaManagerProtocol.swift
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

public protocol AKMediaManagerProtocol: AnyObject {
    var media: AKPlayable { get }
    var asset: AVURLAsset? { get }
    var playerItem: AVPlayerItem? { get }
    var error: AKPlayerError? { get }
    var state: AKPlayableState { get }
    var statePublisher: AnyPublisher<AKPlayableState, Never> { get }
    
    func createAsset() -> AVURLAsset
    func createPlayerItemFromAsset() -> AVPlayerItem
    func fetchAssetPropertiesValues() async throws
    func validateAssetPlayability() async throws
    func abortAssetInitialization()
    
    func startPlayerItemAssetKeysObserver()
    func startPlayerItemReadinessObserver()
    func stopPlayerItemAssetKeysObserver()
    func stopPlayerItemReadinessObserver()
    
    func canStep(by count: Int) -> Bool
    func canPlay(at rate: AKPlaybackRate) -> Bool
    func canSeek(to time: CMTime) -> (flag: Bool,
                                      reason: AKPlayerUnavailableCommandReason?)
}

