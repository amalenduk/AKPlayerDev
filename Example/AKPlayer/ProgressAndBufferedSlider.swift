//
//  ProgressAndBufferedSlider.swift
//  AKPlayer_Example
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
import UIKit
import AVKit

@IBDesignable class AKProgressAndTimeRangesSlider: UISlider {
    
    private var thumbHideTimer: Timer?
    
    private var isThumbHidden: Bool = true
    
    var loadedTimeRanges: [CMTimeRange] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var itemDuration: CMTime = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Clear the existing context
        context.clear(rect)
        context.setFillColor(UIColor.clear.cgColor)
        
        // Draw the loaded time ranges
        for range in loadedTimeRanges {
            let startValue = Float(range.start.seconds)
            let durationValue = Float(range.duration.seconds)
            let startX = (startValue / Float(itemDuration.seconds)) * Float(rect.width)
            let width = (durationValue / Float(itemDuration.seconds)) * Float(rect.width)
            
            let centerY = rect.midY
            let height = trackRect(forBounds: rect).height
            
            let rangeRect = CGRect(x: CGFloat(startX), y: centerY - height / 2, width: CGFloat(width), height: height)
            context.setFillColor(UIColor.darkGray.cgColor)
            context.fill(rangeRect)
        }
    }
    
    open func commonInit() {
        applyDesigns()
        resetControls()
        hideThumb()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        commonInit()
    }
    
    open func setupUI() {
        
    }
    
    open func applyDesigns() {
        minimumTrackTintColor = .red
        maximumTrackTintColor = .lightGray
    }
    
    open func resetControls() {
        minimumValue = 0
        maximumValue = 1
        value = 0
    }
    
    private func showThumb() {
        isThumbHidden = false
        thumbTintColor = UIColor.white
    }
    
    private func hideThumb() {
        isThumbHidden = true
        thumbTintColor = UIColor.white.withAlphaComponent(0.0)
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if isThumbHidden {
            thumbHideTimer?.invalidate()
            showThumb()
        }
        return super.beginTracking(touch, with: event)
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        if !isThumbHidden {
            thumbHideTimer?.invalidate()
            thumbHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { [weak self] _ in
                self?.hideThumb()
            })
        }
    }
}
