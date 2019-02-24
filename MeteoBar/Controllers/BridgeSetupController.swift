//
//  BridgeSetupController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 2/3/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Preferences
import MapKit
import Cocoa

enum BridgeSetupControllerError: Error, CustomStringConvertible {
    case noBridge
    case noBridgeImage
    case noBridgeParameters
    
    var description: String {
        switch self {
        case .noBridge: return "There is no bridge currently configured"
        case .noBridgeImage: return "Cannot determine image for current platform"
        case .noBridgeParameters: return "Cannot determine bridge parameters"
        }
    }
}

class BridgeSetupController: NSViewController, Preferenceable {
    // MARK: - Protocol Variables
    let toolbarItemTitle = "Bridge Setup"
    let toolbarItemIcon = NSImage(named: "configurator.png")!

    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var platformImage: NSImageView!
    @IBOutlet weak var bridgeName: NSTextField!
    @IBOutlet weak var bridgeIP: NSTextField!
    @IBOutlet weak var connectButton: NSButton!
    @IBOutlet weak var latitudeLabel: NSTextField!
    @IBOutlet weak var longitudeLabel: NSTextField!
    @IBOutlet weak var stationLabel: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var buildLabel: NSTextField!
    @IBOutlet weak var platformLabel: NSTextField!
    @IBOutlet weak var stationNumberLabel: NSTextField!
    @IBOutlet weak var altitudeLabel: NSTextField!
    @IBOutlet weak var macLabel: NSTextField!
    @IBOutlet weak var healthIcon: NSImageView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "BridgeSetup"
    }

    override func viewWillAppear() {
        // First, check to see if we have a bridge configured, if we do update the view with the saved metadata.
        // If we don't, do nothing and wait for the user to begin the process
        if theDelegate?.theBridge != nil {
            updateBridgeMetadata()
        }
        super.viewWillAppear()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    ///
    /// Helper to configure the view with bridge metadata
    ///
    private func updateBridgeMetadata() {
        guard let theBridge = theDelegate?.theBridge! else {
            log.error(BridgeSetupControllerError.noBridge)
            return
        }
        
        // Update the system paramaters with what the meteobridge is currently reporting
        theBridge.getAllSystemParameters { [unowned self] (bridge: Meteobridge?, error: Error?) in
            if bridge != nil {
                theDelegate?.updateMeteoBar()   // Save the results
                self.updateMapView()            // Update the map based on the latest
            } else {
                log.warning(BridgeSetupControllerError.noBridgeParameters)          // Something went wrong
                return
            }
            
            // Grab the image for the platform hosting the meteobridge
            WeatherPlatform.getPlatformImage(theBridge.findSensor(sensorName: "platform")!.formattedMeasurement!) { (_ image, _ error) in
                if image != nil {
                    self.platformImage.image = image    // We have a platform; lets find the image
                } else {
                    log.warning(BridgeSetupControllerError.noBridgeImage)
                }
            }
            
            // We have what we need ... let's go
            DispatchQueue.main.async { [unowned self] in // Use DispatchQueue.main to ensure UI updates are done on the main thread
                // Lat/lon
                let dms = theBridge.coordinate.dms
                self.longitudeLabel.stringValue = dms.longitude
                self.latitudeLabel.stringValue = dms.latitude
                
                // The rest ...
                self.stationNumberLabel.stringValue = theBridge.findSensor(sensorName: "stationnum")!.formattedMeasurement!
                self.altitudeLabel.stringValue = theBridge.findSensor(sensorName: "altitude")!.formattedMeasurement!
                self.platformLabel.stringValue = theBridge.findSensor(sensorName: "platform")!.formattedMeasurement!
                self.versionLabel.stringValue = theBridge.findSensor(sensorName: "swversion")!.formattedMeasurement!
                self.stationLabel.stringValue = theBridge.findSensor(sensorName: "station")!.formattedMeasurement!
                self.buildLabel.stringValue = theBridge.findSensor(sensorName: "buildnum")!.formattedMeasurement!
                self.macLabel.stringValue = theBridge.findSensor(sensorName: "mac")!.formattedMeasurement!
                self.bridgeIP.stringValue = theBridge.ipAddress
                self.bridgeName.stringValue = theBridge.name
                
                // Status Icon
                guard let seconds = Int(theBridge.findSensor(sensorName: "lastgooddata")!.formattedMeasurement!) else {
                    self.healthIcon.image = NSImage(named: NSImage.statusUnavailableName)
                    return
                }
                
                if seconds > 0 && seconds < 60 {
                    self.healthIcon.image = NSImage(named: NSImage.statusAvailableName)
                    self.healthIcon.toolTip = "Valid sensor data recieved withn the last minute"
                } else if seconds > 61 && seconds < 120 {
                    self.healthIcon.image = NSImage(named: NSImage.statusPartiallyAvailableName)
                    self.healthIcon.toolTip = "Valid sensor data recieved less than 2 minutes ago"
                } else {
                    self.healthIcon.image = NSImage(named: NSImage.statusUnavailableName)
                    self.healthIcon.toolTip = "Valid sensor data not recieved in over 2 minutes"
                }
                // Status Icon
            }
        }
    }
    
    ///
    /// Initialize/Update the map based on the properly configured bridge
    ///
    private func updateMapView() {
        if theDelegate?.theBridge != nil {
            mapView.addAnnotation((theDelegate?.theBridge)!)
            mapView.centerCoordinate = (theDelegate?.theBridge!.coordinate)!
            mapView.setRegion(MKCoordinateRegion(center: mapView.centerCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)), animated: true)
            
            // Setup MapKitView
            let mapCamera = MKMapCamera()
            mapCamera.centerCoordinate = mapView.centerCoordinate
            mapCamera.altitude  = 250.0
            mapCamera.pitch     = 30.0
            mapCamera.heading   = 30.0
            
            mapView.mapType = MKMapType.satellite
            mapView.camera = mapCamera
        } else {
            log.error(BridgeSetupControllerError.noBridge)
        }
    }
    
    ///
    /// Initialize the bridge based on the name and IP
    ///
    private func initializeBridge() {
        WeatherPlatform.initializeBridgeSpecification(ipAddress: bridgeIP.stringValue, bridgeName: bridgeName.stringValue, callback: { [unowned self] response, error in
            if error == nil {
                theDelegate!.theBridge = response                                       // Bridge was loaded from the json description
                theDelegate!.theBridge!.getObservation(allParams: true, { _, error in   // Get a "FULL" observation so we can see what's going on
                    if error != nil {                                                   // Any errors?
                        log.error(error.value)                                          // Something went wrong getting an initial observation... tell us about it
                    }
                    
                    guard let sensorUL = theDelegate!.theBridge?.findSensor(sensorName: (theDelegate?.theDefaults!.compassULSensor)!) else {
                        log.warning("Cannot find Senor[\(theDelegate?.theDefaults!.compassULSensor ?? "")]: to observe.")
                        return
                    }
                    sensorUL.isObserving = true

                    guard let sensorUR = theDelegate!.theBridge?.findSensor(sensorName: (theDelegate?.theDefaults!.compassURSensor)!) else {
                        log.warning("Cannot find Senor[\(theDelegate?.theDefaults!.compassURSensor ?? "")]: to observe.")
                        return
                    }
                    sensorUR.isObserving = true

                    guard let sensorLL = theDelegate!.theBridge?.findSensor(sensorName: (theDelegate?.theDefaults!.compassLLSensor)!) else {
                        log.warning("Cannot find Senor[\(theDelegate?.theDefaults!.compassLLSensor ?? "")]: to observe.")
                        return
                    }
                    sensorLL.isObserving = true

                    guard let sensorLR = theDelegate!.theBridge?.findSensor(sensorName: (theDelegate?.theDefaults!.compassLRSensor)!) else {
                        log.warning("Cannot find Senor[\(theDelegate?.theDefaults!.compassLRSensor ?? "")]: to observe.")
                        return
                    }
                    sensorLR.isObserving = true

                    guard let sensorWind = theDelegate!.theBridge?.findSensor(sensorName: ("wind0dir")) else {
                        log.warning("Cannot find Senor[wind0dir]: to observe.")
                        return
                    }
                    sensorWind.isObserving = true
                    theDelegate?.updateBridge()
                    
                    self.progressIndicator.stopAnimation(nil)               // Stop the spinning
                })
                self.updateBridgeMetadata()                                 // Update the metatdata and prepare the view
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BridgeInitialized"), object: nil, userInfo: nil)
            } else {                                                        // Something went wrong ... tell us about it
                log.error(error.value)                                      // We should only get here IF we cannot load the json description
            }
        })
    }
    
    /// MARK - Actions
    @IBAction func connectClicked(_ sender: Any) {
        if theDelegate?.theBridge != nil {
            let alert = NSAlert()
            alert.messageText = "Bridge Already Configured"
            alert.informativeText = "If you proceed, you will overwrite the current configuration"
            alert.alertStyle = .warning
            alert.icon = NSImage(named: NSImage.cautionName)
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Continue")
            alert.beginSheetModal(for: self.view.window!) { [unowned self] (_ returnCode: NSApplication.ModalResponse) -> Void in
                switch returnCode {
                case .alertFirstButtonReturn:
                    // Eat it; the user selected cancel ... do nothing
                    break
                case .alertSecondButtonReturn:
                    self.progressIndicator.startAnimation(nil)
                    self.initializeBridge()
                default:
                    break
                }
            }
        } else {    // We're good ... no previous bridge
            progressIndicator.startAnimation(nil)
            initializeBridge()
        }
    }
    
    ///
    /// Detect when the user hits the return key of the ipField.  If we hve a valid IP, GO!
    /// ## Special Note ##
    ///  We need to change the TextField to send the notification on return
    ///
    /// - Parameter sender: intercept the change notification and check validity
    ///
    @IBAction func ipReturnSelected(_ sender: Any) {
        if let textField = sender as? NSTextField {
            if validateIPAddress(textField.stringValue) {
                connectClicked(textField)
            }
        }
    }
}

