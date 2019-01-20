//
//  MeteoObservation.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/19/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

/// Simple class to hold an observation
class MeteoObservation: NSObject, Codable, Copyable {
    private var _value: String?
    private var _time: Date?
    
    /// Observation
    var value: String? {
        return _value
    }
    
    /// Time the observation was made
    var time: Date? {
        return _time
    }

    /// Empty initializer
    override init () {
        super.init()
    }

    /// Make a copy of tghe observation
    ///
    /// - Returns: fully formed copy of the object
    func copy() -> Self {
        return type(of: self).init(value: self._value, time: self._time!)
    }

    /// Initialize the observation
    ///
    /// - Parameters:
    ///   - value: the value of the obseravtion
    ///   - time: the time the observation made?
    required init (value: String?, time: Date) {
        self._value = value
        self._time  = time
        
        super.init()
    }
    
    /// Save creation/deletion ... just update a pre-formed object
    ///
    /// - Parameters:
    ///   - value: the value of the obseravtion
    ///   - time: the time the observation made?
    func update (value: String?, time: Date) {
        _value = value
        _time  = time
    }
    
    /// Save creation/deletion ... just update a pre-formed object
    ///
    /// - Parameter observation: an existing observation to update the current object with
    func update (observation: MeteoObservation?) {
        if observation != nil {
            _value = observation?.value
            _time  = observation?.time
        }
    }
}
