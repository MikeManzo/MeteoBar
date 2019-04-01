//
//  SensorCollectionItemController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/27/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

enum SensorCollectionItemControllerInfo: String, CustomStringConvertible {
    case sensorIsAvailable
    case sensorIsNotAvailable
    
    var description: String {
        switch self {
        case .sensorIsAvailable: return "Sensor is reporting to the meteobridge"
        case .sensorIsNotAvailable: return "Sensor is not reporting to the meteobridge"
        }
    }
}

class SensorCollectionItemController: NSCollectionViewItem {

    @IBOutlet weak var sensorImage: NSImageView!
    @IBOutlet weak var sensorAvailability: NSImageView!
    @IBOutlet weak var sensorDescription: NSTextField!
    @IBOutlet weak var sensorUnits: NSPopUpButton!
    @IBOutlet weak var sensorBattery: NSImageView!
    @IBOutlet weak var sensorToggle: OGSwitch!

    /// Pretty much the mac-Daddy of a variable.  Once set ... it sets up the whole Item for display
    weak var imageFile: MeteoSensorImage? = nil {
        didSet {
            guard isViewLoaded else {   // Bail if there is no view loaded ...
                return
            }
            // Update the thumbnail
            if let imageFile = imageFile {
                sensorImage!.image = imageFile.thumb
                if theDelegate!.isVibrantMode() {
                    let filter = CIFilter(name: "CIColorInvert")
                    sensorImage?.contentFilters = ([filter] as? [CIFilter])!
                }
                
                // Populate the Popup with the available units & select the unit currently collecting
                guard let sensor = WeatherPlatform.findSensorInBridge(searchID: imageFile.sensorID!) else {
                    log.warning("Unable to find a sensor with ID:\(imageFile.sensorID!)")
                    return
                }
                sensorUnits.removeAllItems()
                for unit in sensor.supportedUnits {
                    sensorUnits.addItem(withTitle: unit.name)
                    if unit.isCurrent {
                      sensorUnits.selectItem(withTitle: unit.name)
                    }
                }
                // Populate the Popup with the available units & select the unit currently collecting

                // Update the battery status
                switch sensor.batteryStatus {
                case .good:
                    sensorBattery.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "full-battery.png")!.filter(filter: "CIColorInvert") :
                        NSImage(named: "full-battery.png")
                case .low:
                    sensorBattery.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "empty-battery.png")!.filter(filter: "CIColorInvert") :
                        NSImage(named: "empty-battery.png")
                case .unknown:
                    sensorBattery.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "no-battery.png")!.filter(filter: "CIColorInvert") :
                        NSImage(named: "no-battery.png")
                }
                // Update the battery status

                // Update the description tooltips
                sensorDescription.stringValue = imageFile.label!
                self.view.toolTip = ("Sensor: " + imageFile.sensorID! + "\n" + "Description: " + imageFile.theDescription!)
                // Update the description tooltips
                
                // Update the status of the sensor (e.g., is it observing or not?)
                sensorToggle.setOn(isOn: sensor.isObserving ? true : false, animated: true)
                // Update the status of the sensor (e.g., is it observing or not?)
                
