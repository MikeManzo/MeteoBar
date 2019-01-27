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
    
    var description: String {
        switch self {
        case .observationError: return "Error reading observation from Meteobridge"
        case .bridgeError: return "Error reading data from Meteobridg"
        case .missingBridge: return "No Meteobridge found in User Defaults"
        }
    }
}

class MainMenuController: NSViewController {

    // MARK: - Outlets
    @IBOutlet weak var menuMain: NSMenu!
    
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
        return PreferencesWindowController(viewControllers: [ BridgePreferencesController(),
                                                              GeneralPreferencesController()
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
        
        /// Setup a call-forward listener for anyone to ask the Menu to update with a new observation
        NotificationCenter.default.addObserver(self, selector: #selector(getObservation(_:)), name: NSNotification.Name(rawValue: "UpdateObservation"), object: nil)
        
//        addBridgeToQueue(theBridge: Defaults[.defaultBridges])
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
            log.info("Station[\(theBridge!.name)] will update its data every \(theBridge!.updateInterval) seconds.")
        }
    }

    ///
    /// We have kicked off a number of timers to get an observation; this is the callback to process the obseravtions across observing stations
    ///
    /// ## Important Notes ##
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
        bridge.getObservation(observationReturned)
    }

    ///
    /// The Station has returned with its observation; do somethign with it
    ///
    /// ## Important Notes ##
    ///
    /// - parameters:
    ///   - response: the object that is returned with the data call; in our case, it's the station
    /// - throws: Nothing
    /// - returns:  Nothing
    ///
    func observationReturned(_ response: AnyObject?, _ error: Error?) {
        if error == nil {
            guard let bridge: Meteobridge = response as? Meteobridge else {
                log.warning(MeteobarError.bridgeError)
                return
            }
            
            log.info("Observations updated for \(bridge.name)")
            
        } else {
            log.error(error.value)
            return
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
    }
    
    /// Quit - we're done!
    ///
    /// - Parameter sender: The Caller who sent the message
    @IBAction func quitMeteoBar(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
}
