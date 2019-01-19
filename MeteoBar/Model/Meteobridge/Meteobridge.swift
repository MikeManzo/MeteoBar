//
//  Meteobridge.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/18/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

class Meteobridge: NSObject, Codable, Copyable {
    /// Properties
    var instruments = [MeteoSensorCategory: [MeteoInstrument]]()
    var sensors = [MeteoSensorCategory: [MeteobridgeSensor]]()
    var ipAddress: String
    var uuid: String
    var name: String

    /// Initialize the Meteobridge object
    ///
    /// - Parameters:
    ///   - bridgeIP: IP Address of the meteobridge
    ///   - bridgeName: the name we are giving the meteobridge
    ///   - bridgeSensors: the collection of sensors that this meteobridge has
    required init? (bridgeIP: String, bridgeName: String, bridgeSensors: [MeteoSensorCategory: [MeteobridgeSensor]]? = nil) {
        self.uuid = UUID().uuidString
        self.ipAddress = bridgeIP
        self.name = bridgeName
        
        if bridgeSensors != nil {
            guard case self.sensors = bridgeSensors else {
                return nil
            }
        }
        
        super.init()
    }
    
    /// Copy Meteobridge
    ///
    /// - Returns: fully constructed Meteobridge object
    func copy() -> Self {
        return type(of: self).init(bridgeIP: self.ipAddress, bridgeName: self.name, bridgeSensors: self.sensors)!
    }
    
    /// Add a sensor to the bridge
    ///
    ///  - Note: [Dictonary Reference](https://stackoverflow.com/questions/47739325/make-statement-more-clear-checking-object-for-key-in-dictionary/47739419#47739419)
    ///
    ///  - Parameter sensor: fully-formed MeteobridgeSensor
    ///
    ///  - Returns: nothing
    func addSensor(sensor: MeteobridgeSensor) {
        sensors[sensor.category, default: []].append(sensor)
    }
    
    /// Add a sensor to the bridge
    ///
    ///  - Note: [Dictonary Reference](https://stackoverflow.com/questions/47739325/make-statement-more-clear-checking-object-for-key-in-dictionary/47739419#47739419)
    ///
    ///  - Parameter sensor: fully-formed MeteobridgeSensor
    ///
    ///  - Returns: nothing
    func addSensor(instrument: MeteoInstrument) {
        instruments[instrument.category, default: []].append(instrument)
    }
}
