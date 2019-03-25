//
//  MeteoConsoleLogController.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/24/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Preferences
import Cocoa

///
/// [NSTableView, Bindings, and Array Controllers](https://medium.com/@jamesktan/swift-xcode-8-1-nstableview-bindings-and-array-controllers-oh-my-c595623cae0d)
///
class MeteoConsoleLogController: NSViewController, Preferenceable {
    // MARK: - Protocol Variables
    let toolbarItemTitle = "Console Log"
    let toolbarItemIcon = NSImage(named: "console.png")!
    
    // MARK: - Overrides
    override var nibName: NSNib.Name? {
        return "MeteoConsoleLog"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        guard let logFile = theDelegate?.getFileLogger() else {
            return
        }
        
        let stream = StreamReader(url: logFile.logFileURL!)
        while let json = stream?.nextLine() {
            do {
                let meteoLogReader = try MeteoLogReader(json)
                print("\(meteoLogReader.message)")
            } catch {
                print ("error")
            }
        }
    }
}
