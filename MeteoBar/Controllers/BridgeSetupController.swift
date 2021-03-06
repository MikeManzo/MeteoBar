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
    case unknownOverlay
    case noBridgeParameters
    
    var description: String {
        switch self {
        case .noBridge: return "There is no bridge currently configured"
        case .noBridgeImage: return "Cannot determine image for current platform"
        case .noBridgeParameters: return "Cannot determine bridge parameters"
        case .unknownOverlay: return "Unknwon Overlay detected - skipping"
        }
    }
}

enum BridgeSetupControllerHUD: String, CustomStringConvertible {
    case startingContinuousMonitoring
    case pollingForSystemParameters
    case settingUpDisplayElements
    case readingConfigurationFile
    case settingUpWeatherModels
    case gettingObservation
    
    var description: String {
        switch self {
        case .pollingForSystemParameters: return "Polling Meteobridge for System Paramaters ..."
        case .startingContinuousMonitoring: return "Starting continuous weather readings ..."
        case .readingConfigurationFile: return "Reading Meteobridge configuration file ..."
        case .settingUpWeatherModels: return "Setting up Meteobridge Weather Models ..."
        case .gettingObservation: return "Getting weather observation from sensors ..."
        case .settingUpDisplayElements: return "Setting up display elements ..."
        }
    }
}

