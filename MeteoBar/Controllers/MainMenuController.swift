//
//  MainMenuController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/13/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import SwiftyUserDefaults
import Reachability
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
        case .bridgeError: return "Error reading data from Meteobridge"
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
    // MARK: - Local properties
    var statusItems     = [String: NSStatusItem]()
    var observerQueue   = [String: Repeater]()
    var alertQueue      = [String: Repeater]()
    var eventMonitor: MeteoEventMonitor?
    @IBOutlet weak var delegate: AppDelegate!   // w/o this we get a memory leak
    @IBOutlet var newView: NSView!              // w/o this we get a memory leak
    
    let reachability    = Reachability()        // Network Testing
    var bConnected      = false
    
    // MARK: - Views
    /// Main Weather Panel
    lazy var meteoPanelView: MeteoPanelController = {
        return MeteoPanelController(nibName: NSNib.Name("MeteoPanel"), bundle: nil)
    }()
    
    // MARK: - Overrides
    override func awakeFromNib() {
        statusItems["MeteoBar"]                 = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItems["MeteoBar"]?.title          = "--"
        statusItems["MeteoBar"]?.button!.target = self
        statusItems["MeteoBar"]?.button!.action = #selector(showWeatherPanel(sender:))

        /// Register as a delegate for the notification center
        NSUserNotificationCenter.default.delegate = self

        /// Setup a call-forward listener for anyone to tell the controller that our weather panel has been closed - somehow
        NotificationCenter.default.addObserver(self, selector: #selector(weatherPanelClosed(sender:)), name: NSNotification.Name(rawValue: "WeatherPanelClosed"), object: nil)

        /// Setup a call-forward listener for anyone to tell the controller that we have a new bridge
        NotificationCenter.default.addObserver(self, selector: #selector(newBridgeInitialized(sender:)), name: NSNotification.Name(rawValue: "BridgeInitialized"), object: nil)

        /// Setup a call-forward listener for anyone to ask the Menu to update with a new observation
        NotificationCenter.default.addObserver(self, selector: #selector(getObservation(sender:)), name: NSNotification.Name(rawValue: "UpdateObservation"), object: nil)

        /// Setup a call-forward listener for anyone to tell the controller to retrive alerts
        NotificationCenter.default.addObserver(self, selector: #selector(getAlerts(sender:)), name: NSNotification.Name(rawValue: "RetrieveAlerts"), object: nil)
        
        /// Setup a call-forward listener for reachability notifcations
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability!.startNotifier()
        } catch {
            log.error("Could not start reachability notifier")
        }
        
        newBridgeInitialized(sender: self)

        /// Setup mouse event monitoring for a click anywhere so we can close our weather panel
        eventMonitor = MeteoEventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self!.meteoPanelView.isViewLoaded && self!.meteoPanelView.view.window != nil {
                self!.meteoPanelView.view.window?.close()
                self?.eventMonitor!.stop()
            }
        }
    }
    
    /// Notifier to let the app know whether there is any network connectivity
    /// - Parameter note: notifcation message
    ///
    @objc func reachabilityChanged(note: Notification) {
        guard let reachability = note.object as? Reachability else {
            log.error("Could not determine notification")
            return
        }
                
        switch reachability.connection {
        case .wifi:
            log.info("Connected via WiFi")
            bConnected = true
        case .cellular:
            log.info("Connected via Cellular")
            bConnected = true
        case .none:
            log.error("No longer connected to network; suspending network calls")
            bConnected = false
        }
    }
    
    /// EXPIRIMENTAL
    ///
    /// ## SPECIAL NOTE ##
    /// uncomment the following line to return to using this class
    /// statusItems["MeteoBar"]?.menu   = menuMain
    ///
    /// - Parameter sender: sender of teh notification
    ///
    @objc func showWeatherPanel(sender: AnyObject) {
        if meteoPanelView.isViewLoaded && (meteoPanelView.view.window != nil) {
            meteoPanelView.view.window?.close()
            eventMonitor?.stop()
            return
        } else {
            let frameOrigin = statusItems["MeteoBar"]?.button?.window?.frame.origin
            meteoPanelView.originPoint = CGPoint(x: (frameOrigin?.x)!, y: (frameOrigin?.y)! - 22)
            presentAsModalWindow(meteoPanelView)
            eventMonitor?.start()
        }
    }

    @objc func weatherPanelClosed(sender: AnyObject) {
        eventMonitor?.stop()
    }
    
    /// We have creasted and configured a new meteobridge ... start the machine
    ///
    /// - Parameter theNotification: the notifcation letting us knoe
    ///
    @objc private func newBridgeInitialized(sender: AnyObject) {
        guard let bridge = theDelegate?.theBridge else {
            log.error(MeteobarError.bridgeError)
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
            log.error(MeteobarError.missingBridge)
            return
        }
        
        let queue = Repeater(interval: .seconds(Double(theBridge!.updateInterval)), mode: .infinite) { [unowned self] _ in
            if self.bConnected {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateObservation"), object: nil, userInfo: nil)
            }
        }
        
        queue.start()
        observerQueue[theBridge!.uuid] = queue
        
        DispatchQueue.main.async { [weak theBridge] in // Kick off the first observation while we wait for the timers to count down
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateObservation"), object: nil, userInfo: nil)
            log.info("\(theBridge!.name) will poll every \(theBridge!.updateInterval) seconds.")
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
            log.error(MeteobarError.missingBridge)
            return
        }
        
        let queue = Repeater(interval: .seconds(Double(theBridge!.alertUpdateInterval)), mode: .infinite) { [unowned self] _ in
            if self.bConnected {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RetrieveAlerts"), object: nil, userInfo: nil)
            }
        }
            
        alertQueue[theBridge!.uuid] = queue
        queue.start()
            
        DispatchQueue.main.async { [weak theBridge] in // Kick off the first alert while we wait for the timers to count down
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RetrieveAlerts"), object: nil, userInfo: nil)
            log.info("\(theBridge!.name) will poll for alerts every \(theBridge!.alertUpdateInterval) seconds.")
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
//    @objc private func getObservation(_ theNotification: Notification) {
    @objc private func getObservation(sender: AnyObject) {
        guard let bridge = theDelegate?.theBridge else {
            log.error(MeteobarError.bridgeError)
            return
        }
        
        bridge.getObservation { [unowned self, unowned bridge] (_ error: Error?) in
            if error == nil {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NewObservationReceived"),
                                                object: nil, userInfo: nil)  // Broadcast to all listeners - we have a new measurement.  Update as needed.
                guard let sensor = bridge.findSensor(sensorName: (theDelegate?.theDefaults?.menubarSensor)!) else {
                    log.warning(MeteobarError.missingMenubarSensor)
                    return
                }
                DispatchQueue.main.async { [unowned self, unowned sensor] in
                    self.statusItems["MeteoBar"]?.title = sensor.formattedMeasurement
                }
            } else {
                log.error(error.value)
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
//    @objc private func getAlerts(_ theNotification: Notification) {
    @objc private func getAlerts(sender: AnyObject) {
        guard let theBridge = theDelegate?.theBridge else {
            log.error(MeteobarError.bridgeError)
            return
        }
        
        theBridge.getWeatherAlerts { [unowned self, unowned theBridge] (_ error: Error?) in
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
                        DispatchQueue.main.async { [unowned self, unowned sensor] in
                            self.statusItems["MeteoBar"]?.button?.image = NSImage(named: "warning-red.png")?.resized(to: NSSize(width: 16.0, height: 16.0))
                            self.statusItems["MeteoBar"]?.title = sensor.formattedMeasurement
                        }
                    case .minor, .moderate:
                        DispatchQueue.main.async { [unowned self, unowned sensor] in
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
        guard let alert = theBridge.weatherAlerts.filter({$0.identfier == theAlertID}).first else {
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
        notification.deliveryDate       = Date(timeIntervalSinceNow: delayBeforeDelivering)
        
        switch alert.severity {
        case .extreme, .severe:
            notification.contentImage   = NSImage(named: "warning-red.png")
        case .minor, .moderate:
            notification.contentImage   = NSImage(named: "warning-yellow.png")
        case .unknown:
            notification.contentImage   = NSImage(named: NSImage.Name("NWSLogo.png"))
        }
        notificationcenter.scheduleNotification(notification)
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
        DispatchQueue.global(qos: .background).async { [unowned self] in
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
            
            DispatchQueue.main.async { [unowned self] in
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
        
        guard let theAlert = theDelegate?.theBridge?.weatherAlerts.filter({$0.identfier == userPair[0]}).first else {
            log.warning("Warning: Unable to determine AlertID for alert; skipping further action.")
            return
        }
        
        theAlert.acknowledge()
//        log.info("bridge[\(theDelegate?.theBridge?.name ?? "")] has acknodleged alert[\(theAlert.identfier)]-->\(theAlert.headline).")
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
        
        guard let theAlert = theDelegate?.theBridge?.weatherAlerts.filter({$0.identfier == userPair[0]}).first else {
            log.warning("Warning: Unable to determine AlertID for alert; skipping further action.")
            return
        }
        
        switch notification.activationType {
        case .actionButtonClicked: // "Alert" Button
//            log.info("bridge[\(theDelegate?.theBridge?.name ?? "")] has issued an alert[\(theAlert.identfier)]-->\(theAlert.headline).")
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
