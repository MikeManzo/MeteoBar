//
//  UserInterfaceController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 2/17/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Preferences
import SpriteKit
import Cocoa

protocol CompassDelegate: class {
    func updateCompass(caller: UITableCellView)
}

class UserInterfaceController: NSViewController, CompassDelegate, Preferenceable {
    // MARK: - Protocol Variables
    let toolbarItemTitle = "User Interface"
    let toolbarItemIcon = NSImage(named: "dashboard.png")!

    // MARK: Outlets
    @IBOutlet weak var elementTree: NSOutlineView!
    @IBOutlet weak var compassView: MeteoCompassView!
    
    // MARK: Properties
    var categories = [InterfaceCategory]()
    
    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "UserInterface"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        if theDelegate?.theBridge != nil {  // Yes ... setup the model
            var elements = [InterfaceElement]()
            
            elements.append(InterfaceElement(name: "Cardinal Minor Tick", color: (theDelegate?.theDefaults!.compassCardinalMinorTickColor)!))
            elements.append(InterfaceElement(name: "Cardinal Major Tick", color: (theDelegate?.theDefaults!.compassCardinalMajorTickColor)!))
            elements.append(InterfaceElement(name: "Crosshairs", color: (theDelegate?.theDefaults!.compassCrosshairColor)!))
            elements.append(InterfaceElement(name: "Compass Frame", color: (theDelegate?.theDefaults!.compassFrameColor)!))
            elements.append(InterfaceElement(name: "Compass Carat", color: (theDelegate?.theDefaults!.compassCaratColor)!))
            elements.append(InterfaceElement(name: "Major Sensor Text", color: (theDelegate?.theDefaults!.compassSensorMajorColor)!))
            elements.append(InterfaceElement(name: "Minor Sensor Text", color: (theDelegate?.theDefaults!.compassSensorMinorColor)!))
            elements.append(InterfaceElement(name: "Major Cardinal Text", color: (theDelegate?.theDefaults!.compassCardinalMajorColor)!))
            elements.append(InterfaceElement(name: "Minor Cardinal Text", color: (theDelegate?.theDefaults!.compassCardinalMinorColor)!))
            elements.append(InterfaceElement(name: "Compass Ring", color: (theDelegate?.theDefaults!.compassRingColor)!))
            elements.append(InterfaceElement(name: "Compass Face", color: (theDelegate?.theDefaults!.compassFaceColor)!))
            
            categories.append(InterfaceCategory(category: "Compass Configuration", elements: elements))
            categories.sort {               // Sort the model alphabetically
                $0.name < $1.name
            }
            elementTree.reloadData()         // Reload the OutlineView
            elementTree.expandItem(nil, expandChildren: true)
        }
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        categories.removeAll()
        
        if theDelegate?.theBridge != nil {
            theDelegate?.updateConfiguration()
        }
    }
    
    func updateCompass(caller: UITableCellView) {
        compassView.update()
    }
}

/// We are the data delegate ... let's setup the model to be the data-pump
extension UserInterfaceController: NSOutlineViewDataSource {
    // Tell how many children each row has:
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let category = item as? InterfaceCategory {
            return category.elements.count
        }
        return categories.count
    }
    
    // Give each row a unique identifier, referred to as `item` by the outline view
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let category = item as? InterfaceCategory {
            return category.elements[index]
        }
        return categories[index]
    }
    
    // Tell us whether the row is expandable
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let categoty = item as? InterfaceCategory {
            return (categoty.elements.count) > 0
        }
        return false
    }
}

/// We are the view delegate ... let's setup the view to consume the model data
extension UserInterfaceController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, shouldShowCellExpansionFor tableColumn: NSTableColumn?, item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem: Any) -> Bool {
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
        
        if let category = item as? InterfaceCategory {  // Show the categories (individual roots)
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CategoryView"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = category.name
                
            }
        } else if let element = item as? InterfaceElement { // Show the UI Elements to configure ... the brances of the roots
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ElementView"), owner: self) as? UITableCellView
            if let textField = view?.textField {
                textField.stringValue = element.name
                (view as? UITableCellView)!.colorWell.color     = element.color
                (view as? UITableCellView)!.colorWell.element   = element
                (view as? UITableCellView)!.compassDelegate     = self
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
        guard let element = outlineView.item(atRow: selectedIndex) as? InterfaceElement else {
            return
        }
        
        print(element)
    }
}

/// Quick model for the NSOutlineView
class InterfaceElement: NSObject {
    var name: String
    var color: SKColor
    
    init(name: String, color: SKColor) {
        self.name   = name
        self.color  = color
    }
}

class InterfaceCategory: NSObject {
    var elements = [InterfaceElement]()
    var name: String
    
    init(category: String, elements: [InterfaceElement]) {
        self.name       = category
        self.elements   = elements
    }
}
/// Quick model for the NSOutlineView

// Quick Subclass to get acces to the colorwell in our NSTableCellView
class InterfaceColorWell: NSColorWell {
    private var _element: InterfaceElement?
    
    var element: InterfaceElement? {
        get {
            return _element
        }
        set {
            _element = newValue
        }
    }
}

class UITableCellView: NSTableCellView {
    @IBOutlet weak var colorWell: InterfaceColorWell!
    
    weak var compassDelegate: CompassDelegate?
    
    @IBAction func colorWellChanged(_ sender: InterfaceColorWell) {
        switch sender.element?.name {
        case "Cardinal Minor Tick":
            theDelegate?.theDefaults!.compassCardinalMinorTickColor = sender.color
        case "Cardinal Major Tick":
            theDelegate?.theDefaults!.compassCardinalMajorTickColor = sender.color
        case "Crosshairs":
            theDelegate?.theDefaults!.compassCrosshairColor = sender.color
        case "Compass Frame":
            theDelegate?.theDefaults!.compassFrameColor = sender.color
        case "Compass Carat":
            theDelegate?.theDefaults!.compassCaratColor = sender.color
        case "Major Sensor Text":
            theDelegate?.theDefaults!.compassSensorMajorColor = sender.color
        case "Minor Sensor Text":
            theDelegate?.theDefaults!.compassSensorMinorColor = sender.color
        case "Major Cardinal Text":
            theDelegate?.theDefaults!.compassCardinalMajorColor = sender.color
        case "Minor Cardinal Text":
            theDelegate?.theDefaults!.compassCardinalMinorColor = sender.color
        case "Compass Ring":
            theDelegate?.theDefaults!.compassRingColor = sender.color
        case "Compass Face":
            theDelegate?.theDefaults!.compassFaceColor = sender.color
        default:
            break
        }
        theDelegate?.updateConfiguration()
        if compassDelegate != nil {
            compassDelegate?.updateCompass(caller: self)
        }
    }
}
// Quick Subclass to get acces to the colorwell in our NSTableCellView
