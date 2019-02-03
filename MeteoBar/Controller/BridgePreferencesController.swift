//
//  BridgePreferencesController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/26/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa
import Preferences
import SceneKit

class BridgePreferencesController: NSViewController, Preferenceable {
    // MARK: - Protocol Varioables
    let toolbarItemTitle = "Bridge"
    let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!
    
    // MARK: - Outlets
    @IBOutlet weak var compassView: MeteoCompassSettingsView!
    @IBOutlet weak var collectionView: NSCollectionView!
    
    // Custom Properties
    var indexPathsOfItemsBeingDragged: Set<NSIndexPath>!
    var sensorCollectionModel = SensorCollectionModel()
    
    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "BridgePreferences"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
       
        compassView.windDirection(direction: 90.0)
        
        view.wantsLayer                     = true
        let flowLayout                      = NSCollectionViewFlowLayout()
        flowLayout.itemSize                 = NSSize(width: 137.0, height: 110.0)
        flowLayout.sectionInset             = NSEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        flowLayout.minimumInteritemSpacing  = 5.0
        flowLayout.minimumLineSpacing       = 5.0
        
        collectionView.collectionViewLayout = flowLayout
//        collectionView.registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeImage as String)])
        collectionView.setDraggingSourceOperationMask(.every, forLocal: true)
        collectionView.setDraggingSourceOperationMask(.every, forLocal: false)
    }
    
    ///
    /// Load the model and ensure the CollectionView is setup
    ///
    /// ## Important Notes ##
    /// 1. Consulted [NSCollectionView and calling reloadData from vi... |Apple Developer Forums](https://forums.developer.apple.com/thread/93054) to better-understand
    /// how to properly setup the view
    ///
    /// - parameters:   None
    /// - throws:       Nothing
    /// - returns:      Nothing
    ///
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let error = sensorCollectionModel.setupModel() {
            log.error(error.localizedDescription)
        } else {
            collectionView.reloadData()
        }
    }

    ///
    /// Load the model and ensure the CollectionView is setup
    ///
    /// ## Important Notes ##
    /// 1. Consulted [NSCollectionView and calling reloadData from vi... |Apple Developer Forums](https://forums.developer.apple.com/thread/93054) to better-understand
    /// how to properly setup the view
    ///
    /// - parameters:   None
    /// - throws:       Nothing
    /// - returns:      Nothing
    ///
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    /// Cleanup and save data to user preferences
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        compassView.updatePreferences()
    }
    
    ///
    /// Helper to draw box around selected item
    ///
    ///
    /// - parameters:
    ///   - selected: Is the CollecttionViewItem selected?
    ///   - atIndexPaths: The location of the highlighted (or not) CollecttionViewItem
    /// - throws: Nothing
    /// - returns: Nothing
    ///
    func highlightItems(selected: Bool, atIndexPaths: Set<NSIndexPath>) {
        for indexPath in atIndexPaths {
            guard let item = collectionView.item(at: indexPath as IndexPath) else {continue}
            (item as? SensorCollectionItemController)!.setHighlight(selected: selected)
        }
    }
}

