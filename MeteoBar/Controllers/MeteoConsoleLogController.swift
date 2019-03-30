//
//  MeteoConsoleLogController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/24/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Preferences
import SwiftDate
import Cocoa

enum ConsoleLogError: Error, CustomStringConvertible {
    case viewError
    case logFileError
    case deleteError
    
    var description: String {
        switch self {
        case .viewError: return "Unknown error creating table view"
        case .logFileError: return "Unable to reade log file"
        case .deleteError: return "Unable to delete records from log"
        }
    }
}

///
/// [NSTableView, Bindings, and Array Controllers](https://medium.com/@jamesktan/swift-xcode-8-1-nstableview-bindings-and-array-controllers-oh-my-c595623cae0d)
///
class MeteoConsoleLogController: NSViewController, Preferenceable {
    @IBOutlet weak var consoleTable: NSTableView!
    @IBOutlet weak var boxContainer: NSBox!
    // MARK: - Protocol Variables
    let toolbarItemTitle = "Console Log"
    let toolbarItemIcon = NSImage(named: "console.png")!
    
    var tableConsoleData = [MeteoLogDB]()
    
    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "MeteoConsoleLog"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
       
    override func viewWillAppear() {
        showAllRecords(self)
    }

    @IBAction func deleteSelectedRows(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }

        var logs: [Int64] = []
        
        for indexPath in consoleTable.selectedRowIndexes {
            logs.append(tableConsoleData[indexPath].id!)
        }
        
