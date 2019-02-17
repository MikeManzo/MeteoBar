//
//  SensorCollectionItemController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/27/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

class SensorCollectionItemController: NSCollectionViewItem {

    @IBOutlet weak var sensorImage: NSImageView!
    @IBOutlet weak var sensorDescription: NSTextField!
    @IBOutlet weak var sensorUnits: NSPopUpButton!
    @IBOutlet weak var sensorBattery: NSImageView!
    @IBOutlet weak var sensorOn: NSButton!
    
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
                sensorOn.state = sensor.isObserving ? .on : .off
                // Update the status of the sensor (e.g., is it observing or not?)
            } else {
                sensorDescription.stringValue = ""
                sensorUnits.removeAllItems()
                sensorImage?.image  = nil
                sensorImage.toolTip = ""
            }
        }
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
    /// 1.
    /// 2.
    /// 3.
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
    /// 1.
    /// 2.
    /// 3.
    ///
    override var isSelected: Bool {
        didSet {
            view.layer?.borderWidth = isSelected ? 2.0 : 0.0
        }
    }
    
    @IBAction func observingStateChanged(_ sender: Any) {
        guard let sensor = WeatherPlatform.findSensorInBridge(searchID: imageFile!.sensorID!) else {
            log.warning("Unable to find a sensor with ID:\(imageFile!.sensorID!)")
            return
        }
        
        sensor.isObserving = (sensorOn.state == .on) ? true : false
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
