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

/// User Defaults
extension DefaultsKeys {
    static let defaultBridges = DefaultsKey<Meteobridge?>("DefaultBridges")
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

    var theBridge = Defaults[.defaultBridges]
    
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
        
        /// Test Stub
        if theBridge == nil {
            WeatherPlatform.shared.initializeBridgeSpecification(ipAddress: "10.0.0.137", bridgeName: "Test Bridge", callback: { [unowned self] response, error in
                if error == nil {
                    self.theBridge = response
                    
                    self.theBridge?.getObservation({ bridge, error in
                        if error == nil {
                            log.info("\(bridge?.name ?? "")")
                        } else {
                            log.error(error.value)
                        }
                    })
                    Defaults[.defaultBridges] = self.theBridge
                }
            })
        }
        /// Test Stub
    }

    /// MeteoBar is about to close ... clean-up
    ///
    /// - Parameter aNotification: <#aNotification description#>
    func applicationWillTerminate(_ aNotification: Notification) {
        Defaults[.defaultBridges] = theBridge
    }
}

//  To clear the defaults: Open terminal and type <defaults delete com.StraightOnTillDawn.Solis>
