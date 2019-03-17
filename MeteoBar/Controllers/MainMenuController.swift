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
    case weatherAlertWarning
    
    var description: String {
        switch self {
        case .observationError: return "Error reading observation from Meteobridge"
        case .bridgeError: return "Error reading data from Meteobridg"
        case .missingBridge: return "No Meteobridge found in User Defaults"
        case .missingMenubarSensor: return "No sensor selected for display in menubar"
        case .weatherAlertWarning: return "Unable to find the weather alert"
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
    @IBOutlet weak var alertView: AlertView!
    @IBOutlet weak var iconBarView: IconBarView!
    @IBOutlet weak var compassView: MeteoCompassView!
    @IBOutlet weak var iconBarManuItem: NSMenuItem!
    @IBOutlet weak var compassItem: NSMenuItem!
    @IBOutlet weak var alertItem: NSMenuItem!
    
    // MARK: - Local properties
    var statusItems     = [String: NSStatusItem]()
    var observerQueue   = [String: Repeater]()
    var alertQueue      = [String: Repeater]()
    var eventMonitor: MeteoEventMonitor?

    // MARK: - Views
    /// About View
    lazy var aboutView: AboutController = {
        return AboutController(nibName: NSNib.Name("About"), bundle: nil)
    }()

    // MARK: - Views
    /// About View
    lazy var meteoPanelView: MeteoPanelController = {
        return MeteoPanelController(nibName: NSNib.Name("MeteoPanel"), bundle: nil)
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
    override func awakeFromNib() {
        statusItems["MeteoBar"]         = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItems["MeteoBar"]?.title  = "--"
//        statusItems["MeteoBar"]?.menu   = menuMain

        statusItems["MeteoBar"]?.button!.target = self
        statusItems["MeteoBar"]?.button!.target = self
        statusItems["MeteoBar"]?.button!.action = #selector(showWeatherPanel(sender:))

        iconBarManuItem.view            = iconBarView
        compassItem.view                = compassView
        alertItem.view                  = alertView

        /// Register as a delegate for the notification center
        NSUserNotificationCenter.default.delegate = self

        /// Setup a call-forward listener for anyone to tell the controller to retrive alerts
        NotificationCenter.default.addObserver(self, selector: #selector(weatherPanelClosed(sender:)), name: NSNotification.Name(rawValue: "WeatherPanelClosed"), object: nil)

        /// Setup a call-forward listener for anyone to tell the controller that we have a new bridge
        NotificationCenter.default.addObserver(self, selector: #selector(newBridgeInitialized(_:)), name: NSNotification.Name(rawValue: "BridgeInitialized"), object: nil)

        /// Setup a call-forward listener for anyone to ask the Menu to update with a new observation
        NotificationCenter.default.addObserver(self, selector: #selector(getObservation(_:)), name: NSNotification.Name(rawValue: "UpdateObservation"), object: nil)

        /// Setup a call-forward listener for anyone to tell the controller to retrive alerts
        NotificationCenter.default.addObserver(self, selector: #selector(getAlerts(_:)), name: NSNotification.Name(rawValue: "RetrieveAlerts"), object: nil)
        
        newBridgeInitialized(Notification(name: NSNotification.Name(rawValue: "BridgeInitialized")))
        
        /// Setup mouse event monitoring for so we can close our window
        eventMonitor = MeteoEventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] _ in
            if self.meteoPanelView.isViewLoaded && (self.meteoPanelView.view.window != nil) {
                self.meteoPanelView.view.window?.close()
            }
        }
        eventMonitor?.start()
    }

    /// EXPIRIMENTAL
    ///
    /// ## SPECIAL NOTE ##
    /// uncomment the following line to return to using this class
    /// statusItems["MeteoBar"]?.menu   = menuMain
    ///
    /// - Parameter sender: <#sender description#>
    ///
    @objc func showWeatherPanel(sender: AnyObject) {
        if meteoPanelView.isViewLoaded && (meteoPanelView.view.window != nil) {
            meteoPanelView.view.window?.close()
            eventMonitor?.stop()
            print("Stopped")
            return
        } else {
            let frameOrigin = statusItems["MeteoBar"]?.button?.window?.frame.origin
            meteoPanelView.originPoint = CGPoint(x: (frameOrigin?.x)!, y: (frameOrigin?.y)! - 22)
            presentAsModalWindow(meteoPanelView)
            eventMonitor?.start()
            print("Started")
        }
    }

    @objc func weatherPanelClosed(sender: AnyObject) {
        eventMonitor?.stop()
        print("Stopped")
    }
    
    /// We have creasted and configured a new meteobridge ... start the machine
    ///
    /// - Parameter theNotification: the notifcation letting us knoe
    ///
    @objc private func newBridgeInitialized(_ theNotification: Notification) {
        guard let bridge = theDelegate?.theBridge else {
            log.warning(MeteobarError.bridgeError)
            return
        }
        
        observerQueue.removeAll()
        
        addBridgeToQueue(theBridge: bridge)
        addBridgeToAlertQueue(theBridge: bridge)
    }
    
    ///
    /// Queue managament ... we want to be able to add stations to the queue at-will
    ///
    /// ## Steps ##
    /// - Add bridge to the queue
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
            log.info("Meteobridge[\(theBridge!.name)] will poll every \(theBridge!.updateInterval) seconds.")
        }
    }

    ///
    /// Manage the Alert Queue
    ///
    /// ## Steps ##
    /// - Add bridge to the queue
    /// - Fire off a request for an alert
    ///
    /// - Parameter station: The station to update in the queue
    /// - throws:       Nothing
    /// - returns:      Nothing
    ///
    private func addBridgeToAlertQueue(theBridge: Meteobridge?) {
        if theBridge == nil {
            log.warning(MeteobarError.missingBridge)
            return
        }
        
        let queue = Repeater(interval: .seconds(Double(theBridge!.alertUpdateInterval)), mode: .infinite) { _ in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RetrieveAlerts"), object: nil, userInfo: ["Bridge": theBridge!])
        }
            
        alertQueue[theBridge!.uuid] = queue
        queue.start()
            
        DispatchQueue.main.async { // Kick off the first alert while we wait for the timers to count down
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RetrieveAlerts"), object: nil, userInfo: ["Bridge": theBridge!])
            log.info("Meteobridge[\(theBridge!.name)] will poll for alerts every \(theBridge!.alertUpdateInterval) seconds.")
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
                DispatchQueue.main.async { [unowned self] in
                    self.statusItems["MeteoBar"]?.title = sensor.formattedMeasurement
                }
            } else {
                log.warning(error.value)
                return
            }
        }
    }

    ///
    /// We have kicked off a number of timers to get an observation; this is the callback to process the forecasts
    ///
    /// ## Important Notes ##
    ///
    /// - parameters:
    ///   - theNotification: the notification that is returned with the data call; in our case, it's the station
    ///
    /// - throws: Nothing
    /// - returns:  Nothing
    ///
    @objc private func getAlerts(_ theNotification: Notification) {
        guard let theBridge = theNotification.userInfo!["Bridge"] as? Meteobridge else {
            log.error(MeteobarError.bridgeError)
            return
        }
        
        theBridge.getWeatherAlerts { [unowned self] (_ response: Meteobridge?, _ error: Error?) in
            if error != nil {
                log.warning(error.value)
            }
            guard let sensor = theBridge.findSensor(sensorName: (theDelegate?.theDefaults?.menubarSensor)!) else {
                log.warning(MeteobarError.missingMenubarSensor)
                return
            }

            for alert in theBridge.weatherAlerts {
                if !alert.isAcknoledged() {
                    switch alert.severity {
                    case .extreme, .severe:
                        DispatchQueue.main.async { [unowned self] in
                            self.statusItems["MeteoBar"]?.button?.image = NSImage(named: "warning-red.png")?.resized(to: NSSize(width: 16.0, height: 16.0))
                            self.statusItems["MeteoBar"]?.title = sensor.formattedMeasurement
                        }
                    case .minor, .moderate:
                        DispatchQueue.main.async { [unowned self] in
                            self.statusItems["MeteoBar"]?.button?.image = NSImage(named: "warning-yellow.png")?.resized(to: NSSize(width: 16.0, height: 16.0))
                            self.statusItems["MeteoBar"]?.title = sensor.formattedMeasurement
                        }
                    case .unknown:
                        log.warning("Unkown alert discovered")
                    }
                    self.postNotifcationForStation(theBridge: theBridge, theAlertID: alert.identfier)
                }
            }
            if theBridge.weatherAlerts.isEmpty {
                self.statusItems["MeteoBar"]?.button?.image = nil
            }
        }
    }
    
    ///
    /// Post a notification to the Notification Center about a weather alert.
    /// Try to make it as unobtrusive as possible.  Give the user a chance to
    /// acknowledge or dismiss teh alert.  If no activity after 10 seconds, the
    /// dismissed on behalf of the user
    ///
    /// ## Important Notes ##
    ///
    /// None
    ///
    /// ## Extras ##
    ///
    /// None
    ///
    /// - parameter theStation: The station that generated the alert
    /// - parameter theAlertID: The unique alert ID
    /// - throws:       Nothing
    /// - returns:      Nothing
    ///
    private func postNotifcationForStation(theBridge: Meteobridge, theAlertID: String) {
        guard let alert = theBridge.weatherAlerts.filter ({$0.identfier == theAlertID}).first else {
            log.warning(MeteobarError.weatherAlertWarning)
            return
        }
        
        let notification = NSUserNotification()
        let delayBeforeDelivering: TimeInterval = 0.25  // A quarter-second delay
        let notificationcenter = NSUserNotificationCenter.default
        
        notification.soundName          = NSUserNotificationDefaultSoundName
        notification.actionButtonTitle  = "Open"
        notification.otherButtonTitle   = "Dismiss"
        notification.hasActionButton    = true
        notification.identifier         = theAlertID
        notification.title              = alert.event
        notification.subtitle           = "\(theBridge.name)"
        notification.informativeText    = "Ends: \(alert.endsOn.toShortDateTimeString())"
        notification.userInfo           = ["Alert": "\(theAlertID):\(theBridge.uuid)"]
        notification.contentImage       = NSImage(named: NSImage.Name("NWSLogo.png"))
        notification.deliveryDate       = Date(timeIntervalSinceNow: delayBeforeDelivering)
        
        notificationcenter.scheduleNotification(notification)
    }
    
    /// Show the preferences window with the Setup Tab selected
    ///
    /// *** DEPRECATED ***
    /// *** Look in MeteoPanelController for updated logic
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
    /// *** DEPRECATED ***
    /// *** Look in MeteoPanelController for updated logic
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
    /// *** DEPRECATED ***
    /// *** Look in MeteoPanelController for updated logic
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
    /// *** DEPRECATED ***
    /// *** Look in MeteoPanelController for updated logic
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
    /// *** DEPRECATED ***
    /// *** Look in MeteoPanelController for updated logic
    ///
    /// - Parameter sender: The Caller who sent the message
    ///
    @IBAction func quitMeteoBar(_ sender: Any) {
        for key in observerQueue.keys {
            observerQueue[key]?.pause()
            observerQueue.removeValue(forKey: key)
        }
        
        for key in alertQueue.keys {
            alertQueue[key]?.pause()
            alertQueue.removeValue(forKey: key)
        }
        
        observerQueue.removeAll()
        alertQueue.removeAll()
        NSApplication.shared.terminate(self)
    }    
}

// MARK: NSUserNotificationCenterDelegate Extension
///
/// Extend NSUserNotifcationCenter to handle the callbacks for any alerts that get fed to the Notifcation Center
///
/// ## Important Notes ##
///
/// userInfo format: ["Alert": "\(theAlertID):\(theStation.uniqueID!)"]
/// userPair[0] == AlertID
/// userPair[1] == BridgeUUID
///
/// - parameters: None
/// - throws: Nothing
/// - returns:  Nothing
///
extension MainMenuController: NSUserNotificationCenterDelegate {
    /// A special ovveride to detect the "Dismiss" or "Close" button on a delivered notification
    ///
    /// ## Notes ##
    ///   PS: Please also notice that it is the way to detect the dismiss event, which can be triggered in several cases.
    ///   1. Click the otherButton to dismiss
    ///   2. Click the Clear All button in Notification Center
    ///   3. There are multiple notifications in deliveredNotifications array, while only one is displayed. The dismissal shall trigger multiple callbacks.
    ///   4. Clicking actionButton will also trigger the dismissal callback
    ///
    /// ## Reference ##
    ///  [Notifcations](https://stackoverflow.com/questions/21110714/mac-os-x-nsusernotificationcenter-notification-get-dismiss-event-callback)
    /// - Parameters:
    ///   - center: <#center description#>
    ///   - notification: <#notification description#>
    ///
    func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
        DispatchQueue.global(qos: .background).async {
            var notificationStillPresent: Bool
            repeat {
                notificationStillPresent = false
                for nox in NSUserNotificationCenter.default.deliveredNotifications where nox.identifier == notification.identifier {
                    notificationStillPresent = true
                    break
                }
                
                if notificationStillPresent {
                    _ = Thread.sleep(forTimeInterval: 0.20)
                }
            } while notificationStillPresent
            
            DispatchQueue.main.async {
                self.dismissClicked(notification: notification)
            }
        }
    }
    
    /// Helper to acknowledge the user hitting the "Dismiss" button
    /// What a pain in the ass to go through this when there is a perfectly
    /// acceptable enumeration in notification.activationType that could
    /// have handled it w/o all of this
    ///
    /// - Parameter notification: the notifcation that we want to dismiss
    ///
    private func dismissClicked(notification: NSUserNotification) {
        guard let userInfo = notification.userInfo!["Alert"] as? String else {
            log.warning("Warning: Unknown alert data; skipping further action.")
            return
        }
        
        guard let userPair = userInfo.components(separatedBy: ":") as [String]? else {
            log.warning("Warning: Unable to determine user pair for alert; skipping further action.")
            return
        }
        
        guard let theAlert = theDelegate?.theBridge?.weatherAlerts.filter ({$0.identfier == userPair[0]}).first else {
            log.warning("Warning: Unable to determine AlertID for alert; skipping further action.")
            return
        }
        
        theAlert.acknowledge()
        log.info("bridge[\(theDelegate?.theBridge?.name ?? "")] has acknodleged alert[\(theAlert.identfier)]-->\(theAlert.headline).")
    }
    
    /// Handle the user clicking the action button
    ///
    /// - Parameters:
    ///   - center: the notification center to use
    ///   - notification: the notification we want to handle
    ///
    func userNotificationCenter (_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        center.delegate = self
        
        guard let userInfo = notification.userInfo!["Alert"] as? String else {
            log.warning("Warning: Unknown alert data; skipping further action.")
            return
        }
        
        guard let userPair = userInfo.components(separatedBy: ":") as [String]? else {
            log.warning("Warning: Unable to determine user pair for alert; skipping further action.")
            return
        }
        
        guard let theAlert = theDelegate?.theBridge?.weatherAlerts.filter ({$0.identfier == userPair[0]}).first else {
            log.warning("Warning: Unable to determine AlertID for alert; skipping further action.")
            return
        }
        
        switch notification.activationType {
        case .actionButtonClicked: // "Alert" Button
            log.info("bridge[\(theDelegate?.theBridge?.name ?? "")] has issued an alert[\(theAlert.identfier)]-->\(theAlert.headline).")
            theAlert.acknowledge()
            statusItems["MeteoBar"]?.button?.performClick(self)
        case .additionalActionClicked:
            log.info("Additional Action")
        case .contentsClicked:
            log.info("Contents")
        case .none:
            log.info("None")
        case .replied:
            log.info("Replied")
        }
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

// MARK: - Custom extension to handle UI updates for the AlertView
/// *** DEPRECATED ***
/// *** Look in MeteoPanelController for updated logic
///
extension MainMenuController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        for item in menu.items {
            switch item.view {
            case is AlertView:
                guard let alertView = item.view as? AlertView else {
                    break
                }
                if theDelegate?.theBridge != nil {
                    alertView.refreshAlerts(alerts: (theDelegate?.theBridge?.weatherAlerts)!)
                }
            default:
                break
            }
        }
    }

    func menuDidClose(_ menu: NSMenu) {

    }
}
