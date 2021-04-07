//
//  AKScreenBrightnessObservingService.swift
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

final public class AKScreenBrightnessObservingService {

    // MARK: - Properties

    public var onbBrightnessChange: ((_ brightness: CGFloat) -> Void)?

    // MARK: - Init

    init() {
        AKPlayerLogger.shared.log(message: "Init", domain: .lifecycleService)
        /* A notification that’s posted when brightness change. */
        NotificationCenter.default.addObserver(self, selector: #selector(brightnessDidChange(_ :)), name: UIScreen.brightnessDidChangeNotification, object: nil)
    }

    deinit {
        AKPlayerLogger.shared.log(message: "DeInit", domain: .lifecycleService)
        NotificationCenter.default.removeObserver(self, name: UIScreen.brightnessDidChangeNotification, object: nil)
    }

    /* A notification that’s posted when an audio interruption occurs. */
    @objc private func brightnessDidChange(_ notification: Notification) {
        onbBrightnessChange?(UIScreen.main.brightness)
    }
}
