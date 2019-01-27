//
//  BridgePreferencesController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/26/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa
import Preferences
import SceneKit

class BridgePreferencesController: NSViewController, Preferenceable {
    // MARK: - Protocol Varioables
    let toolbarItemTitle = "Bridge"
    let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!
    
    // MARK: - Outlets
    @IBOutlet weak var compassView: MeteoCompassView!
    @IBOutlet weak var collectionView: NSScrollView!
    
    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "BridgePreferences"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
       
        compassView.windDirection(direction: 90.0)
    }
    
    /// Cleanup and save data to user preferences
    override func viewDidDisappear() {
        compassView.updatePreferences()
    }
}