                // Update the sensor availability
                updateSensorAvailability(sensor: sensor)
                // Update the sensor availability
            } else {
                sensorDescription.stringValue = ""
                sensorUnits.removeAllItems()
                sensorImage?.image  = nil
                sensorImage.toolTip = ""
            }
        }
    }
    
    /// Helper function to set availability
    ///
    /// - Parameter sensor: sensor to check
    ///
    private func updateSensorAvailability(sensor: MeteobridgeSensor?) {
        guard sensor != nil else {
            return
        }
        
        sensorAvailability.image = sensor!.isAvailable ? NSImage(named: NSImage.statusAvailableName) : NSImage(named: NSImage.statusUnavailableName)
        sensorAvailability.toolTip = sensor!.isAvailable ? SensorCollectionItemControllerInfo.sensorIsAvailable.description:
                                                           SensorCollectionItemControllerInfo.sensorIsNotAvailable.description
    }
    
    /// Just some perfunctary setup for a better viewing experience
    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer                 = true
        view.layer?.backgroundColor     = NSColor.controlBackgroundColor.cgColor
        view.layer?.borderColor         = NSColor.systemBlue.cgColor
        view.layer?.borderWidth         = 0.0
    }
    
    ///
    /// Set the highlight box when selected
    ///
    /// ## Important Notes ##
    /// 1. None
    ///
    /// - parameters:
    ///   - selected: boolean for whether the item has been selected
    /// - throws: Nothing
    /// - returns: Nothing
    ///
    func setHighlight(selected: Bool) {
        view.layer?.borderWidth = selected ? 2.0 : 0.0
    }
    
    ///
    /// Set the highlight box when selected
    ///
    /// ## Important Notes ##
    /// 1. None
    ///
    override var isSelected: Bool {
        didSet {
            view.layer?.borderWidth = isSelected ? 2.0 : 0.0
        }
    }

    /// Toggle the observing state for teh sensor
    /// The platform will try to get a valied measurement before it turns on
    /// If no valid data, it stays off
    ///
    /// - Parameter sender: OGwitch that sent the state change

    @IBAction func observingStateToggle(_ sender: Any) {
        guard imageFile != nil else {
            log.error("An error has occured trying to turn this sensor on.")
            return
        }
        
        guard let sensor = WeatherPlatform.findSensorInBridge(searchID: imageFile!.sensorID!) else {
            log.warning("Unable to find a sensor with ID:\(imageFile!.sensorID!)")
            return
        }
        
//        updateSensorAvailability(sensor: sensor)
        
        // Quick check ... is the sensor available and simply off (or on?)
        if sensor.isAvailable {
            sensor.isObserving = sensorToggle.isOn ? true : false
        } else {    // The sensor is reporting as not available ... let's see if things have changed - try again.
            if sensorToggle.isOn { // Okay; thse toggle was off, the user tried to switch it on AND the sensor was reporting as not available ... try to get some data
                let alert = NSAlert()
                alert.messageText = "This sensor is not available or not reporting."
                alert.informativeText = "Do you want to see if it is available and reporting?"
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
                        theDelegate?.theBridge?.getObservation(sensor: sensor, { [unowned self] error in // Call the bridge and see if anything has changed
                            if error != nil {
                                return
                            }
                            guard let updatedSensor = WeatherPlatform.findSensorInBridge(searchID: sensor.sensorID) else {
                                return
                            }
                            
                            if !updatedSensor.isAvailable { // Okay, we have a new sensor ... let's check
                                let subAlert = NSAlert()
                                subAlert.messageText = "Sensor: \(sensor.sensorID) is still not responding."
                                subAlert.informativeText = "Please check that your Meteobridge is configured correctly."
                                subAlert.alertStyle = .critical
                                subAlert.addButton(withTitle: "Ok")
                                subAlert.beginSheetModal(for: self.view.window!) { [unowned self] (_ subReturnCode: NSApplication.ModalResponse) -> Void in
                                    switch subReturnCode {
                                    case .alertFirstButtonReturn:
                                        self.sensorToggle.setOn(isOn: false, animated: true)
                                    default:
                                        break
                                    }
                                }
                            } else {    // It's reporting as availble now ... proceed
                                self.updateSensorAvailability(sensor: updatedSensor)
                            }
                        })
                    default:
                        break
                    }
                }
            }
        }
    }
    
    /// Update the sensor with the selected unit
    ///
    /// - Parameter sender: NSPopUpButton that has changed
    ///
    @IBAction func unitChanged(_ sender: NSPopUpButton) {
        guard let sensor = WeatherPlatform.findSensorInBridge(searchID: imageFile!.sensorID!) else {
            log.warning("Unable to find a sensor with ID:\(imageFile!.sensorID!)")
            return
        }
        
        if let error = sensor.setCurrentUnit(stringUnit: (sender.selectedItem?.title)!) {
            log.error(error.localizedDescription)
        } else {
            log.info("Sensor:\(imageFile?.sensorID ?? "UNKNOWN") colelction unit has changed to: \(sender.selectedItem?.title ?? "UNKNOWN")")
        }
    }
}

///
/// Custom class to vertically center the tet in a label (NSTextFieldCell)
///
/// ## Important Notes ##
/// None
///
/// ## Parameters ##
/// None
/// - throws: Nothing
/// - returns: Nothing
///
class VerticallyCenteredTextFieldCell: NSTextFieldCell {
    override func titleRect(forBounds rect: NSRect) -> NSRect {
        var titleRect = super.titleRect(forBounds: rect)
        
        let minimumHeight = self.cellSize(forBounds: rect).height
        titleRect.origin.y += (titleRect.height - minimumHeight) / 2
        titleRect.size.height = minimumHeight
        
        return titleRect
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: titleRect(forBounds: cellFrame), in: controlView)
    }
}
