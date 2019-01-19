//
//  AppDelegate.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/12/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa
import Preferences
import SwiftyBeaver
import SwiftyUserDefaults

/// The only globals we're going to use
let theDelegate = AppDelegate.self
let log = QuantumLogger.self
/// The only globals we're going to use

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    /// Meteobar is up and we're ready to go
    ///
    /// - Parameter aNotification: <#aNotification description#>
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // SwiftyBeaver Config
        let console         = ConsoleDestination()
        console.format      = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M"
        console.useNSLog    = true
        log.addDestination(console)
        // SwiftyBeaver Config
        
        WeatherPlatform.shared.initializeBridgeSpecification(ipAddress: "10.0.0.137", bridgeName: "Test Bridge")
    }

    /// MeteoBar is about to close ... clean-up
    ///
    /// - Parameter aNotification: <#aNotification description#>
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
