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
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func awakeFromNib() {
        alertsTable.dataSource  = self
        alertsTable.delegate    = self
    }
    
    open func refresh(alerts: [MeteoWeatherAlert]) {
        self.alerts = alerts
        DispatchQueue.main.async { [unowned self] in
            self.alertsTable.reloadData()
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
            log.warning("Cannot display alerts table")
            return nil
        }

        if alerts == nil {
            return result
        } else {
            if !alerts!.isEmpty {
                
                let myAlert = alerts![row]
                result.alertHeadline.stringValue    = myAlert.headline
                print(myAlert.detail)
                result.alertDescription.stringValue = myAlert.detail
                switch myAlert.severity {
                case .extreme, .severe:
                    DispatchQueue.main.async {
                        result.imageView?.image = NSImage(named: "warning-red.png")?.resized(to: NSSize(width: 16.0, height: 16.0))
                    }
                case .minor, .moderate:
                    DispatchQueue.main.async {
                        result.imageView?.image = NSImage(named: "warning-yellow.png")?.resized(to: NSSize(width: 16.0, height: 16.0))
                    }
                case .unknown:
                    log.warning("Unkown alert passed")
                }
            }
        }
        
        return result
    }
}

/// Custom view for our row (1 Icon and two text fields)
class AlertTableCellView: NSTableCellView {
    @IBOutlet weak var imgAlert: NSImageView!
    @IBOutlet weak var alertHeadline: NSTextField!
    @IBOutlet weak var alertDescription: NSTextField!
}
