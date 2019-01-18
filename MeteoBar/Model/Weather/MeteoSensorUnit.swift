//
//  SensorUnit.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/17/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

/// Atomic class to describe sensor units
class MeteoSensorUnit: NSObject, Codable {
    
    /// Properties
    var name: String
    var parameter: String
    var reprsentation: String
    var isDefault: Bool
    
    /// Initialize the Sensor Unit
    ///
    /// - Parameters:
    ///   - unitName: name of sensor
    ///   - unitParam: Meteobridge parameter
    ///   - unitRep: unit representation (e.g., mm, in, m/s, etc.)
    ///   - unitDefault: is this THE default sensor unit?
    init (unitName: String, unitParam: String, unitRep: String, unitDefault: Bool) {
        
        self.isDefault      = unitDefault
        self.parameter      = unitParam
        self.name           = unitName
        self.reprsentation  = unitRep
        
        super.init()
    }
}
