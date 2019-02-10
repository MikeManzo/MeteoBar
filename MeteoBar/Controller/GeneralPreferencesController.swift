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
    
    var categories = [SensorCat]()
    
    // MARK: - Outlets
    @IBOutlet weak var sensorTree: NSOutlineView!
    
    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "GeneralPreferences"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for (category, _) in (theDelegate?.theBridge?.sensors)! {
            categories.append(SensorCat(sensorCat: category, sensors: (theDelegate?.theBridge?.sensors[category])!))
        }
        sensorTree.reloadData()
    }
}

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

extension GeneralPreferencesController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, shouldShowCellExpansionFor tableColumn: NSTableColumn?, item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return true
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
      
        if let category = item as? SensorCat {
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
            
        } else if let sensor = item as? MeteobridgeSensor {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorView"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = sensor.information
                textField.toolTip = sensor.information
            }
        } else {
            log.error("Unknown type item=\(item)")
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
        print("Sensor[\(sensor.name)] selected")
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
