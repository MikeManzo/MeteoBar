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
    var parameterMax: String
    var parameterMin: String
    var parameter: String
    var isDefault: Bool
    var name: String
    
    private var _isCurrent: Bool
    
    /// We can have a default sensor that is not active ... so, let's be explicit
    var isCurrent: Bool {
        get {
            return _isCurrent
        }
        set {
            _isCurrent = newValue
        }
    }
    
    /// Initialize the Sensor Unit
    ///
    /// - Parameters:
    ///   - unitName: name of sensor
    ///   - unitParam: Meteobridge parameter
    ///   - unitRep: unit representation (e.g., mm, in, m/s, etc.)
    ///   - unitDefault: is this THE default sensor unit?
    required init (unitName: String, unitParam: String, unitMax: String, unitMin: String, unitRep: String, unitDefault: Bool) {
        self._isCurrent     = unitDefault ? true : false
        self.isDefault      = unitDefault
        self.parameter      = unitParam
        self.name           = unitName
        self.representation = unitRep
        self.parameterMax   = unitMax
        self.parameterMin   = unitMin

        super.init()
    }
    
    /// Copy MeteoSensorUnit
    ///
    /// - Returns: fully constructed MeteoSensorUnit object
    func copy() -> Self {
        return type(of: self).init(unitName: self.name, unitParam: self.parameter,
                                   unitMax: self.parameterMax, unitMin: parameterMin,
                                   unitRep: self.representation, unitDefault: self.isDefault)
    }
}
