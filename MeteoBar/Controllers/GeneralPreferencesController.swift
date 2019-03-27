//
//  GeneralPreferencesController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/26/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa
import Preferences

class GeneralPreferencesController: NSViewController, Preferenceable {
    // MARK: - Protocol Variables
    let toolbarItemTitle = "General"
    let toolbarItemIcon = NSImage(named: NSImage.advancedName)!
    
    var tableViewCellForSizing: NSTableCellView?
    var categories = [SensorCat]()
    
    // MARK: - Outlets
    @IBOutlet weak var sensorTree: NSOutlineView!
    @IBOutlet weak var updateInterval: NSPopUpButton!
    @IBOutlet weak var alertUpdateInterval: NSPopUpButton!
    @IBOutlet weak var alertIntervalLabel: NSTextField!
    @IBOutlet weak var weatherAlerts: NSButton!
    
    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "GeneralPreferences"
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        /// Do we have a valid meteobridge?
        if theDelegate?.theBridge != nil {  // Yes ... setup the model
            for (category, _) in (theDelegate?.theBridge?.sensors)! {   // Create a simple model for our OutlineView
//                categories.append(SensorCat(sensorCat: category, sensors: (theDelegate?.theBridge?.sensors[category])!))
                let sensorCat = SensorCat(sensorCat: category, sensors: (theDelegate?.theBridge?.sensors[category])!)
                sensorCat.sensors.sort {
                    $0.information < $1.information
                }
                categories.append(sensorCat)
            }
            sensorTree.headerView = nil     // Default (no meteobridge) is a header that says "Meteobridge Not Yet Configured"
            categories.sort {               // Sort the model alphabetically
                $0.cat.rawValue < $1.cat.rawValue
            }
            sensorTree.reloadData()         // Reload the OutlineView
            if !(theDelegate?.theDefaults?.menubarSensor.isEmpty)! {    // Select the current sensor that is reporting to the menubar
                guard let sensor = WeatherPlatform.findSensorInBridge(searchID: (theDelegate?.theDefaults?.menubarSensor)!) else {
                    return
                }
                let sensorCat = categories.filter { // Get the category
                    $0.cat == sensor.category}.first
                sensorTree.expandItem(sensorCat, expandChildren: true)  // Epand the tree
                let rowIndex = sensorTree.row(forItem: sensor)  // Now: Annoyingly, the outline won't find rows unless they are expanded
                sensorTree.selectRowIndexes(IndexSet(integer: rowIndex), byExtendingSelection: true) // Select the c
                sensorTree.scrollRowToVisible(rowIndex)
            }
        }
        
        // Update view based on defaults
        if theDelegate?.theBridge != nil {
            updateInterval.isEnabled = true
            alertUpdateInterval.isEnabled = true
            updateInterval.setTitle((theDelegate?.theBridge?.updateInterval.description)!)
            
            let minutes = ((theDelegate?.theBridge?.alertUpdateInterval)!) / 60
            alertUpdateInterval.setTitle(minutes.description)
            
            if minutes == 1 {
                alertIntervalLabel.stringValue = "minute"
            } else {
                alertIntervalLabel.stringValue = "minutes"
            }
        } else {
            updateInterval.isEnabled = false
            alertUpdateInterval.isEnabled = false
        }
        weatherAlerts.state = (theDelegate?.theDefaults?.weatherAlerts)! ? .on : .off
        // Update view based on defaults
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        categories.removeAll()
        
        if theDelegate?.theBridge != nil {
            theDelegate?.theBridge?.updateInterval = Int(updateInterval.titleOfSelectedItem!)!
            theDelegate?.theBridge?.alertUpdateInterval = Int(alertUpdateInterval.titleOfSelectedItem!)! * 60
        }
        theDelegate?.theDefaults?.weatherAlerts = (weatherAlerts.state == .on) ? true : false
        
        theDelegate?.updateMeteoBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewCellForSizing = sensorTree.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorView"), owner: self) as? NSTableCellView
        tableViewCellForSizing?.textField?.preferredMaxLayoutWidth = 132
    }
    @IBAction func alertIntervalChanged(_ sender: Any) {
        switch alertUpdateInterval.titleOfSelectedItem {
        case "1":
            alertIntervalLabel.stringValue = "minute"
        default:
            alertIntervalLabel.stringValue = "minutes"
        }
    }
}

/// We are the data delegate ... let's setup the model to be the data-pump
extension GeneralPreferencesController: NSOutlineViewDataSource {
    // Tell how many children each row has:
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let category = item as? SensorCat {
            return category.sensors.count
        }
        return categories.count
    }
    
    // Give each row a unique identifier, referred to as `item` by the outline view
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let category = item as? SensorCat {
            return category.sensors[index]
        }
        return categories[index]
    }
    
    // Tell us whether the row is expandable
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let categoty = item as? SensorCat {
            return (categoty.sensors.count) > 0
        }
        return false
    }
}

