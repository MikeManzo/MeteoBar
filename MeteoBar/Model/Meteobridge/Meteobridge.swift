//
//  Meteobridge.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/18/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

enum MeteobridgeError: Error, CustomStringConvertible {
    case observationError
    case unknownSensor
    case dataError
    
    var description: String {
        switch self {
        case .observationError: return "Error reading observation from Meteobridge"
        case .dataError: return "Error reading data from Meteobridg"
        case .unknownSensor: return "Unknown sensor detected"
        }
    }
}

final class Meteobridge: NSObject, Codable, Copyable, DefaultsSerializable {
    /// Properties
    var sensors = [MeteoSensorCategory: [MeteobridgeSensor]]()
    var updateInterval: Int
    var ipAddress: String
    var uuid: String
    var name: String

    /// Initialize the Meteobridge object
    ///
    /// - Parameters:
    ///   - bridgeIP: IP Address of the meteobridge
    ///   - bridgeName: the name we are giving the meteobridge
    ///   - bridgeSensors: the collection of sensors that this meteobridge has
    required init? (bridgeIP: String, bridgeName: String, bridgeSensors: [MeteoSensorCategory: [MeteobridgeSensor]]? = nil, uniqueID: String? = nil) {
        self.ipAddress = bridgeIP
        self.name = bridgeName

        self.updateInterval = 3
        
        if bridgeSensors != nil {
            guard case self.sensors = bridgeSensors else {
                return nil
            }
        }
        
        if uniqueID != nil {
            self.uuid = uniqueID!
        } else {
            self.uuid = UUID().uuidString
        }
        
        super.init()
    }
    
    /// Copy Meteobridge
    ///
    /// - Returns: fully constructed Meteobridge object
    func copy() -> Self {
        return type(of: self).init(bridgeIP: self.ipAddress, bridgeName: self.name, bridgeSensors: self.sensors, uniqueID: self.uuid)!
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
    
    /// Since we have a dictonary of sensors organized by Category, we need an additional step to get a discreet sensor
    ///
    /// - Parameter sensorName: sensorName
    /// - Returns: a valid sensor OR nil if no sensor was found
    ///
    func findSensor(sensorName: String) -> MeteobridgeSensor? {
        var theSensor: MeteobridgeSensor?
        
        for (_, catSensors) in sensors {
            theSensor = catSensors.filter { $0.name == sensorName }.first
            if theSensor != nil {
                break
            }
        }
        
        return theSensor
    }
    
    /// Interrogate the bridge for data
    ///
    /// ## Important Notes ##
    /// The data comes to us in a response array like
    /// 1. [0] == Time:12;00;00 <-- Always
    /// 2. [1] == THB0TEMP:29.9 <-- Optional
    /// 3. [2] == ... etc.
    ///
    /// We want to separate the keys and values so we can apply them to the appropriate sensors
    ///
    /// - Parameter callback: return function
    ///
    func getObservation(_ callback: @escaping (_ theBridge: Meteobridge?, _ error: Error?) -> Void) {
        WeatherPlatform.shared.getConditions(theBridge: self, callback: { [unowned self] bridgeData, bridgeError in
            if bridgeError != nil {
                callback(nil, bridgeError)
            }
            
            guard let validData = bridgeData as? Data else {
                callback(nil, MeteobridgeError.dataError)
                return
            }
            
            guard let bridgeResponse: [String] = String(data: validData, encoding: .utf8)?.components(separatedBy: ",") else {
                callback(nil, MeteobridgeError.dataError)
                return
            }
            
            guard let timeArray = bridgeResponse[0].components(separatedBy: ";") as Array? else { // Time:HH;MM;SS (note the semi-colon)
                callback(nil, MeteobridgeError.observationError)
                return
            }
            guard let hourPair = timeArray[0].components(separatedBy: ":")  as Array? else {  // [0] = Time [1] = HH
                callback(nil, MeteobridgeError.observationError)
                return
            }
            guard let timeCollect = Calendar.current.date(bySettingHour: Int(hourPair[1])!, minute: Int(timeArray[1])!, second: Int(timeArray[2])!, of: Date())! as Date? else {
                callback(nil, MeteobridgeError.observationError)
                return
            }
            
            for pair in bridgeResponse {
                let subPair = pair.components(separatedBy: ":")                                 // th0temp:30.4 <-- We want to break this into [0]th0temp & [1]30.4
                if subPair[0] != "Time" {
                guard let filteredSensor = self.findSensor(sensorName: subPair[0]) else {       // Find the sensor with this tag
                    callback(nil, PlatformError.custom(message: "Unknown sensor:[\(subPair[0])] detected"))
                    return
                }
                    let battPair = subPair[1].components(separatedBy: "|")                      // We're going to get something like this "993.0|--" for the observation / battery health
                    filteredSensor.updateMeasurement(newMeasurement: MeteoObservation(value: battPair[0], time: timeCollect))     // Record the observation
                    filteredSensor.updateBatteryHealth(observation: battPair[1])                // Record the battery health
                }
            }
            
            callback(self, nil)
        })
    }
}
