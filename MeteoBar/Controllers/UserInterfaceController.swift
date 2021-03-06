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

class UserInterfaceController: NSViewController, CompassDelegate, PreferencePane {
    // MARK: - Protocol Variables
    let preferencePaneTitle = "User Interface"
    let toolbarItemIcon = NSImage(named: "dashboard.png")!
    let preferencePaneIdentifier = PreferencePane.Identifier.interafce

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
        
        preferredContentSize    = NSSize(width: 704, height: 440)      // Set the size of our view
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        if theDelegate?.theBridge != nil {  // Yes ... setup the model
            var elements = [InterfaceElement]()
            
            elements.append(InterfaceElement(name: "Cardinal 'Minor' Tick", color: (theDelegate?.theDefaults!.compassCardinalMinorTickColor)!))
            elements.append(InterfaceElement(name: "Cardinal 'Major' Tick", color: (theDelegate?.theDefaults!.compassCardinalMajorTickColor)!))
            elements.append(InterfaceElement(name: "Crosshairs", color: (theDelegate?.theDefaults!.compassCrosshairColor)!))
            elements.append(InterfaceElement(name: "Compass Frame", color: (theDelegate?.theDefaults!.compassFrameColor)!))
            elements.append(InterfaceElement(name: "Compass Carat", color: (theDelegate?.theDefaults!.compassCaratColor)!))
            elements.append(InterfaceElement(name: "Major Sensor Text", color: (theDelegate?.theDefaults!.compassSensorMajorColor)!))
            elements.append(InterfaceElement(name: "Minor Sensor Text", color: (theDelegate?.theDefaults!.compassSensorMinorColor)!))
            elements.append(InterfaceElement(name: "Cardinal 'Major' Text", color: (theDelegate?.theDefaults!.compassCardinalMajorColor)!))
            elements.append(InterfaceElement(name: "Cardinal 'Minor' Text", color: (theDelegate?.theDefaults!.compassCardinalMinorColor)!))
            elements.append(InterfaceElement(name: "Compass Ring", color: (theDelegate?.theDefaults!.compassRingColor)!))
            elements.append(InterfaceElement(name: "Compass Face", color: (theDelegate?.theDefaults!.compassFaceColor)!))

            elements.sort {               // Sort the model alphabetically by 'name'
                $0.name < $1.name
            }

            categories.append(InterfaceCategory(category: "Compass Configuration", elements: elements))
            
            elementTree.reloadData()         // Reload the OutlineView
            elementTree.expandItem(nil, expandChildren: true)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateCompassFace"), object: nil, userInfo: nil)
            
            guard let sensor = theDelegate?.theBridge?.findSensor(sensorName: "wind0dir") else {
                log.warning(MeteoCompassViewError.windSensorError)
                return
            }
            
            guard let value = sensor.measurement.value else {
                log.warning(MeteoCompassViewError.windSensorError)
                return
            }
            compassView.windDirection(direction: Double(value)!)
        } else {
            compassView.windDirection(direction: 0)
        }
    }
    
    /// Try to close the colorwell (NSColorPanel)
    override func viewWillDisappear() {
        NSColorPanel.shared.orderOut(nil)
    }
    
    ///
    /// Houusekeeping
    ///
    override func viewDidDisappear() {
        super.viewDidDisappear()
        categories.removeAll()
        
        if theDelegate?.theBridge != nil {
            theDelegate?.updateConfiguration()
        }
    }
    
    func updateCompass(caller: UITableCellView) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateCompassFace"), object: nil, userInfo: nil)
    }
    
    @IBAction func resetToDefaults(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = "You are about to reset all of the compass colors to MeteoBar defaults"
        alert.informativeText = "If you proceed, you will lose all of your color custimizations"
        alert.alertStyle = .warning
        alert.icon = NSImage(named: NSImage.cautionName)
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Reset")
        alert.beginSheetModal(for: self.view.window!) { (_ returnCode: NSApplication.ModalResponse) -> Void in
            switch returnCode {
            case .alertFirstButtonReturn:
                // Eat it; the user selected cancel ... do nothing
                break
            case .alertSecondButtonReturn:
                theDelegate?.resetCompassColors()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateCompassFace"), object: nil, userInfo: nil)
            default:
                break
            }
        }
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
            }
        } else {
            log.error("SensorTree: Unknown type[\(item)]")
        }
        
        return view
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
    
    override func awakeFromNib() {
        let gesture = QLDoubleClickGestureRecognizer(target: self,
                                                     action: #selector(singleAction),
                                                     doubleAction: #selector(doubleAction))
        self.addGestureRecognizer(gesture)
    }
    
    ///
    /// Easy ... did we just click once?
    /// Yes: Proceed
    ///
    @objc func singleAction() {
        activate(true)
    }
    
    ///
    /// Easy ... did we just click once?
    /// No: Do not proceed
    ///
    @objc func doubleAction() {
        // Eat it ...
    }
}

class UITableCellView: NSTableCellView {
    @IBOutlet weak var colorWell: InterfaceColorWell!
    
    @IBAction func colorWellChanged(_ sender: InterfaceColorWell) {
        switch sender.element?.name {
        case "Cardinal 'Minor' Tick":
            theDelegate?.theDefaults!.compassCardinalMinorTickColor = sender.color
        case "Cardinal 'Major' Tick":
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
        case "Cardinal 'Major' Text":
            theDelegate?.theDefaults!.compassCardinalMajorColor = sender.color
        case "Cardinal 'Minor' Text":
            theDelegate?.theDefaults!.compassCardinalMinorColor = sender.color
        case "Compass Ring":
            theDelegate?.theDefaults!.compassRingColor = sender.color
        case "Compass Face":
            theDelegate?.theDefaults!.compassFaceColor = sender.color
        default:
            break
        }
        theDelegate?.updateConfiguration()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateCompassFace"), object: nil, userInfo: nil)
    }
}
// Quick Subclass to get acces to the colorwell in our NSTableCellView
