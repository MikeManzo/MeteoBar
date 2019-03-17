//
//  MeteoPanelController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/16/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Preferences
import Cocoa

class MeteoPanelController: NSViewController {
    @IBOutlet weak var alertView: AlertView!
    @IBOutlet weak var compassView: MeteoCompassView!
    @IBOutlet weak var iconBarView: IconBarView!
    
    var originPoint = NSPoint(x: 0, y: 0)
    
    /// About View
    lazy var aboutView: AboutController = {
        return AboutController(nibName: NSNib.Name("About"), bundle: nil)
    }()
    
    /// Preferences
    lazy var preferencesView: PreferencesWindowController = {
        return PreferencesWindowController(viewControllers: [ GeneralPreferencesController(),
                                                              BridgeSetupController(),
                                                              BridgePreferencesController(),
                                                              UserInterfaceController()
            ])
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear() {
        view.window!.standardWindowButton(.miniaturizeButton)?.isHidden = true
        view.window!.standardWindowButton(.closeButton)?.isHidden       = true
        view.window!.standardWindowButton(.zoomButton)?.isHidden        = true
        view.window!.titlebarAppearsTransparent                         = true
        view.window!.titleVisibility                                    = .hidden
        view.window!.styleMask                                          = .borderless

        view.window!.setFrameOrigin(originPoint)
        if theDelegate?.theBridge != nil {
            alertView.refreshAlerts(alerts: (theDelegate?.theBridge?.weatherAlerts)!)
        }
    }

    /// Show the preferences window with the Setup Tab selected
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func showBridgeSetupTab(_ sender: QJHighlightButtonView) {
        DispatchQueue.main.async { [unowned self] in
            sender.superview?.window?.orderOut(self)
            self.preferencesView.showWindow(tabIndex: 1)
        }
    }
    
    /// Show the preferences Tab
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func showBridgeConfiguration(_ sender: QJHighlightButtonView) {
        DispatchQueue.main.async { [unowned self] in
            sender.superview?.window?.orderOut(self)
            self.preferencesView.showWindow(tabIndex: 2)
        }
    }
    
    /// Show the preferences tab
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func meteoBarPreferences(_ sender: Any) {
        preferencesView.showWindow()
        guard let myView = sender as? NSView else {
            return
        }
        myView.superview?.window?.close()
    }
    
    /// Show the User Interface configuration tab
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func showUIConfiguration(_ sender: QJHighlightButtonView) {
        DispatchQueue.main.async { [unowned self] in
            sender.superview?.window?.orderOut(self)
            self.preferencesView.showWindow(tabIndex: 3)
        }
    }
    
    /// Show the "About" Window
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func aboutMeteoBar(_ sender: Any) {
        (sender as AnyObject).superview?.window?.orderOut(self)
        presentAsModalWindow(aboutView)
    }
    
    /// Quit - we're done!
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func quitMeteoBar(_ sender: Any) {
      NSApplication.shared.terminate(self)
    }
}
