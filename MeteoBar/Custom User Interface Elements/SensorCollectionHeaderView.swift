//
//  SensorCollectionHeaderView.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/27/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

/// Helper for the header in the collectionview of the bridge configuration in preferences
class SensorCollectionHeaderView: NSView {

    @IBOutlet weak var sensorIcon: NSImageView!
    @IBOutlet weak var headerText: NSTextField!

    override func awakeFromNib() {
        wantsLayer = true
        window?.isOpaque = false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor(calibratedWhite: 0.8 , alpha: 0.8).set()
        NSColor.windowBackgroundColor.set()
        dirtyRect.fill(using: NSCompositingOperation.sourceOver)
    }
}
