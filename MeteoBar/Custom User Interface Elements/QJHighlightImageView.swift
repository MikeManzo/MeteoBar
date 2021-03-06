//
//  QJHighlightImageView.swift
//  MeteoBar
//
//  Created by Mike Manzo on 2/13/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

///
/// [Custom Highlight](https://stackoverflow.com/questions/43265671/osx-nsmenuitem-with-custom-nsview-does-not-highlight-swift#)
///
class QJHighlightImageView: NSImageView {
//    var trackingArea: NSTrackingArea?
    
    override var isHighlighted: Bool {
        didSet {
            if oldValue != isHighlighted {
                needsDisplay = true
            }
        }
    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        super.mouseEntered(with: theEvent)
        isHighlighted = true
    }
    override func mouseExited(with theEvent: NSEvent) {
        super.mouseExited(with: theEvent)
        isHighlighted = false
    }
    
    override func awakeFromNib() {
/*        trackingArea = NSTrackingArea(rect: NSRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height),
                                      options: [NSTrackingArea.Options.activeAlways ,NSTrackingArea.Options.mouseEnteredAndExited],
                                      owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
        self.wantsLayer = true
 */
        addTrackingArea(NSTrackingArea(rect: NSRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height),
                                      options: [NSTrackingArea.Options.activeAlways ,NSTrackingArea.Options.mouseEnteredAndExited],
                                      owner: self, userInfo: nil))
//        wantsLayer = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if isHighlighted {
            NSColor.selectedMenuItemColor.withAlphaComponent(0.5).set()
        } else {
            NSColor.clear.withAlphaComponent(0.0).set()
        }
        
        NSBezierPath.fill(dirtyRect)
    }
}