///
/// Setup the extension for our CollectionView
///
/// ## Important Notes ##
/// 1.
///
/// - parameters:   None
/// - throws:       Nothing
/// - returns:      Nothing
///
extension BridgePreferencesController: NSCollectionViewDataSource {
    ///
    /// Simple: How many sections do we have
    ///
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return sensorCollectionModel.numberOfSections
    }
    
    ///
    /// Simple: How many items in the section do we have
    ///
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return sensorCollectionModel.numberOfItemsInSection(section)
    }
    
    ///
    /// Create the item to show
    ///
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item: NSCollectionViewItem? = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("SensorCollectionItem"), for: indexPath)
        guard let collectionViewItem = item as? SensorCollectionItemController else {
            return item!
        }
        
        collectionViewItem.imageFile = sensorCollectionModel.sensorImageForIndexPath(indexPath)
        
        return collectionViewItem
    }
    
    ///
    /// Return the view depending on where we are in the dragging process/window
    ///
    /// 1. section[0] = Energy Sensors
    /// 2. section[1] = Humidity Sensors
    /// 3. section[2] = Pressure Sensors
    /// 4. section[3] = Rain Sensors
    /// 5. section[4] = Solar Sensors
    /// 6. section[5] = Temperature Sensors
    /// 7. section[6] = Wind Sensors
    /// 8. section[7] = System Sensors
    ///
    func collectionView(_ collectionView: NSCollectionView,
                        viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind,
                        at indexPath: IndexPath) -> NSView {
        
        var view = NSView()
        switch kind {
        case NSCollectionView.elementKindSectionHeader:
            guard let headerView = collectionView.makeSupplementaryView(ofKind: kind,
                                                        withIdentifier: NSUserInterfaceItemIdentifier("SensorCollectionHeader"),
                                                        for: indexPath) as? SensorCollectionHeaderView else {
                log.warning("Something has gone wrong.  Cannot generate Header for CollectionView")
                return view
            }

            switch indexPath.section {
            case 0: // Energy
                headerView.headerText.stringValue = "Energy Sensors"
                headerView.sensorIcon.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "energy.png")!.filter(filter: "CIColorInvert") : NSImage(named: "energy.png")
            case 1: // Humidity
                headerView.headerText.stringValue = "Humidity Sensors"
                headerView.sensorIcon.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "humidity.png")!.filter(filter: "CIColorInvert") : NSImage(named: "humidity.png")
            case 2: // Temperature
                headerView.headerText.stringValue = "Pressure Sensors"
                headerView.sensorIcon.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "pressure.png")!.filter(filter: "CIColorInvert") : NSImage(named: "pressure.png")
            case 3: // Pressure
                headerView.headerText.stringValue = "Rain Sensors"
                headerView.sensorIcon.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "drop.png")!.filter(filter: "CIColorInvert") : NSImage(named: "drop.png")
            case 4: // Rain
                headerView.headerText.stringValue = "Solar Sensors"
                headerView.sensorIcon.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "solar-energy.png")!.filter(filter: "CIColorInvert") : NSImage(named: "solar-energy.png")
            case 5: // Solar
                headerView.headerText.stringValue = "Temperature Sensors"
                headerView.sensorIcon.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "thermometer.png")!.filter(filter: "CIColorInvert") : NSImage(named: "thermometer.png")
            case 6: // Wind
                headerView.headerText.stringValue = "Wind Sensors"
                headerView.sensorIcon.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "wind-sock.png")!.filter(filter: "CIColorInvert") : NSImage(named: "wind-sock.png")
            case 7: // System
                headerView.headerText.stringValue = "System Sensors"
                headerView.sensorIcon.image = (theDelegate?.isVibrantMode())! ? NSImage(named: "system.png")!.filter(filter: "CIColorInvert") : NSImage(named: "system.png")
            default: // Error
                log.warning("Something has gone wrong.  Unkown Sensor Type Detected.")
            }
        case NSCollectionView.elementKindSectionFooter:
            log.warning("Something has gone wrong.  Footers are not supported in this CollectionView")
        case NSCollectionView.elementKindInterItemGapIndicator:
            view = SeparatorView(frame: NSRect(x: 5.0, y: 0.0, width: 1.0, height: 64.0))
        default:
            log.error("Error: We should not have gotten here.  Unknown Element Kind in sensor collectiom view")
        }
        
        return view
    }
}

// MARK: - NSCollectionViewDelegate
///
/// Setup the extension for our CollectionView
///
/// ## Important Notes ##
/// 1. Compulsary view delegates added for highlighting and dragging/dropping
///
/// - parameters:   None
/// - throws:       Nothing
/// - returns:      Nothing
///
extension BridgePreferencesController: NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo) {
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        highlightItems(selected: true, atIndexPaths: indexPaths as Set<NSIndexPath>)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        highlightItems(selected: false, atIndexPaths: indexPaths as Set<NSIndexPath>)
    }
    
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
        return true
    }
    
    /// Prepare the dragged item to be the sensorID associated wiht the dragged image
    ///
    /// Original return was: <return sensorImage.thumb> --> This wrote a TIFF image to the pasteboard
    /// Changed it to return the sensorID so the reciever can do whatever w/ it
    ///
    /// ///  # Notes #
    ///  - [Inspired By](https://github.com/cupnoodle/ADragDropView)
    ///  - [Custom Pastebord](http://swiftrien.blogspot.com/2015/06/using-drag-drop-from-swift.html)
    ///
    /// - Parameters:
    ///   - collectionView: <#collectionView description#>
    ///   - indexPath: <#indexPath description#>
    /// - Returns: string representing the sensorID of the dragged image
    ///
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        let sensorImage = sensorCollectionModel.sensorImageForIndexPath((indexPath as NSIndexPath) as IndexPath)
        
        return sensorImage.sensorID! as NSPasteboardWriting
    }
    
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession,
                        willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
        
        indexPathsOfItemsBeingDragged = indexPaths as Set<NSIndexPath>
    }
    
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo,
                        proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
                        dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        
        /// Block any interactions with our "blank" Item at position 0
        if proposedDropIndexPath.pointee.item == 0 {
            return []
        }