        do {
            _ = try logDB.deleteRecords(recordIDs: logs)
            
            guard let tempData = try logDB.orderByDateAscending() else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    @IBAction func deleteWarningRecords(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        do {
            _ = try logDB.deleteLevelRecords(level: .warning)
            
            guard let tempData = try logDB.orderByDateAscending() else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    @IBAction func deleteVerboseRecords(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        do {
            _ = try logDB.deleteLevelRecords(level: .verbose)
            
            guard let tempData = try logDB.orderByDateAscending() else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    @IBAction func deleteInformationRecords(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        do {
            _ = try logDB.deleteLevelRecords(level: .info)
            
            guard let tempData = try logDB.orderByDateAscending() else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    @IBAction func deleteErrorRecords(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        do {
            _ = try logDB.deleteLevelRecords(level: .error)
            
            guard let tempData = try logDB.orderByDateAscending() else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    @IBAction func deleteDebugRecods(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        do {
            _ = try logDB.deleteLevelRecords(level: .debug)
            
            guard let tempData = try logDB.orderByDateAscending() else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    @IBAction func showAllRecords(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        
        do {
            guard let tempData = try logDB.orderByDateAscending() else {
                return
            }
            
            tableConsoleData = tempData
            consoleTable.reloadData()
            boxContainer.title = "Shwowing \(tempData.count) of \(try logDB.recordCount()) records"
        } catch {
            log.error(ConsoleLogError.logFileError)
        }
    }
    
    @IBAction func showYear(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        
        do {
            guard let tempData = try logDB.recordsByDateRange(dateFrom: Date() - 1.years, dateTo: Date()) else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
            boxContainer.title = "Shwowing \(tempData.count) of \(try logDB.recordCount()) records"
        } catch {
            log.error(ConsoleLogError.logFileError)
        }
    }

    @IBAction func showMonth(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        
        do {
            guard let tempData = try logDB.recordsByDateRange(dateFrom: Date() - 30.days, dateTo: Date()) else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
            boxContainer.title = "Shwowing \(tempData.count) of \(try logDB.recordCount()) records"
        } catch {
            log.error(ConsoleLogError.logFileError)
        }
    }

    @IBAction func showWeek(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        
        do {
            guard let tempData = try logDB.recordsByDateRange(dateFrom: Date() - 7.days, dateTo: Date()) else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
            boxContainer.title = "Shwowing \(tempData.count) of \(try logDB.recordCount()) records"
        } catch {
            log.error(ConsoleLogError.logFileError)
        }
    }

    @IBAction func showToday(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        
        do {
            guard let tempData = try logDB.recordsByDateRange(dateFrom: Date().dateBySet([.month: 0, .day: 0, .hour: 0, .minute: 0, .second: 0])!,
                                                              dateTo: Date()) else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
            boxContainer.title = "Shwowing \(tempData.count) of \(try logDB.recordCount()) records"
        } catch {
            log.error(ConsoleLogError.logFileError)
        }
    }

    @IBAction func showWarningOnly(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        do {
            guard let tempData = try logDB.recordsByLevel(level: .warning) else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
            boxContainer.title = "Shwowing \(tempData.count) of \(try logDB.recordCount()) records"
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    @IBAction func showVerboseOnly(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        do {
            guard let tempData = try logDB.recordsByLevel(level: .verbose) else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
            boxContainer.title = "Shwowing \(tempData.count) of \(try logDB.recordCount()) records"
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    @IBAction func showInformationOnly(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        do {
            guard let tempData = try logDB.recordsByLevel(level: .info) else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
            boxContainer.title = "Shwowing \(tempData.count) of \(try logDB.recordCount()) records"
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    @IBAction func showErrorOnly(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        do {
            guard let tempData = try logDB.recordsByLevel(level: .error) else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
            boxContainer.title = "Shwowing \(tempData.count) of \(try logDB.recordCount()) records"
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    @IBAction func showDebugOnly(_ sender: Any) {
        guard let logDB = theDelegate?.getDBLogger() else {
            return
        }
        do {
            guard let tempData = try logDB.recordsByLevel(level: .debug) else {
                return
            }
            tableConsoleData = tempData
            consoleTable.reloadData()
            boxContainer.title = "Shwowing \(tempData.count) of \(try logDB.recordCount()) records"
        } catch {
            log.error(ConsoleLogError.deleteError)
        }
    }
    
    override func viewDidDisappear() {
        tableConsoleData.removeAll()
        consoleTable.reloadData()
    }
}

// MARK: - Extension
extension MeteoConsoleLogController: NSTableViewDataSource, NSTableViewDelegate {
    /// Returns the number of rows that shoudl be displayed by the table
    ///
    /// - Parameter tableView: the TableView in question
    /// - Returns: the number of rows to display
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tableConsoleData.count
    }
    
    /// TableView override to format the contents of our cutom row (Note the custom AttributionTableCellView class)
    ///
    /// - Parameters:
    ///   - tableView: the TableView in-question
    ///   - tableColumn: the column to format
    ///   - row: the row to format
    /// - Returns: the fully formatted view (AttributionTableCellView in our case)
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let result = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DefaultRow"), owner: self) as? ConsoleTableCellView else {
            log.error(ConsoleLogError.viewError)
            return nil
        }

        if !tableConsoleData.isEmpty {
            let consoleEntry = tableConsoleData[row]
            var icon: NSImage?
            
            switch consoleEntry.level {
            case 0: // Verbose
                icon = NSImage(named: "log-verbose.png")
            case 1: // Debug
                icon = NSImage(named: "log-debug.png")
            case 2: // Info
                icon = NSImage(named: "log-info.png")
            case 3: // Warning
                icon = NSImage(named: "log-warning.png")
            case 4: // Error
                icon = NSImage(named: "log-error.png")
            default:
                icon = NSImage(named: "question.png")
            }
            
            result.date.stringValue         = consoleEntry.date.toLongDateString()
            result.time.stringValue         = consoleEntry.date.toLongTimeString()
            result.lineNumber.stringValue   = consoleEntry.line.description
            result.function.stringValue     = consoleEntry.function
            result.file.stringValue         = consoleEntry.file
            result.message.stringValue      = consoleEntry.msg
            result.imageIcon.image          = icon
        }

        return result
    }
}

/// Custom view for our row (1 Icon and three text fields)
class ConsoleTableCellView: NSTableCellView {
    @IBOutlet weak var lineNumber: NSTextField!
    @IBOutlet weak var imageIcon: NSImageView!
    @IBOutlet weak var function: NSTextField!
    @IBOutlet weak var message: NSTextField!
    @IBOutlet weak var date: NSTextField!
    @IBOutlet weak var time: NSTextField!
    @IBOutlet weak var file: NSTextField!
}
