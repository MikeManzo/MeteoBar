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
    /// Library⁩ ▸ ⁨Containers⁩ ▸ ⁨com.quantumjoker.meteobar⁩ ▸ ⁨Data⁩
    /// ~/Library/Containers/com.quantumjoker.meteobar/Data/meteobar_console.log
    ///
    /// - Parameter aNotification: <#aNotification description#>
    ///
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // SwiftyBeaver Config
        let console         = ConsoleDestination()
        console.format      = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M"
        console.useNSLog    = true
        log.addDestination(console)
        
        if (theDefaults?.logFileEnabled)! {
            enableFileLogging(enable: true)
        }
        // SwiftyBeaver Config
    }

    /// MeteoBar is about to close ... clean-up
    ///
    /// - Parameter aNotification: <#aNotification description#>
    func applicationWillTerminate(_ aNotification: Notification) {
        updateMeteoBar()
        log.info("Meteobar exiting gracefully")
    }
    
    /// Start using the file logger
    ///
    func enableFileLogging(enable: Bool) {
        switch enable {
        case true:
            for aDestination in log.destinations {
                switch aDestination {
                case FileDestination():
                    log.warning("File Logging Already Enabled ... taking no action")
                    return
                default:
                    break
                }
            }
            
            let file            = FileDestination()
            file.logFileURL     = URL(fileURLWithPath: "meteobar_console.log")
            file.format         = "$Dyyyy-MM-dd HH:mm:ss.SSS$d $C$L$c: $M"
            file.minLevel       = .info
            
            log.addDestination(file)
            log.info("File Logging Enabled")
        case false:
            for aDestination in log.destinations {
                switch aDestination {
                case FileDestination():
                    log.info("File Logging Disabled")
                    log.removeDestination(aDestination)
                default:
                    break
                }
            }
        }
    }
    
    /// Save the current bridge to user defaults
    ///
    func updateBridge() {
        Defaults[.bridgesDefaults]  = theBridge
        log.info("Bridge configuration updated")
    }
    
    /// Save the current UI configuration to the user defaults
    ///
    func updateConfiguration() {
        Defaults[.meteoBarDefaults] = theDefaults
        log.info("User interface configuration updated")
    }
    
    /// Save the entire app's configuration to user defaults
    ///
    func updateMeteoBar() {
        Defaults[.bridgesDefaults]  = theBridge
        Defaults[.meteoBarDefaults] = theDefaults
        log.info("Meteobar configuration updated")
    }
}