// MARK: - Support for MKMapViewDelegate
extension BridgeSetupController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.pinTintColor = NSColor.blue
            annotationView!.canShowCallout = true
            
            let newLabel = NSTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            let newSize = NSSize(width: newLabel.bestwidth(text: annotation.subtitle! ?? "", height: 0),
                                 height: newLabel.bestheight(text: annotation.subtitle! ?? "", width: 0))
            newLabel.setFrameSize(newSize)
            newLabel.alphaValue             = annotationView?.alphaValue ?? 0.0
            newLabel.wantsLayer             = true
            newLabel.layer?.backgroundColor = NSColor.clear.cgColor
            newLabel.textColor              = NSColor.labelColor
            newLabel.drawsBackground        = false
            newLabel.isEditable             = false
            newLabel.isSelectable           = false
            newLabel.stringValue            = annotation.subtitle! ?? ""
            annotationView!.detailCalloutAccessoryView = newLabel
        } else {
            annotationView!.annotation = annotation
        }

        return annotationView
    }
}

// MARK: - Support for NSControlTextEditingDelegate
extension BridgeSetupController: NSControlTextEditingDelegate {
    ///
    /// Regex Expression to validate an IP address
    ///
    /// - Parameter sender: string to check
    /// - Returns: true if it's a valid IP .... false if it's not
    ///
    func validateIPAddress(_ sender: String) -> Bool {
        let validIP = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
        if sender.isEmpty || (sender.range(of: validIP, options: .regularExpression) == nil) {
            return false
        } else {
            return true
        }
    }

    ///
    /// Poor-man's hack to check if/when a valid IP address is input
    ///
    /// - Parameter notification: intercept the change notification and check
    ///
    func controlTextDidChange(_ notification: Notification) {
        if let textField = notification.object as? NSTextField {
            if validateIPAddress(textField.stringValue) {
                connectButton.isEnabled = true
            } else {
                connectButton.isEnabled = false
            }
        }
    }
}