/*
        /// Prevent the user from removing the sensor and putting it back in the wrong station
        if (sensorCollectionModel.stationForSection(proposedDropIndexPath.pointee.section) != "Reserved") {
            if (sensorCollectionModel.stationForSection(proposedDropIndexPath.pointee.section) ==
                sensorCollectionModel.sensorImageForIndexPath(indexPathsOfItemsBeingDragged!.first! as IndexPath).StationID) {
                // log.info("Can Drop")
            } else {
                // log.info("Cannnot Drop")
                return []
            }
        }
        /// Prevent the user from removing the sensor and putting it back in the wrong station
*/
        /// Are we trying to drop an item "on" another one?  If yes - just add it "before" the current item
        if proposedDropOperation.pointee == NSCollectionView.DropOperation.on {
            proposedDropOperation.pointee = NSCollectionView.DropOperation.before
        }
        
        if indexPathsOfItemsBeingDragged.count == 1 {
            return NSDragOperation.move
        } else {
            log.warning("CollectionView drag error: We do not support multiple drag items.")
            return []
        }
    }
    
    ///
    /// Called after mouse-up on drag
    ///
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo,
                        indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        
        if indexPathsOfItemsBeingDragged != nil {
            let indexPathOfFirstItembeingDragged = indexPathsOfItemsBeingDragged.first!
            var toIndexPath: NSIndexPath
            
            if indexPathOfFirstItembeingDragged.compare(indexPath as IndexPath) == .orderedAscending {
                toIndexPath = NSIndexPath(forItem: indexPath.item-1, inSection: indexPath.section)  // Item dropped after the original position
            } else {
                toIndexPath = NSIndexPath(forItem: indexPath.item, inSection: indexPath.section)    // Item dropped before the original position
            }
            
            // Block any interactions with our "blank" Item at position 0
            if toIndexPath.item == 0 {
                return false
            }
            
            sensorCollectionModel.moveImageFromIndexPath(indexPath: indexPathOfFirstItembeingDragged, toIndexPath: toIndexPath)
            highlightItems(selected: false, atIndexPaths: indexPathsOfItemsBeingDragged)
            NSAnimationContext.current.duration = 0.35
            collectionView.animator().moveItem(at: indexPathOfFirstItembeingDragged as IndexPath, to: toIndexPath as IndexPath)
        } else {
            log.error("Someone tried to drop something on me from outside the application!")
        }
        
        return true
    }
    
    ///
    /// The draggging has ended ... update the collectionView appropriately
    ///
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession,
                        endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
        
        indexPathsOfItemsBeingDragged = nil
    }
}

///
/// Setup the extension for our CollectionView
///
/// ## Important Notes ##
/// 1. Fixed height (30 pix) of the header
/// 2. Fixed size of the icons (48 pix)
///
/// - parameters:   None
/// - throws:       Nothing
/// - returns:      Nothing
///
extension BridgePreferencesController: NSCollectionViewDelegateFlowLayout {
    ///
    /// We need to size the header ... so do it.
    ///
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> NSSize {
        return NSSize(width: collectionView.frame.width, height: 32)
    }
    
    ///
    /// Size the item in the 0th item appropriately: 0 width and a height of 64
    ///
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> NSSize {
        
        return NSSize(width: 146, height: 110)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5.0
    }
}

///
/// Custom view for inter-gap separator (all it does is draw a 1-pixel-width blue line between items
///
/// ## Important Notes ##
/// 1.
///
/// - parameters:   None
/// - throws:       Nothing
/// - returns:      Nothing
///
private final class SeparatorView: NSBox {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        wantsLayer = true
        boxType = .separator  // We get a constraint assertion if this is not set as a separator
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let color: NSColor = NSColor.systemBlue
        
        /// Draw the seperator 1/2 of the distance across the gap - whatever the gap disnce is
        let drect = CGRect(x: dirtyRect.width/2.0, y: 0.0, width: 1, height: 48.0)
        let bpath: NSBezierPath = NSBezierPath(rect: drect)
        color.set()
        bpath.stroke()
    }
}
