//
//  AKMediaSelectionService.swift
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

protocol AKMediaSelectionServiceable {
    var availableMediaCharacteristicsWithMediaSelectionOptions: [AVMediaCharacteristic] { get }
    func availableOption(for characteristic: AVMediaCharacteristic) -> [AVMediaSelectionOption]
    func select(mediaSelectionOption: AVMediaSelectionOption?, for characteristic: AVMediaCharacteristic)
    func select(locale: Locale, for characteristic: AVMediaCharacteristic)
}

final public class AKMediaSelectionService: AKMediaSelectionServiceable {

    // MARK: - Properties

    private let playerItem: AVPlayerItem?

    // MARK: - Init

    public init(with playerItem: AVPlayerItem?) {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        self.playerItem = playerItem
    }

    deinit {
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
    }

    // MARK: - Additional Helper Functions

    public func select(mediaSelectionOption: AVMediaSelectionOption?, for characteristic: AVMediaCharacteristic) {
        guard let currentItem = playerItem, let group = currentItem.asset.mediaSelectionGroup(forMediaCharacteristic: characteristic) else { return }
        currentItem.select(mediaSelectionOption, in: group)
    }

    public func select(locale: Locale, for characteristic: AVMediaCharacteristic) {
        guard let currentItem = playerItem else { return }
        if let group = currentItem.asset.mediaSelectionGroup(forMediaCharacteristic: characteristic) {
            if let option = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale).first {
                currentItem.select(option, in: group)
            }
        }
    }

    public var availableMediaCharacteristicsWithMediaSelectionOptions: [AVMediaCharacteristic] {
        guard let currentItem = playerItem else { return [] }
        return currentItem.asset.availableMediaCharacteristicsWithMediaSelectionOptions
    }

    public func availableOption(for characteristic: AVMediaCharacteristic) -> [AVMediaSelectionOption] {
        guard let currentItem = playerItem else { return [] }
        guard let mediaSelectionGroup = currentItem.asset.mediaSelectionGroup(forMediaCharacteristic: characteristic) else { return [] }
        // Retrieve the AVMediaSelectionGroup for the specified characteristic.
        return mediaSelectionGroup.options
    }
}
