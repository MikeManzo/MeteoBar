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
    func initializeBridgeSpecification(ipAddress: String, bridgeName: String) -> Meteobridge?
}

extension Weather {
    func initializeBridgeSpecification(ipAddress: String, bridgeName: String) -> Meteobridge? {
        return WeatherPlatform.shared.initializeBridgeSpecification(ipAddress: ipAddress, bridgeName: bridgeName)
    }
}

/// Singleton "Platform" to interact with the rest of the weather model(s)
class WeatherPlatform: Weather {
    static let shared = WeatherPlatform()
    
    /// Private init for the singleton
    private init() { }
  
    /// Based on th JSON model(s) in the "/Config" directory, build the represetnation of the Meteobridge that we can use throughout the app
    ///
    /// - Parameters:
    ///   - ipAddress: ipAddress of the briegd we want to connect to
    ///   - bridgeName: name of the bridge (does not need to be unique)
    ///
    /// - Returns: fully constructed Meteobridge object (our model)
    func initializeBridgeSpecification(ipAddress: String, bridgeName: String) -> Meteobridge? {
        var theBridge: Meteobridge?
        
        do {
            let path = Bundle.main.resourcePath! + "/Config"
            let fileManager = FileManager.default
            let bridgeConfigs = try fileManager.contentsOfDirectory(atPath: path)
            
            for bridge in bridgeConfigs {
                if let file = Bundle.main.url(forResource: bridge, withExtension: nil, subdirectory: "/Config") {
                    
                    Alamofire.request(file).responseJSON { jsonResponse in
                        switch jsonResponse.result {
                        case .success(let jsonModel):
                            var bridgeModel: JSON = JSON(jsonModel)
                            
                            theBridge = Meteobridge(bridgeIP: ipAddress, bridgeName: bridgeName)
                            
                            for (category, sensors) in bridgeModel["sensors"]["0"] {   // <-- Sensor 0
                                log.info("Categpry:\(category)")
                                for sensor in sensors {                                 // <-- Categoruies (e.g., Temperature, wind, etc.)
                                    log.info("\t\tSensor:\(sensor.0) -> Desc: \(sensor.1[0]["description"]) -> Type: \(sensor.1[0]["type"]) -> Outdoor: \(sensor.1[0]["outdoor"]) -> Param: \(sensor.1[0]["battery_parameter"])")
                                    
                                    let theSensor = MeteobridgeSensor(sensorName: sensor.0, sensorCat: MeteoSensorCategory(rawValue: category)!,
                                                                      isSensorOutdoor: sensor.1[0]["outdoor"].bool!, batteryParam: sensor.1[0]["battery_parameter"].string!)
                                    
                                    for unit in sensor.1[0]["supported_units"] {        // <-- Compatible Units
                                        log.info("\t\t\tUnit Name:\(unit.0) -> Rep: \(unit.1["unit"]) -> Param: \(unit.1["parameter"]) -> Default: \(unit.1["default"])")
                                        theSensor.addSuppoortedUnit(unit: MeteoSensorUnit(unitName: unit.0, unitParam: unit.1["parameter"].string!,
                                                                                          unitRep: unit.1["unit"].string!, unitDefault: unit.1["default"].bool!))
                                    }
                                    theBridge?.addSensor(sensor: theSensor)
                                }
                            }
                            log.info("Made it")
                        case .failure(let error):
                            log.error(error)
                            return
                        }
                    }
                }
            }
            
        } catch {
            log.error("Error reading Meteobridge configuration file. [Message]-->\(error)")
        }
        
        return theBridge
    }
}
