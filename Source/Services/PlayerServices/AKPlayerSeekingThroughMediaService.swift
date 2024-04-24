//
//  AKPlayerSeekingThroughMediaService.swift
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

import AVKit

public protocol AKPlayerSeekingThroughMediaServiceProtocol: AnyObject {
    var player: AVPlayer { get }
    var pendingSeeks: OrderedSet<AKSeek> { get }
    var seekPosition: AKSeekPosition? { get }
    var isSeeking: Bool { get }
    
    func seek(to time: CMTime)
    func seek(to time: CMTime,
              completionHandler: @escaping (Bool) -> Void)
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime)
    func seek(to time: CMTime,
              toleranceBefore: CMTime,
              toleranceAfter: CMTime,
              completionHandler: @escaping (Bool) -> Void)
    func seek(to date: Date)
    func seek(to date: Date,
              completionHandler: @escaping (Bool) -> Void)
}

open class AKPlayerSeekingThroughMediaService: AKPlayerSeekingThroughMediaServiceProtocol {
    
    // MARK: - Properties
    
    public let player: AVPlayer
    
    public private(set) var pendingSeeks = OrderedSet<AKSeek>()
    
    open var seekPosition: AKSeekPosition? { pendingSeeks.last?.position }
    
    open var isSeeking: Bool { !(seekPosition == nil) }
    
    // MARK: - Init
    
    public init(with player: AVPlayer) {
        self.player = player
    }
    
    deinit { }
    
    open func seek(to time: CMTime) {
        seek(to: .time(time),
             completionHandler: nil)
    }
    
    open func seek(to time: CMTime,
                   completionHandler: @escaping (Bool) -> Void) {
        seek(to: .time(time),
             completionHandler: completionHandler)
    }
    
    open func seek(to time: CMTime,
                   toleranceBefore: CMTime,
                   toleranceAfter: CMTime) {
        seek(to: .time(time),
             toleranceBefore: toleranceBefore,
             toleranceAfter: toleranceAfter)
    }
    
    open func seek(to time: CMTime,
                   toleranceBefore: CMTime,
                   toleranceAfter: CMTime,
                   completionHandler: @escaping (Bool) -> Void) {
        seek(to: .time(time),
             toleranceBefore: toleranceBefore,
             toleranceAfter: toleranceAfter,
             completionHandler: completionHandler)
    }
    
    open func seek(to date: Date) {
        seek(to: .date(date))
    }
    
    open func seek(to date: Date,
                   completionHandler: @escaping (Bool) -> Void) {
        seek(to: .date(date),
             completionHandler: completionHandler)
    }
    
    private func seek(to position: AKSeekPosition,
                      toleranceBefore: CMTime = .positiveInfinity,
                      toleranceAfter: CMTime = .positiveInfinity,
                      completionHandler: ((Bool) -> Void)? = nil) {
        guard player.currentItem != nil else {
            completionHandler?(false)
            return
        }
        
        let seek = AKSeek(position: position,
                          toleranceBefore: toleranceBefore,
                          toleranceAfter: toleranceAfter,
                          completionHandler: completionHandler)
        
        pendingSeeks.insert(seek)
        
        guard pendingSeeks.count == 1 else {
            return
        }
        
        enqueue(seek: seek)
    }
    
    private func enqueue(seek: AKSeek) {
        switch seek.position {
        case .time(let cmTime):
            player.seek(to: cmTime,
                        toleranceBefore: seek.toleranceBefore,
                        toleranceAfter: seek.toleranceAfter) { [weak self] finished in
                guard let self = self else { return }
                process(seek: seek, finished: finished)
            }
        case .date(let date):
            player.seek(to: date) { [weak self] finished in
                guard let self = self else { return }
                process(seek: seek, finished: finished)
            }
        }
    }
    
    private func process(seek: AKSeek, finished: Bool) {
        if let targetSeek = pendingSeeks.last,
           !(seek == targetSeek) {
            while let pendingSeek = pendingSeeks.first,
                  !(pendingSeek == targetSeek) {
                pendingSeeks.removeFirst()
                pendingSeek.completionHandler?(true)
            }
            if finished  {
                enqueue(seek: targetSeek)
            }
        } else if finished {
            seek.completionHandler?(finished)
            pendingSeeks.removeAll()
        } else {
            pendingSeeks.remove(seek)
            seek.completionHandler?(false)
            if let targetSeek = pendingSeeks.last {
                enqueue(seek: seek)
            }
        }
    }
}
