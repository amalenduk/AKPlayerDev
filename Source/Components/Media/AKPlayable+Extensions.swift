//
//  AKPlayable+Extensions.swift
//  AKPlayer
//
//  Created by Amalendu Kar on 27/10/21.
//

import AVFoundation

private var AssociatedObjectHandle: UInt8 = 0

extension AKPlayable {
    
    // Don't set this property from anywhere else, except from AKPlayerItemInitService
    internal var playerItem: AVPlayerItem? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandle) as? AVPlayerItem
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