/// We are the view delegate ... let's setup the view to consume the model data
extension GeneralPreferencesController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, shouldShowCellExpansionFor tableColumn: NSTableColumn?, item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem: Any) -> Bool {
        return true
    }

    /// Auto height for Row
    ///
    /// - Parameters:
    ///   - outlineView: our outlineView
    ///   - item: the item in question (we only want sensors)
    /// - Returns: height of row
    ///
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let tableCellView = tableViewCellForSizing else { return 17 }
        
        switch item {
        case is MeteobridgeSensor:
            let strokeTextAttributes: [NSAttributedString.Key: Any]?
            strokeTextAttributes = [
                .strokeColor: NSColor.controlTextColor,
                .foregroundColor: NSColor.controlTextColor,
                .strokeWidth: -2.0,
                .font: NSFont.systemFont(ofSize: NSFont.Weight.regular.rawValue)
            ]
            tableCellView.textField?.attributedStringValue = NSAttributedString(string: (item as? MeteobridgeSensor)!.information, attributes: strokeTextAttributes)
        default:
            break
        }
        if let height = tableCellView.textField?.fittingSize.height, height > 0 {
            return height
        }
        
        return 17 // <-- Defult height for system font of regular value
    }
    
    /// Customize the view for presentation
    /// [Reference](https://stackoverflow.com/questions/40338563/nstablecellview-imageview-is-null)
    ///
    /// - Parameters:
    ///   - outlineView: our control
    ///   - tableColumn: the column in question (for this, it's one)
    ///   - item: what item are we dealing with?
    /// - Returns: a full-formed view (or nil if a failure has occured)
    ///
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
      
        if let category = item as? SensorCat {  // Show the categories (individual roots)
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CategoryView"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = category.name
                
                switch category.cat {
                case .energy:
                    view?.imageView?.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "energy.png")!.filter(filter: "CIColorInvert") : NSImage(named: "energy.png")
                case .humidity:
                    view?.imageView?.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "humidity.png")!.filter(filter: "CIColorInvert") : NSImage(named: "humidity.png")
                case .pressure:
                    view?.imageView?.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "pressure.png")!.filter(filter: "CIColorInvert") : NSImage(named: "pressure.png")
                case .rain:
                    view?.imageView?.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "drop.png")!.filter(filter: "CIColorInvert") : NSImage(named: "drop.png")
                case .solar:
                    view?.imageView?.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "solar-energy.png")!.filter(filter: "CIColorInvert") : NSImage(named: "solar-energy.png")
                case .temperature:
                    view?.imageView?.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "thermometer.png")!.filter(filter: "CIColorInvert") : NSImage(named: "thermometer.png")
                case .wind:
                    view?.imageView?.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "wind-sock.png")!.filter(filter: "CIColorInvert") : NSImage(named: "wind-sock.png")
                case .system, .unk:
                    break
                }
            }
        } else if let sensor = item as? MeteobridgeSensor { // Show the sensors ... the brances of the roots
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorView"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                //textField.stringValue = sensor.information

                if sensor.isObserving {
                    view?.imageView!.image = NSImage(named: NSImage.statusAvailableName)
                    view?.imageView?.toolTip = "Sensor is observing"
                } else {
                    view?.imageView!.image = NSImage(named: NSImage.statusUnavailableName)
                    view?.imageView?.toolTip = "Check Bridge config: Sensor is not observing"
                }
                
                let strokeTextAttributes: [NSAttributedString.Key: Any]?
                if sensor.name == theDelegate?.theDefaults?.menubarSensor {
                    strokeTextAttributes = [
                        .strokeColor: NSColor.controlTextColor,
                        .foregroundColor: NSColor.controlTextColor,
                        .strokeWidth: -2.0,
                        .font: NSFont.systemFont(ofSize: NSFont.Weight.regular.rawValue).setBoldandItalics()
                    ]
                } else {
                    strokeTextAttributes = [
                        .strokeColor: NSColor.controlTextColor,
                        .foregroundColor: NSColor.controlTextColor,
                        .strokeWidth: -2.0,
                        .font: NSFont.systemFont(ofSize: NSFont.Weight.regular.rawValue)
                    ]
                }
                textField.attributedStringValue = NSAttributedString(string: sensor.information, attributes: strokeTextAttributes)
                textField.toolTip = sensor.information
            }
        } else {
            log.error("SensorTree: Unknown type[\(item)]")
        }
        
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let outlineView = notification.object as? NSOutlineView else {
            return
        }
        
        let selectedIndex = outlineView.selectedRow
        guard let sensor = outlineView.item(atRow: selectedIndex) as? MeteobridgeSensor else {
            return
        }
        theDelegate?.theDefaults?.menubarSensor = sensor.name
    }
}

/// Quick model for the NSOutlineView
class SensorCat: NSObject {
    var sensors = [MeteobridgeSensor]()
    var cat: MeteoSensorCategory
    var name: String
    
    init(sensorCat: MeteoSensorCategory, sensors: [MeteobridgeSensor]) {
        self.name       = sensorCat.rawValue
        self.cat        = sensorCat
        self.sensors    = sensors
    }
}
