//
//  AppDelegate.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/12/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//
// [Design Guidlines](https://developer.apple.com/design/human-interface-guidelines/macos/icons-and-images/system-icons/)

import Cocoa
import Preferences
import SwiftyBeaver
import SwiftyUserDefaults

/// The only globals we're going to use
let log = QuantumLogger.self
/// The only globals we're going to use

/// User Defaults
extension DefaultsKeys {
    static let bridgesDefaults  = DefaultsKey<Meteobridge?>("DefaultBridges")
    static let meteoBarDefaults = DefaultsKey<MeteoPreferences?>("MeteoBarPrefwerences")
}
/// User Defaults

enum PlatformError: Error, CustomStringConvertible {
    case passthroughSystem(systemError: Error)
    case custom(message: String)
    
    var description: String {
        switch self {
        case .passthroughSystem(let systemError): return systemError.localizedDescription
        case .custom(let message): return message
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var theDefaults = Defaults[.meteoBarDefaults]
    var theBridge   = Defaults[.bridgesDefaults]

    override init() {
        if theDefaults == nil {
            theDefaults = MeteoPreferences()
            Defaults[.meteoBarDefaults] = theDefaults
        }
    }
    
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
        
/*        if theDefaults == nil {
            theDefaults = MeteoPreferences()
            Defaults[.meteoBarDefaults] = theDefaults
        } */
    }

    /// MeteoBar is about to close ... clean-up
    ///
    /// - Parameter aNotification: <#aNotification description#>
    func applicationWillTerminate(_ aNotification: Notification) {
        updateMeteoBar()
    }
    
    func updateBridge() {
        Defaults[.bridgesDefaults]  = theBridge
    }
    
    func updateConfiguration() {
        Defaults[.meteoBarDefaults] = theDefaults
    }
    
    func updateMeteoBar() {
        Defaults[.bridgesDefaults]  = theBridge
        Defaults[.meteoBarDefaults] = theDefaults
    }
}