class BridgeSetupController: NSViewController, PreferencePane {
    // MARK: - Protocol Variables
    let preferencePaneTitle = "Bridge Setup"
    let toolbarItemIcon = NSImage(named: "configurator.png")!
    let preferencePaneIdentifier = PreferencePane.Identifier.setup

    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var platformImage: NSImageView!
    @IBOutlet weak var bridgeName: NSTextField!
    @IBOutlet weak var bridgeIP: NSTextField!
    @IBOutlet weak var connectButton: NSButton!
    @IBOutlet weak var mapZoomButton: NSButton!
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
    @IBOutlet weak var forecastSwitch: OGSwitch!
    @IBOutlet weak var countySwitch: OGSwitch!
    @IBOutlet weak var alertSwitch: OGSwitch!
    @IBOutlet weak var meteoInformation: NSBox!
    
    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "BridgeSetup"
    }

    override func viewWillAppear() {
        // First, check to see if we have a bridge configured, if we do update the view with the saved metadata.
        // If we don't, do nothing and wait for the user to begin the process
        if theDelegate?.theBridge != nil {
            
            theDelegate?.theBridge?.getSystemParameter(systemParam: MeteobridgeSystemParameter.lastgooddata, callback: { [unowned self] (_ sensor, _ error) in
                if error == nil {
                    // Update the status Icon
                    guard let seconds = Int(sensor!.formattedMeasurement!) else {
                        self.healthIcon.image = NSImage(named: NSImage.statusUnavailableName)
                        return
                    }
                    self.updateStatusIcon(seconds: seconds)
                } else {
                    log.error(error.value)
                }
            })
            updateBridgeMetadata()
        }
        super.viewWillAppear()
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        print("Mouse Down:\(event.locationInWindow) in Window: \(String(describing: event.window))")
    }
   
    override func viewDidAppear() {
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        // Update the polygon switches
        theDelegate?.theDefaults?.showForecastPolygon   = forecastSwitch.isOn
        theDelegate?.theDefaults?.showCountyPolygon     = countySwitch.isOn
        theDelegate?.theDefaults?.showAlertPolygon      = alertSwitch.isOn
        // Update the polygon switches
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
        // Take care of our black/white icons
        connectButton.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "play-button.png")!.filter(filter: "CIColorInvert") : NSImage(named: "play-button.png")
        mapZoomButton.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "map-zoom.png")!.filter(filter: "CIColorInvert") : NSImage(named: "map-zoom.png")
        // Take care of our black/white icons
        
        preferredContentSize    = NSSize(width: 919, height: 440)      // Set the size of our view
    }
    
    ///
    /// Helper to configure the view with bridge metadata
    ///
    private func updateBridgeMetadata() {
        guard let theBridge = theDelegate?.theBridge! else {
            log.error(BridgeSetupControllerError.noBridge)
            return
        }
        
        if ProgressHUD.isVisible() {
            ProgressHUD.show(withStatus: BridgeSetupControllerHUD.settingUpDisplayElements.description)
        }
        // Grab the image <from the meteobridge> for the platform hosting meteobridge
        WeatherPlatform.getPlatformImage(theBridge.findSensor(sensorName: "platform")!.formattedMeasurement!) { [unowned self] (_ image, _ error) in
            if error == nil {
                // Let's update the user interface
                DispatchQueue.main.async { [unowned self] in    // Use DispatchQueue.main to ensure UI updates are done on the main thread
                    self.platformImage.image = image            // We have a platform; lets display the image
                    if self.mapView.overlays.isEmpty {          // If no overlays ... add them; if there are ... skip and don't re-add
                        for (type, polyline) in theBridge.polygonOverlays {
                            switch type {
                            case "Forecast":
                                if theDelegate?.theDefaults?.showForecastPolygon == true {
                                    let polygon = MKMeteoPolygon(coordinates: polyline.coordinates, count: polyline.pointCount)
                                    polygon.polyName = type
                                    polyline.lineName = type
                                    self.mapView.addOverlay(polyline)
                                    self.mapView.addOverlay(polygon)
                                }
                            case "County":
                                if theDelegate?.theDefaults?.showCountyPolygon  == true {
                                    let polygon = MKMeteoPolygon(coordinates: polyline.coordinates, count: polyline.pointCount)
                                    polygon.polyName = type
                                    polyline.lineName = type
                                    self.mapView.addOverlay(polyline)
                                    self.mapView.addOverlay(polygon)
                                }
                            case "Alert":
                                if theDelegate?.theDefaults?.showForecastPolygon  == true {
                                    let polygon = MKMeteoPolygon(coordinates: polyline.coordinates, count: polyline.pointCount)
                                    polygon.polyName = type
                                    polyline.lineName = type
                                    self.mapView.addOverlay(polyline)
                                    self.mapView.addOverlay(polygon)
                                }
                            default:
                                log.warning(BridgeSetupControllerError.unknownOverlay)
                            }
                        }
                    }
                    self.updateMapView()                        // Update the map based on the latest
                    if ProgressHUD.isVisible() {
                        ProgressHUD.show(withStatus: BridgeSetupControllerHUD.startingContinuousMonitoring.description)
                    }
                    
                    // Update the Latitude & Longitude in human readable form
                    let dms = theBridge.coordinate.dms
                    self.longitudeLabel.stringValue = dms.longitude
                    self.latitudeLabel.stringValue = dms.latitude
                    
                    // Update the the rest of the metadata
                    self.stationNumberLabel.stringValue = theBridge.findSensor(sensorName: "stationnum")!.formattedMeasurement!
                    self.versionLabel.stringValue       = theBridge.findSensor(sensorName: "swversion")!.formattedMeasurement!
                    self.buildLabel.stringValue         = theBridge.findSensor(sensorName: "buildnum")!.formattedMeasurement!
                    self.altitudeLabel.stringValue      = theBridge.findSensor(sensorName: "altitude")!.formattedMeasurement!
                    self.platformLabel.stringValue      = theBridge.findSensor(sensorName: "platform")!.formattedMeasurement!
                    self.stationLabel.stringValue       = theBridge.findSensor(sensorName: "station")!.formattedMeasurement!
                    self.macLabel.stringValue           = theBridge.findSensor(sensorName: "mac")!.formattedMeasurement!
                    self.bridgeIP.stringValue           = theBridge.ipAddress
                    self.bridgeName.stringValue         = theBridge.name
                    // Update the the rest of the metadata

                    // Update the polygon switches
                    self.forecastSwitch.setOn(isOn: (theDelegate?.theDefaults?.showForecastPolygon)!, animated: true)
                    self.countySwitch.setOn(isOn: (theDelegate?.theDefaults?.showCountyPolygon)!, animated: true)
                    self.alertSwitch.setOn(isOn: (theDelegate?.theDefaults?.showAlertPolygon)!, animated: true)
                    // Update the polygon switches

                    // Update the status Icon
                    guard let seconds = Int(theBridge.findSensor(sensorName: "lastgooddata")!.formattedMeasurement!) else {
                        self.healthIcon.image = NSImage(named: NSImage.statusUnavailableName)
                        return
                    }
                    
                    self.updateStatusIcon(seconds: seconds)
                    // Enable the connect button
                    if self.validateIPAddress(self.bridgeIP.stringValue) {
                        self.connectButton.isEnabled = true
                    }
                    // Enable the connect button
                    
                    // Enable the zoom button
                    self.mapZoomButton.isEnabled = true
                    // Enable the zoom button

                    // We made it; dismiss the HUD
                    self.dismissHUD()
                    // We made it; dismiss the HUD
                }
            } else {
                log.warning(BridgeSetupControllerError.noBridgeImage)
                ProgressHUD.show(withStatus: error.value)
                self.dismissHUD()
            }
        }
    }
    
    /// Update the bridge indicator (Red/Yellow/Green) for valid data
    ///
    /// - Parameter seconds: the number of seconds since last valid data
    ///
    private func updateStatusIcon(seconds: Int) {
        if seconds > 0 && seconds < 60 {
            self.healthIcon.image = NSImage(named: NSImage.statusAvailableName)
            self.healthIcon.toolTip = "Valid sensor data recieved withn the last minute"
        } else if seconds > 61 && seconds < 120 {
            self.healthIcon.image = NSImage(named: NSImage.statusPartiallyAvailableName)
            self.healthIcon.toolTip = "Valid sensor data recieved less than 2 minutes ago"
        } else {
            self.healthIcon.image = NSImage(named: NSImage.statusUnavailableName)
            self.healthIcon.toolTip = "No valid data recieved in over 2 minutes"
        }
    }
    
    ///
    /// Initialize/Update the map based on the properly configured bridge
    ///
    private func updateMapView() {
        if theDelegate?.theBridge != nil {
            mapView.addAnnotation((theDelegate?.theBridge)!)
            mapView.centerCoordinate = (theDelegate?.theBridge!.coordinate)!
            
            // Setup MapKitView
            let mapCamera               = MKMapCamera()
            mapCamera.centerCoordinate  = mapView.centerCoordinate
            mapCamera.altitude          = 250.0
            mapCamera.pitch             = 30.0
            mapCamera.heading           = 30.0
            mapView.mapType             = MKMapType.satellite
            mapView.camera              = mapCamera
            // Setup MapKitView
            
            mapView.fitToAnnotaions(animated: true, shouldIncludeUserAccuracyRange: true,
                                    edgePadding: NSEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0))
        } else {
            log.error(BridgeSetupControllerError.noBridge)
        }
    }
    
    ///
    /// Initialize the bridge based on the name and IP
    ///
    private func initializeBridge() {
        ProgressHUD.setFont(NSFont.systemFont(ofSize: 16))
        ProgressHUD.setContainerView(meteoInformation)
        ProgressHUD.setDefaultPosition(.center)
        ProgressHUD.setDefaultStyle(.light)
        ProgressHUD.setDismissable(false)
        ProgressHUD.setSpinnerSize(32.0)
        ProgressHUD.setOpacity(0.75)
        
        var errorThrown = false

        ProgressHUD.show(withStatus: BridgeSetupControllerHUD.readingConfigurationFile.description)
        WeatherPlatform.initializeBridgeSpecification(ipAddress: bridgeIP.stringValue, bridgeName: bridgeName.stringValue, callback: { [unowned self] response, error in
            if error == nil {
                theDelegate!.theBridge = response                                           // Bridge was successfully initialized from the json description
                guard let theBridge = theDelegate!.theBridge else {                         // Cheksum that we're good to go
                    log.error(BridgeSetupControllerError.noBridge)                          // Warn the user - something is not right
                    self.dismissHUD()
                    return                                                                  // Bail gracefully
                }
                ProgressHUD.show(withStatus: BridgeSetupControllerHUD.pollingForSystemParameters.description)
                theBridge.getAllSystemParameters { [unowned self] (_ , error: Error?) in    // Get All the System Paramaters that this Meteobridge Supports
                    if error == nil {                                                       // Any errors?
                        ProgressHUD.show(withStatus: BridgeSetupControllerHUD.settingUpWeatherModels.description)
                        theBridge.updateWeatherModel { (_ , error: Error?) in               // Try to populate the weather model for forecasts/alerts/warnings
                            if error != nil {
                                log.error(error.value)                                      // Warn the user that we're unable to update the model
                            }                                                               // We still want to continue though ...
                            ProgressHUD.show(withStatus: BridgeSetupControllerHUD.gettingObservation.description)
                            theBridge.getObservation(allParams: true, { (error: Error?) in         // Get a "FULL" observation so we can see what's going on outside
                                if error == nil {
                                    guard let sensorUL = theDelegate!.theBridge?.findSensor(sensorName: (theDelegate?.theDefaults!.compassULSensor)!) else {
                                        log.warning("Cannot find Senor[\(theDelegate?.theDefaults!.compassULSensor ?? "")]: to observe.")
                                        self.dismissHUD()
                                        return
                                    }
                                    sensorUL.isObserving = true
                                    
                                    guard let sensorUR = theDelegate!.theBridge?.findSensor(sensorName: (theDelegate?.theDefaults!.compassURSensor)!) else {
                                        log.warning("Cannot find Senor[\(theDelegate?.theDefaults!.compassURSensor ?? "")]: to observe.")
                                        self.dismissHUD()
                                        return
                                    }
                                    sensorUR.isObserving = true
                                    
                                    guard let sensorLL = theDelegate!.theBridge?.findSensor(sensorName: (theDelegate?.theDefaults!.compassLLSensor)!) else {
                                        log.warning("Cannot find Senor[\(theDelegate?.theDefaults!.compassLLSensor ?? "")]: to observe.")
                                        self.dismissHUD()
                                        return
                                    }
                                    sensorLL.isObserving = true
                                    
                                    guard let sensorLR = theDelegate!.theBridge?.findSensor(sensorName: (theDelegate?.theDefaults!.compassLRSensor)!) else {
                                        log.warning("Cannot find Senor[\(theDelegate?.theDefaults!.compassLRSensor ?? "")]: to observe.")
                                        self.dismissHUD()
                                        return
                                    }
                                    sensorLR.isObserving = true
                                    
                                    guard let sensorWind = theDelegate!.theBridge?.findSensor(sensorName: ("wind0dir")) else {
                                        log.warning("Cannot find Senor[wind0dir]: to observe.")
                                        self.dismissHUD()
                                        return
                                    }
                                    sensorWind.isObserving = true
                                    
                                    theDelegate?.updateBridge()                 // Save our new bridge for the rest of the system to use
                                    self.updateBridgeMetadata()                 // We have everything we need; update the display
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "BridgeInitialized"), object: nil, userInfo: nil)
                                } else {
                                    log.error(error.value)  // Error with getObservation
                                    self.dismissHUD()
                                    return
                                }
                            })
                        }
                    } else {
                        if !errorThrown {
                            errorThrown = true
                            log.error(error.value)  // Error with allSystemParamaters
                            self.dismissHUD()
                            
                            let alert = NSAlert()
                            alert.messageText = "MeteoBar is unable to conenct to your Meteobridge"
                            alert.informativeText = "The request timed out"
                            alert.alertStyle = .critical
                            alert.addButton(withTitle: "Ok")
                            alert.beginSheetModal(for: self.view.window!) { (_ returnCode: NSApplication.ModalResponse) -> Void in
                                theDelegate?.theBridge = nil
                                theDelegate?.updateBridge()
                                return
                            }
                        }
                    }
                }
            } else {
                if !errorThrown {
                    errorThrown = true
                    log.error(error.value)  // Error with initializeBridgeSpecification
                    self.dismissHUD()
                    
                    let alert = NSAlert()
                    alert.messageText = "MeteoBar is unable to initialize the Meteobridge model"
                    alert.informativeText = "There is an error in the Meteobridge.json file"
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "Ok")
                    alert.beginSheetModal(for: self.view.window!) { (_ returnCode: NSApplication.ModalResponse) -> Void in
                        theDelegate?.theBridge = nil
                        theDelegate?.updateBridge()
                        return
                    }
                }
            }
        })
    }
    
    /// Quick helper to dismiss the HUD if it's visible
    ///
    /// Dismiss our HUD if it's showing
    ///
    fileprivate func dismissHUD() {
        if ProgressHUD.isVisible() {
            ProgressHUD.dismiss(delay: 1.0)
        }
        // Dismiss our HUD if it's showing
    }
    
    // MARK: - Actions
    @IBAction func mapZoomClicked(_ sender: Any) {
        guard let theBridge = theDelegate?.theBridge! else {
            log.error(BridgeSetupControllerError.noBridge)
            return
        }
        mapView.zoomToPoint(toCenterCoordinate: theBridge.coordinate, zoomLevel: 90)
    }
    
    /// Toggle the forecast Polygon
    ///
    /// - Parameter sender: OGSwitch that sent the action
    ///
    @IBAction func forecastSwitchClicked(_ sender: Any) {
        guard let theBridge = theDelegate?.theBridge! else {
            log.error(BridgeSetupControllerError.noBridge)
            return
        }

        switch forecastSwitch.isOn {
        case false: // We want to turn-off the forecast overlays
            for mapOverlay in mapView.overlays {
                switch mapOverlay {
                case is MKMeteoPolyline:    // Turn off the polyline
                    if (mapOverlay as? MKMeteoPolyline)?.lineName == "Forecast" {
                        mapView.removeOverlay(mapOverlay)
                        for (type, polyline) in theBridge.polygonOverlays {
                            switch type {
                            case "County":  // But we want to ensure the remaining polygon has an outline
                                polyline.lineName = type
                                self.mapView.addOverlay(polyline)
                            default:
                                break
                            }
                        }
                    }
                case is MKMeteoPolygon:     // Turn off the polygon
                    if (mapOverlay as? MKMeteoPolygon)?.polyName == "Forecast" {
                        mapView.removeOverlay(mapOverlay)
//                        print("Removing Forecast Polygon")
                    }
                default:
                    break
                }
            }
        case true:
            guard let theBridge = theDelegate?.theBridge! else {
                log.error(BridgeSetupControllerError.noBridge)
                break
            }
            for (type, polyline) in theBridge.polygonOverlays {
                switch type {
                case "Forecast":
                    let polygon = MKMeteoPolygon(coordinates: polyline.coordinates, count: polyline.pointCount)
                    polygon.polyName = type
                    polyline.lineName = type
                    self.mapView.addOverlay(polyline)
                    self.mapView.addOverlay(polygon)
//                    print ("Adding forecast overlays")
                default:
                    break
                }
            }
        }
    }
    
    /// Toggle the county Polygon
    ///
    /// - Parameter sender: OGSwitch that sent the action
    ///
    @IBAction func countySwitchClicked(_ sender: Any) {
        guard let theBridge = theDelegate?.theBridge! else {
            log.error(BridgeSetupControllerError.noBridge)
            return
        }
        
        switch countySwitch.isOn {
        case false: // We want to turn-off the forecast overlays
            for mapOverlay in mapView.overlays {
                switch mapOverlay {
                case is MKMeteoPolyline: // Turn off the polyline
                    if (mapOverlay as? MKMeteoPolyline)?.lineName == "County" {
                        mapView.removeOverlay(mapOverlay)
                        for (type, polyline) in theBridge.polygonOverlays {
                            switch type {
                            case "Forecast":    // But we want to ensure the remaining polygon has an outline
                                polyline.lineName = type
                                self.mapView.addOverlay(polyline)
                            default:
                                break
                            }
                        }
                    }
                case is MKMeteoPolygon:     // Turn off the polygon
                    if (mapOverlay as? MKMeteoPolygon)?.polyName == "County" {
                        mapView.removeOverlay(mapOverlay)
//                        print("Removing Forecast Polygon")
                    }
                default:
                    break
                }
            }
        case true:
            guard let theBridge = theDelegate?.theBridge! else {
                log.error(BridgeSetupControllerError.noBridge)
                break
            }
            for (type, polyline) in theBridge.polygonOverlays {
                switch type {
                case "County":
                    let polygon = MKMeteoPolygon(coordinates: polyline.coordinates, count: polyline.pointCount)
                    polygon.polyName = type
                    polyline.lineName = type
                    self.mapView.addOverlay(polyline)
                    self.mapView.addOverlay(polygon)
//                    print ("Adding county overlays")
                default:
                    break
                }
            }
        }
    }
    
    /// Toggle the alert Polygon
    ///
    /// - Parameter sender: OGSwitch that sent the action
    ///
    @IBAction func alertSwicthClicked(_ sender: Any) {
    
    }
    
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
                    self.initializeBridge()
                default:
                    break
                }
            }
        } else {    // We're good ... no previous bridge
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case is MKMeteoPolyline:
            let renderer = MKPolylineRenderer(overlay: overlay)

            renderer.lineWidth = 3.0
            switch (overlay as? MKMeteoPolyline)!.lineName {
            case "Forecast":
                renderer.strokeColor = NSColor.blue
//                print("Forecast Polyline")
            case "County":
                renderer.strokeColor = NSColor.green
 //               print("County Polyline")
            case "Alert":
                renderer.strokeColor = NSColor.red
//                print("Alert Polyline")
            default:
                break
            }
            return renderer
        case is MKMeteoPolygon:
            let renderer = MKPolygonRenderer(overlay: overlay)
            
            switch (overlay as? MKMeteoPolygon)!.polyName {
            case "Forecast":
                renderer.fillColor = NSColor.blue.withAlphaComponent(0.25)
//                print("Forecast Polygon")
            case "County":
                renderer.fillColor = NSColor.green.withAlphaComponent(0.25)
//                print("County Polygon")
            case "Alert":
                renderer.fillColor = NSColor.red.withAlphaComponent(0.25)
//                print("Alert Polygon")
            default:
                break
            }
            return renderer
        default:
            return MKOverlayRenderer()
        }
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

/// Helper class to add a name property to identfy different polygons
class MKMeteoPolygon: MKPolygon {
    var polyName: String = ""
}
