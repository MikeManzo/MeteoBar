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
    
    var origAlertOrigin: NSPoint?
    var origCompassOrigin: NSPoint?
    var origIconBarOrigin: NSPoint?
    
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
        self.view.window?.delegate = self
        
        origCompassOrigin   = compassView.frame.origin
        origIconBarOrigin   = iconBarView.frame.origin
        origAlertOrigin     = alertView.frame.origin
    }
    
    override func viewWillAppear() {
        view.window!.standardWindowButton(.miniaturizeButton)?.isHidden = true
        view.window!.standardWindowButton(.closeButton)?.isHidden       = true
        view.window!.standardWindowButton(.zoomButton)?.isHidden        = true
        view.window!.titlebarAppearsTransparent                         = true
        view.window!.titleVisibility                                    = .hidden
        view.window!.styleMask                                          = .borderless

        view.window!.setFrameOrigin(originPoint)
        
        guard let theBridge = theDelegate?.theBridge else {
            return
        }
        
        if theBridge.weatherAlerts.isEmpty {                    // No alerts ... move views up
            setSize(newSize: NSSize(width: 400, height: 442))   // Size of window w/o he AlertView (which is 96 pixels)
            var compassOrigin   = compassView.frame.origin
            var iconBarOrigin   = iconBarView.frame.origin
            
            compassOrigin.y += 96
            compassView.animator().setFrameOrigin(compassOrigin)

            iconBarOrigin.y += 96
            iconBarView.animator().setFrameOrigin(iconBarOrigin)

        } else {                                                // Alerts ... move views to defult
            setSize(newSize: NSSize(width: 400, height: 538))   // Size of window w/o he AlertView (which is 96 pixels)
            
            compassView.animator().setFrameOrigin(origCompassOrigin!)
            iconBarView.animator().setFrameOrigin(origIconBarOrigin!)
            alertView.animator().setFrameOrigin(origAlertOrigin!)
        }
        alertView.refreshAlerts(alerts: theBridge.weatherAlerts)
    }
    
    private final func setSize(newSize: NSSize) {
        if let myWindow = self.view.window {
            var frame = myWindow.frame
            frame.size = newSize
            myWindow.setFrame(frame, display: true, animate: true)
        }
    }
    
    /// Override the dismissal so we can stop the mouse event looking for left/right mouse clicks
    /// Send a message back to the listener that we've closed ...
    ///
    override func viewDidDisappear() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "WeatherPanelClosed"), object: nil, userInfo: ["Controller": self])
    }

    /// Show the "About" Window
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func aboutMeteoBar(_ sender: Any) {
        (sender as AnyObject).superview?.window?.orderOut(self)
        presentAsModalWindow(aboutView)
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

    /// Show the preferences window with the Setup Tab selected
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func showBridgeSetupTab(_ sender: QJHighlightButtonView) {
        DispatchQueue.main.async { [unowned self] in
            self.preferencesView.showWindow()
            self.preferencesView.selectTab(tabIndex: 1)
            sender.superview?.window?.close()
        }
    }
    
    /// Show the preferences Tab
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func showBridgeConfiguration(_ sender: QJHighlightButtonView) {
        DispatchQueue.main.async { [unowned self] in
            self.preferencesView.showWindow()
            self.preferencesView.selectTab(tabIndex: 2)
            sender.superview?.window?.close()
        }
    }

    /// Show the User Interface configuration tab
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func showUIConfiguration(_ sender: QJHighlightButtonView) {
        DispatchQueue.main.async { [unowned self] in
            self.preferencesView.showWindow()
            self.preferencesView.selectTab(tabIndex: 3)
            sender.superview?.window?.close()
        }
    }
    
    /// Quit - we're done!
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func quitMeteoBar(_ sender: Any) {
      NSApplication.shared.terminate(self)
    }
}

extension MeteoPanelController: NSWindowDelegate {
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        if !(theDelegate?.theBridge?.weatherAlerts.isEmpty)! {
            print("We have Alerts Alerts")
            return NSSize(width: 400, height: 538)
        } else {
            print("We don't have Alerts Alerts")
            return NSSize(width: 400, height: 442)
        }
    }
}
