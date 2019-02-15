//
//  QuickResponseTableView.swift
//  Meteobar
//
//  Created by Mike Manzo on 7/23/17.
//  Copyright © 2017 Straight On 'Till Dawn. All rights reserved.
//

import Cocoa

@IBDesignable
class QJQuickResponseTableView: NSTableView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    /// A simple subclass of an NSTableView to allow the keydown message to be sent to subviews contained in the row(s) of the table.
    ///
    /// - Parameters:
    ///   - responder: <#responder description#>
    ///   - event: <#event description#>
    /// - Returns: <#return value description#>
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return true
    }
}
