//
//  MainMenuController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/13/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import SwiftyUserDefaults
import Preferences
import Repeat
import Cocoa

enum MeteobarError: Error, CustomStringConvertible {
    case observationError
    case bridgeError
    case missingBridge
    case missingMenubarSensor
    
    var description: String {
        switch self {
        case .observationError: return "Error reading observation from Meteobridge"
        case .bridgeError: return "Error reading data from Meteobridg"
        case .missingBridge: return "No Meteobridge found in User Defaults"
        case .missingMenubarSensor: return "No sensor selected for display in menubar"
        }
    }
}

///
/// Main Menu
///
/// ## Special Notes ##
/// [NSSTackView Example](https://stackoverflow.com/questions/44823449/how-to-stretch-all-buttons-inside-horizontal-stack-view-as-device-width#)
///
class MainMenuController: NSViewController {

    // MARK: - Outlets
    @IBOutlet weak var menuMain: NSMenu!
    @IBOutlet weak var iconBarView: IconBarView!
    @IBOutlet weak var compassView: MeteoCompassView!
    @IBOutlet weak var iconBarManuItem: NSMenuItem!
    @IBOutlet weak var compassItem: NSMenuItem!
    
    // MARK: - Local properties
    var statusItems     = [String: NSStatusItem]()
    var observerQueue   = [String: Repeater]()
    
    // MARK: - Views
    /// About View
    lazy var aboutView: NSViewController = {
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
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func awakeFromNib() {
        statusItems["MeteoBar"]         = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItems["MeteoBar"]?.title  = "--"
        statusItems["MeteoBar"]?.menu   = menuMain
        
        iconBarManuItem.view            = iconBarView
        compassItem.view                = compassView
        
        /// Setup a call-forward listener for anyone to ask the Menu to update with a new observation
        NotificationCenter.default.addObserver(self, selector: #selector(getObservation(_:)), name: NSNotification.Name(rawValue: "UpdateObservation"), object: nil)

        /// Setup a call-forward listener for anyone to tell the controller that we have a new bridge
        NotificationCenter.default.addObserver(self, selector: #selector(newBridgeInitialized(_:)), name: NSNotification.Name(rawValue: "BridgeInitialized"), object: nil)
       
//        if theDelegate?.theBridge != nil {
//            addBridgeToQueue(theBridge: theDelegate?.theBridge)
//        }
        newBridgeInitialized(Notification(name: NSNotification.Name(rawValue: "BridgeInitialized")))
    }

    @objc private func newBridgeInitialized(_ theNotification: Notification) {
        guard let bridge = theDelegate?.theBridge else {
            log.warning(MeteobarError.bridgeError)
            return
        }
        
        observerQueue.removeAll()
        
        addBridgeToQueue(theBridge: bridge)
    }
    
    ///
    /// Queue managament ... we want to be able to add stations to the queue at-will
    /// ## Steps ##
    /// - ToDo: Update the meunebar
    /// - Add station to the queue
    /// - Fire off a request for an observtion
    ///
    /// - Parameter theBrodge: The Meteobridge to add to the queue
    ///
    /// - Throws: Nothing
    /// - Returns: Nothing
    ///
    private func addBridgeToQueue(theBridge: Meteobridge?) {
        if theBridge == nil {
            log.warning(MeteobarError.missingBridge)
            return
        }
        
        let queue = Repeater(interval: .seconds(Double(theBridge!.updateInterval)), mode: .infinite) { _ in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateObservation"), object: nil, userInfo: ["Bridge": theBridge!])
        }
        
        observerQueue[theBridge!.uuid] = queue
        queue.start()
        
        DispatchQueue.main.async { // Kick off the first observation while we wait for the timers to count down
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateObservation"), object: nil, userInfo: ["Bridge": theBridge!])
            log.info("Station[\(theBridge!.name)] will poll every \(theBridge!.updateInterval) seconds.")
        }
    }

    ///
    /// We have kicked off a number of timers to get an observation; this is the callback to process the obseravtions across observing stations
    ///
    /// ## Important Notes ##
    ///   The Station has returned with its observation; do something with it
    ///
    /// - parameters:
    ///   - theNotification: the notification that is returned with the data call; in our case, it's the station
    ///
    /// - throws: Nothing
    /// - returns:  Nothing
    ///
    @objc private func getObservation(_ theNotification: Notification) {
        guard let bridge = theNotification.userInfo!["Bridge"] as? Meteobridge else {
            log.error(MeteobarError.bridgeError)
            return
        }
        bridge.getObservation { (_ response: AnyObject?, _ error: Error?) in
            if error == nil {
                guard let bridge: Meteobridge = response as? Meteobridge else {
                    log.warning(MeteobarError.bridgeError)
                    return
                }
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NewObservationReceived"),
                                                object: nil, userInfo: ["Bridge": bridge])  // Broadcast to all listeners - we have a new measurement.  Update as needed.
                guard let sensor = bridge.findSensor(sensorName: (theDelegate?.theDefaults?.menubarSensor)!) else {
                    log.warning(MeteobarError.missingMenubarSensor)
                    return
                }
                self.statusItems["MeteoBar"]?.title = sensor.formattedMeasurement           // Update the menubar
            } else {
                log.warning(error.value)
                return
            }
        }
    }
    
    /// Show the preferences window with the Setup Tab selected
    ///
    /// - Parameter sender: The Caller who sent the message
    @IBAction func showBridgeSetupTab(_ sender: QJHighlightButtonView) {
        sender.superview?.window?.close()
        preferencesView.showWindow(tabIndex: 1)
        DispatchQueue.main.async { [unowned self] in
            self.preferencesView.becomeFirstResponder()
        }
    }
    
    /// Show the preferences window the Configuration Tab selected
    ///
    /// - Parameter sender: The Caller who sent the message
    @IBAction func showBridgeConfiguration(_ sender: QJHighlightButtonView) {
        sender.superview?.window?.close()
        preferencesView.showWindow(tabIndex: 2)
        DispatchQueue.main.async { [unowned self] in
            self.preferencesView.becomeFirstResponder()
        }
    }
    
    /// Show the "About" Window
    ///
    /// - Parameter sender: The Caller who sent the message
    @IBAction func aboutMeteoBar(_ sender: Any) {
        presentAsModalWindow(aboutView)
    }
    
    /// Show the preferences window
    ///
    /// - Parameter sender: The Caller who sent the message
    @IBAction func meteoBarPreferences(_ sender: Any) {
        preferencesView.showWindow()
        guard let myView = sender as? NSView else {
            return
        }
        myView.superview?.window?.close()
    }
    
    /// Show the preferences window
    ///
    /// - Parameter sender: The Caller who sent the message
    @IBAction func showUIConfiguration(_ sender: QJHighlightButtonView) {
        sender.superview?.window?.close()
        preferencesView.showWindow(tabIndex: 3)
        DispatchQueue.main.async { [unowned self] in
            self.preferencesView.window!.makeFirstResponder(nil)
            self.preferencesView.window!.makeKey()
        }
    }

    /// Quit - we're done!
    ///
    /// - Parameter sender: The Caller who sent the message
    @IBAction func quitMeteoBar(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
}
