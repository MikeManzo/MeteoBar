//
//  WeatherPlatform.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/18/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftyJSON

protocol Weather {
    func initializeBridgeSpecification(ipAddress: String, bridgeName: String, callback: @escaping (_ station: Meteobridge?, _ error: Error?) -> Void)
}

extension Weather {
    func initializeBridgeSpecification(ipAddress: String, bridgeName: String, callback: @escaping (_ station: Meteobridge?, _ error: Error?) -> Void) {
        WeatherPlatform.shared.initializeBridgeSpecification(ipAddress: ipAddress, bridgeName: bridgeName, callback: { _, _ in })
    }
}

enum WeatherPlatformError: Error, CustomStringConvertible {
    case jsonModelError
    
    var description: String {
        switch self {
        case .jsonModelError: return "Error reading Meteobridge configuration file"
        }
    }
}

/// Singleton "Platform" to interact with the rest of the weather model(s)
class WeatherPlatform: Weather {
    static let shared = WeatherPlatform()
    
    /// Private init for the singleton
    private init() { }
  
    /// Based on th JSON model(s) in the "/Config" directory, build the represetnation of the Meteobridge that we can use throughout the app
    ///
    /// Our Structure for the model is as follows
    /// [0] <-- Only sensor group "Zero" is supported
    ///     Then we have the categories for the group (Currently, 7: Temp, Humidity, Pressure, Wind, Rain, Solar, Energy)
    ///     Once we get the category, we want to look at each sensor available for that category
    ///     In the nested for loops below, we have the following
    ///     [0]
    ///         sensor.0 <-- Sensor Name
    ///         sensor.1[0][<custom_tag>] <-- These are the child properties of the sensor
    ///         sensor.1[0]["supported_units"] <-- These are the child units that the sensor can support
    ///             unit.0 <-- Unit Name
    ///             unit.1[<custom_tag>] <-- These ar the child attributes of the supported unit
    ///
    /// - Parameters:
    ///   - ipAddress: ipAddress of the briegd we want to connect to
    ///   - bridgeName: name of the bridge (does not need to be unique)
    ///
    /// - Returns: fully constructed Meteobridge object (our model)
    ///
    func initializeBridgeSpecification(ipAddress: String, bridgeName: String, callback: @escaping (_ station: Meteobridge?, _ error: Error?) -> Void) {
        var theBridge: Meteobridge?
        
        do {
            let path = Bundle.main.resourcePath! + "/Config"
            let fileManager = FileManager.default
            let bridgeConfigs = try fileManager.contentsOfDirectory(atPath: path)
            
            for bridge in bridgeConfigs {
                if let file = Bundle.main.url(forResource: bridge, withExtension: nil, subdirectory: "/Config") {
                    
                    Alamofire.request(file).responseJSON { jsonResponse in
                        switch jsonResponse.result {
                        case .success(let jsonModel):   // JSON Read Successful
                            var bridgeModel: JSON = JSON(jsonModel)
                            
                            theBridge = Meteobridge(bridgeIP: ipAddress, bridgeName: bridgeName)
                            
                            for (category, sensors) in bridgeModel["sensors"]["0"] {    // <-- Sensor 0
                                for sensor in sensors {                                 // <-- Categoruies (e.g., Temperature, wind, etc.)
                                    let theSensor = MeteobridgeSensor(sensorName: sensor.0, sensorCat: MeteoSensorCategory(rawValue: category)!,
                                                                      isSensorOutdoor: sensor.1[0]["outdoor"].bool!, batteryParam: sensor.1[0]["battery_parameter"].string!,
                                                                      info: sensor.1[0]["description"].string!)
                                    
                                    for unit in sensor.1[0]["supported_units"] {        // <-- Compatible Units
                                        theSensor.addSuppoortedUnit(unit: MeteoSensorUnit(unitName: unit.0, unitParam: unit.1["parameter"].string!,
                                                                                          unitRep: unit.1["unit"].string!, unitDefault: unit.1["default"].bool!))
                                    }
                                    theBridge?.addSensor(sensor: theSensor)
                                }
                            }
                            callback (theBridge, nil)                                   // <-- We're finished; we should return the populated Meteobridge object
                        case .failure(let error):   // JSON Read Failed
                            callback(nil, error)
                        }
                    }
                }
            }
            
        } catch {
            callback(nil, PlatformError.passthroughSystem(systemError: error))
        }
    }
}
