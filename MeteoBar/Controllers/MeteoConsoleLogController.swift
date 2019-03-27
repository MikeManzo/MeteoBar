//
//  MeteoConsoleLogController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/24/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Preferences
import Cocoa

enum ConsoleLogError: Error, CustomStringConvertible {
    case viewError
    case logFileError
    
    var description: String {
        switch self {
        case .viewError: return "Unknown error creating table view"
        case .logFileError: return "Unable to reade log file"
        }
    }
}

///
/// [NSTableView, Bindings, and Array Controllers](https://medium.com/@jamesktan/swift-xcode-8-1-nstableview-bindings-and-array-controllers-oh-my-c595623cae0d)
///
class MeteoConsoleLogController: NSViewController, Preferenceable {
    @IBOutlet weak var consoleTable: NSTableView!
    // MARK: - Protocol Variables
    let toolbarItemTitle = "Console Log"
    let toolbarItemIcon = NSImage(named: "console.png")!
    
    var tableConsoleData = [MeteoLogReader]()
    
    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "MeteoConsoleLog"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        guard let logFile = theDelegate?.getFileLogger() else {
            return
        }
        
        let stream = StreamReader(url: logFile.logFileURL!)
        while let json = stream?.nextLine() {
            do {
                tableConsoleData.append(try MeteoLogReader(json))
            } catch {
                log.warning(ConsoleLogError.logFileError)
            }
        }
        consoleTable.reloadData()
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
            log.warning(ConsoleLogError.viewError)
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

            result.date.stringValue         = Date(timeIntervalSince1970: consoleEntry.timestamp).toLongDateString()
            result.time.stringValue         = Date(timeIntervalSince1970: consoleEntry.timestamp).toLongTimeString()
            result.lineNumber.stringValue   = consoleEntry.line.description
            result.function.stringValue     = consoleEntry.function
            result.message.stringValue      = consoleEntry.message
            result.file.stringValue         = consoleEntry.file
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
