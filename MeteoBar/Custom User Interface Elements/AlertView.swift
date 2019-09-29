//
//  AlertView.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/14/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

class AlertView: NSView {
    @IBOutlet weak var alertsTable: NSTableView!

    var alerts: [MeteoWeatherAlert]?

    lazy var alertPopOver: NSPopover = {
        var popOver = NSPopover()
        popOver.contentViewController = AlertDetailsController.newController()
        return popOver
    }()
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    /// Called when a view is tranistioned to a MenuItem
    ///
    override func viewDidMoveToWindow() {
        if self.window == nil {

        } else {

        }
    }
    
    override func awakeFromNib() {
        alertsTable.doubleAction    = #selector(doubleClickOnAlertRow)
        alertsTable.dataSource      = self
        alertsTable.delegate        = self
        alertsTable.target          = self
    }
        
    /// Helper to referesh the UI
    ///
    /// - Parameter alerts: the alerts to fill the table with
    open func refreshAlerts(alerts: [MeteoWeatherAlert]) {
        DispatchQueue.main.async { [unowned self] in
            self.alerts = alerts
            self.alertsTable.reloadData()
        }
    }

    ///
    /// The user double clicked on the table ... do something
    ///
    @objc func singleClickOnAlertRow(sender: AnyObject) {
        if alertsTable.selectedRow > -1 {

        } else {
            // Eat it
        }
    }

    ///
    /// The user double clicked on the table ... do something
    ///
    @objc func doubleClickOnAlertRow(sender: AnyObject) {
        if alertsTable.selectedRow > -1 {
            if alertPopOver.isShown {
                closeAlertPopover(sender: alertsTable.selectedRow)
                showAlertPopover(sender: alertsTable.selectedRow)
            } else {
                showAlertPopover(sender: alertsTable.selectedRow)
            }
        } else {
            // Eat it
        }
    }
}

extension AlertView: NSTableViewDataSource, NSTableViewDelegate {
    /// Returns the number of rows that shoudl be displayed by the table
    ///
    /// - Parameter tableView: the TableView in question
    /// - Returns: the number of rows to display
    func numberOfRows(in tableView: NSTableView) -> Int {
        if alerts == nil {
            return 0
        } else {
            return (alerts?.count)!
        }
    }
    
    /// TableView override to format the contents of our cutom row (Note the custom AlertTableCellView class)
    ///
    /// - Parameters:
    ///   - tableView: the TableView in-question
    ///   - tableColumn: the column to format
    ///   - row: the row to format
    /// - Returns: the fully formatted view (AlertTableCellView in our case)
    ///
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DefaultRow"), owner: self) as? AlertTableCellView else {
            log.error("Cannot display alerts table")
            return nil
        }

        if alerts == nil {
            return result
        } else {
            if !alerts!.isEmpty {
                let myAlert = alerts![row]
                DispatchQueue.main.async {
                    result.alertHeadline.stringValue    = myAlert.headline
                    result.alertDescription.stringValue = myAlert.detail
                    switch myAlert.severity {
                    case .extreme, .severe:
                        result.imgAlert?.image = NSImage(named: "warning-red.png")
                    case .minor, .moderate:
                        result.imgAlert?.image = NSImage(named: "warning-yellow.png")
                    case .unknown:
                        log.warning("Unkown alert passed")
                    }
                }
            } else {
                result.alertHeadline.stringValue    = ""
                result.alertDescription.stringValue = ""
                result.imgAlert = nil
            }
        }        
        return result
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
}

// MARK: MainMenuController Extension
///
/// Extend the MainMenuController to hanfle the Popovers
///
/// - parameters: None
/// - throws: Nothing
/// - returns:  Nothing
///
extension AlertView {
    @objc func toggleAlertPopover(_ sender: Any?) {
        if alertPopOver.isShown {
            closeAlertPopover(sender: sender)
        } else {
            showAlertPopover(sender: sender)
        }
    }
    
    func showAlertPopover(sender: Any?) {
        guard let myRow = sender as? Int else {
            log.error("Row Error")
            return
        }
        
        guard let myView = alertsTable.view(atColumn: 0, row: myRow, makeIfNecessary: true) as? AlertTableCellView else {
            log.error("ViewError")
            return
        }

        let myAlert = alerts![myRow]

         DispatchQueue.main.async { [unowned self] in
            (self.alertPopOver.contentViewController as? AlertDetailsController)?.update(alert: myAlert)
            self.alertPopOver.show(relativeTo: myView.imgAlert.bounds, of: myView.imgAlert, preferredEdge: NSRectEdge.minX)
        }
    }
    
    func closeAlertPopover(sender: Any?) {
        alertPopOver.performClose(sender)
    }
}

/// Custom view for our row (1 Icon and two text fields)
class AlertTableCellView: NSTableCellView {
    @IBOutlet weak var imgAlert: NSImageView!
    @IBOutlet weak var alertHeadline: NSTextField!
    @IBOutlet weak var alertDescription: NSTextField!
}
