//
//  AKMediaManager.swift
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

open class AKMediaManager: NSObject, AKMediaManagerProtocol {
    
    // MARK: - Properties
    
    public unowned let media: AKPlayable
    
    public var asset: AVURLAsset? {
        return playerItemInitService.asset
    }
    
    public var playerItem: AVPlayerItem? {
        return playerItemInitService.playerItem
    }
    
    public var error: AKPlayerError?
    
    public private(set) var state: AKPlayableState = .idle {
        didSet {
            stateSubject.send(state)
            media.delegate?.akMedia(media,
                                    didChangedState: state)
        }
    }
    
    public var statePublisher: AnyPublisher<AKPlayableState, Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    private let stateSubject = PassthroughSubject<AKPlayableState, Never>()
    
    private var playerItemInitService: AKPlayerItemInitServiceProtocol!
    
    private var seekingThroughMediaService: AKSeekingThroughMediaServiceProtocol!
    
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    // MARK: - Init
    
    public init(media: AKPlayable) {
        self.media = media
        playerItemInitService = AKPlayerItemInitService(with: media)
    }
    
    deinit {
        stopPlayerItemReadinessObserver()
        stopPlayerItemAssetKeysObserver()
        print("Deinit called from AKMediaManager 👌🏼")
    }
    
    open func createAsset() {
        assert(state.isIdle
               || state.isFailed,
               "This function can only be called if the media is idle or has encountered an error.")
        self.error = nil
        playerItemInitService.createAsset()
        state = .assetLoaded
    }
    
    open func fetchAssetPropertiesValues() async throws {
        assert(state.isAssetLoaded,
               "This function requires the asset to be loaded first.")
        do {
            try await playerItemInitService.fetchAssetPropertiesValues()
        } catch {
            throw error
        }
    }
    
    open func validateAssetPlayability() async throws {
        assert(state.isAssetLoaded,
               "This function requires the asset to be loaded first.")
        do {
            try await playerItemInitService.validateAssetPlayability()
        } catch {
            throw error
        }
    }
    
    open func createPlayerItemFromAsset() {
        assert(state.isAssetLoaded,
               "This function requires the asset to be loaded first.")
        self.error = nil
        playerItemInitService.createPlayerItemFromAsset()
        seekingThroughMediaService = AKSeekingThroughMediaService(with: playerItemInitService.playerItem!)
        state = .playerItemLoaded
    }
    
    open func abortAssetInitialization() {
        playerItemInitService?.abortAssetInitialization()
    }
    
    open func startPlayerItemReadinessObserver() {
        guard state.isPlayerItemLoaded
                || state.isReadyToPlay else { return }
        
        playerItem!.publisher(for: \.status,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] status in
            switch status {
            case .readyToPlay:
                state = .readyToPlay
            case .failed:
                self.error = .playerItemLoadingFailed(reason: .statusLoadingFailed(error: playerItem!.error!))
                state = .failed
            default: break
            }
        }
        .store(in: &cancellables)
    }
    
    open func stopPlayerItemReadinessObserver() {
        cancellables.removeAll()
    }
    
    open func startPlayerItemAssetKeysObserver() {
        guard state.isPlayerItemLoaded
                || state.isReadyToPlay else { return }
        
        startObservingPlayerItemProperties()
    }
    
    open func stopPlayerItemAssetKeysObserver() {
        cancellables.removeAll()
    }
    
    open func canStep(by count: Int) -> Bool {
        guard state.isPlayerItemLoaded || state.isReadyToPlay else { return false }
        var isForward: Bool { return count.signum() == 1 }
        return isForward ? playerItem!.canStepForward : playerItem!.canStepBackward
    }
    
    open func canPlay(at rate: AKPlaybackRate) -> Bool {
        guard state.isPlayerItemLoaded || state.isReadyToPlay else { return false }
        switch rate.rate {
        case 0.0...:
            switch rate.rate {
            case 2.0...:
                return playerItem!.canPlayFastForward
            case 1.0..<2.0:
                return true
            case 0.0..<1.0:
                return playerItem!.canPlaySlowForward
            default:
                return false
            }
        case ..<0.0:
            switch rate.rate {
            case -1.0:
                return playerItem!.canPlayReverse
            case -1.0..<0.0:
                return playerItem!.canPlaySlowReverse
            case ..<(-1.0):
                return playerItem!.canPlayFastReverse
            default:
                return false
            }
        default:
            return false
        }
    }
    
    open func canSeek(to time: CMTime) -> (flag: Bool,
                                           reason: AKPlayerUnavailableCommandReason?) {
        guard state.isPlayerItemLoaded
                || state.isReadyToPlay else {
            if state.isIdle
                || state.isFailed {
                return (false, .loadMediaFirst)
            } else {
                return (false, .waitTillMediaLoaded)
            }
        }
        return seekingThroughMediaService.canSeek(to: time)
    }
    
    // MARK: - Additional Helper Functions
    
    private func startObservingPlayerItemProperties() {
        playerItem!.publisher(for: \.tracks,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] tracks in
            media.delegate?.akMedia(media,
                                    didChangeTracks: tracks)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.canStepForward,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] canStepForward in
            media.delegate?.akMedia(media,
                                    didChangeCanStepForwardStatus: canStepForward)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.canStepBackward,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] canStepBackward in
            media.delegate?.akMedia(media,
                                    didChangeCanStepBackwardStatus: canStepBackward)
        }
        .store(in: &cancellables)
        
        
        playerItem!.publisher(for: \.presentationSize,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] presentationSize in
            media.delegate?.akMedia(media,
                                    didChangePresentationSize: presentationSize)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.loadedTimeRanges,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] loadedTimeRanges in
            media.delegate?.akMedia(media,
                                    didChangeLoadedTimeRanges: loadedTimeRanges)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.seekableTimeRanges,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] seekableTimeRanges in
            media.delegate?.akMedia(media,
                                    didChangeSeekableTimeRanges: seekableTimeRanges)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.duration,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] duration in
            media.delegate?.akMedia(media,
                                    didChangeItemDuration: duration)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.timebase,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] timebase in
            media.delegate?.akMedia(media,
                                    didChangeTimebase: timebase)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.canPlayReverse,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] canPlayReverse in
            media.delegate?.akMedia(media,
                                    didChangeCanPlayReverseStatus: canPlayReverse)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.canPlayFastForward,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] canPlayFastForward in
            media.delegate?.akMedia(media,
                                    didChangeCanPlayFastForwardStatus: canPlayFastForward)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.canPlayFastReverse,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] canPlayFastReverse in
            media.delegate?.akMedia(media,
                                    didChangeCanPlayFastReverseStatus: canPlayFastReverse)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.canPlaySlowForward,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] canPlaySlowForward in
            media.delegate?.akMedia(media,
                                    didChangeCanPlaySlowForwardStatus: canPlaySlowForward)
        }
        .store(in: &cancellables)
        
        playerItem!.publisher(for: \.canPlaySlowReverse,
                              options: [.initial,
                                        .new])
        .subscribe(on: DispatchQueue.global(qos: .background))
        .receive(on: DispatchQueue.main)
        .sink { [unowned self] canPlaySlowReverse in
            media.delegate?.akMedia(media,
                                    didChangeCanPlaySlowReverseStatus: canPlaySlowReverse)
        }
        .store(in: &cancellables)
    }
}
