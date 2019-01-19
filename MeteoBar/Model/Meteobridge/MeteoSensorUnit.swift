//
//  SensorUnit.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/17/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

/// Atomic class to describe sensor units
class MeteoSensorUnit: NSObject, Codable, Copyable {
    
    /// Properties
    var representation: String
    var parameter: String
    var isDefault: Bool
    var name: String
    
    /// Initialize the Sensor Unit
    ///
    /// - Parameters:
    ///   - unitName: name of sensor
    ///   - unitParam: Meteobridge parameter
    ///   - unitRep: unit representation (e.g., mm, in, m/s, etc.)
    ///   - unitDefault: is this THE default sensor unit?
    required init (unitName: String, unitParam: String, unitRep: String, unitDefault: Bool) {
        
        self.isDefault      = unitDefault
        self.parameter      = unitParam
        self.name           = unitName
        self.representation = unitRep
        
        super.init()
    }
    
    /// Copy MeteoSensorUnit
    ///
    /// - Returns: fully constructed MeteoSensorUnit object
    func copy() -> Self {
        return type(of: self).init(unitName: self.name, unitParam: self.parameter, unitRep: self.representation, unitDefault: self.isDefault)
    }
}
