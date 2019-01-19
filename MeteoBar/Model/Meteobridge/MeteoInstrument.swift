//
//  MeteoInstruments.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/19/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

class MeteoInstrument: NSObject, Codable, Copyable {

    /// Properties
    var category: MeteoSensorCategory
    var information: String
    var parameter: String
    var name: String

    /// <#Description#>
    ///
    /// - Parameters:
    ///   - name: name of instrument
    ///   - param: parameter to send to Meteobridge
    ///   - info: description of instrument
    ///
    /// - Returns: nothing
    ///
    required init (name: String, param: String, info: String) {
        self.category       = .system
        self.parameter      = param
        self.information    = info
        self.name           = name
        
        super.init()
    }
    
    /// Copy MeteoInstrument
    ///
    /// - Returns: fully constructed MeteoSensorUnit object
    func copy() -> Self {
        return type(of: self).init(name: self.name, param: self.parameter, info: self.information)
    }
}
