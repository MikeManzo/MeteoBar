//
//  MainMenuController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/13/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

class MainMenuController: NSViewController {

    /// Outlets
    @IBOutlet weak var menuMain: NSMenu!
    
    /// Local Variables
    var statusItems     = [String: NSStatusItem]()
    
    /// Local Views
    lazy var aboutWindow: NSViewController = {
        return AboutController(nibName: NSNib.Name("About"), bundle: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func awakeFromNib() {
        statusItems["MeteoBar"]         = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItems["MeteoBar"]?.title  = "--"
        statusItems["MeteoBar"]?.menu   = menuMain
    }
    
    /// Show the "About" Window
    ///
    /// - Parameter sender: The Caller who sent the message
    @IBAction func aboutMeteoBar(_ sender: Any) {
        presentAsModalWindow(aboutWindow)
    }
    
    /// Show the preferences window
    ///
    /// - Parameter sender: The Caller who sent the message
    @IBAction func meteoBarPreferences(_ sender: Any) {
    }
    
    /// Quit - we're done!
    ///
    /// - Parameter sender: The Caller who sent the message
    @IBAction func quitMeteoBar(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
}
