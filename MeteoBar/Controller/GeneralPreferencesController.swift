//
//  GeneralPreferencesController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/26/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa
import Preferences

class GeneralPreferencesController: NSViewController, Preferenceable {
    // MARK: - Protocol Variables
    let toolbarItemTitle = "General"
    let toolbarItemIcon = NSImage(named: NSImage.advancedName)!
    
    // MARK: - Outlets

    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "GeneralPreferences"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
}
