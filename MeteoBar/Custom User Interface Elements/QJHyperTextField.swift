//
//  HyperTextField.swift
//  Meteobar
//
//  Created by Mike Manzo on 7/23/17.
//  Copyright © 2017 Straight On 'Till Dawn. All rights reserved.
//

import Cocoa

@IBDesignable
class QJHyperTextField: NSTextField {
    @IBInspectable var href: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let attributes: [NSAttributedString.Key: AnyObject] = [
            NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): NSColor.blue,
            NSAttributedString.Key(rawValue: NSAttributedString.Key.underlineStyle.rawValue): NSUnderlineStyle.single.rawValue as AnyObject
        ]
        
        self.attributedStringValue = NSAttributedString(string: self.stringValue, attributes: attributes)

        let trackingArea = NSTrackingArea(rect: self.bounds,
                                          options: NSTrackingArea.Options(rawValue: NSTrackingArea.Options.RawValue(UInt8(NSTrackingArea.Options.activeInKeyWindow.rawValue)|UInt8(NSTrackingArea.Options.mouseEnteredAndExited.rawValue))), owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        NSWorkspace.shared.open(URL(string: self.href)!)
    }
    
    /// Change the cursor to the pointing hand to denote a "Clickable" URL
    ///
    /// - Parameter event: <#event description#>
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
    }
    
    /// Restore the cursor to the arrow after leaving the context of the control
    ///
    /// - Parameter event: <#event description#>
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }
}
