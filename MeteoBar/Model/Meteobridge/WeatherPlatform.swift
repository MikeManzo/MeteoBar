//
//  WeatherPlatform.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/18/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa
import Alamofire
import AlamofireImage
import SwiftyJSON

protocol Weather {
    func initializeBridgeSpecification(ipAddress: String, bridgeName: String, callback: @escaping (_ station: Meteobridge?, _ error: Error?) -> Void)
    func getConditions(theBridge: Meteobridge, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void)
    func findSensorInBridge(searchID: String) -> MeteobridgeSensor?
}

extension Weather {
    func initializeBridgeSpecification(ipAddress: String, bridgeName: String, callback: @escaping (_ station: Meteobridge?, _ error: Error?) -> Void) {
        WeatherPlatform.shared.initializeBridgeSpecification(ipAddress: ipAddress, bridgeName: bridgeName, callback: { _, _ in })
    }
    
    func getConditions(theBridge: Meteobridge, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void) {
        WeatherPlatform.shared.getConditions(theBridge: theBridge, callback: { _, _ in })
    }
    
    func findSensorInBridge(searchID: String) -> MeteobridgeSensor? {
        return WeatherPlatform.shared.findSensorInBridge(searchID: searchID)
    }
}

enum WeatherPlatformError: Error, CustomStringConvertible {
    case jsonModelError
    case urlError
    case platformImageError
    case noLatitudeSet
    case noLongitudeSet
    
    var description: String {
        switch self {
        case .jsonModelError: return "Error reading Meteobridge configuration file"
        case .urlError: return "Failed to form proper URL to retrieve Meteobridge parameters"
        case .platformImageError: return "Failed to retrieve platform image"
        case .noLatitudeSet: return "No value for Latitude found in Meteobridge"
        case .noLongitudeSet: return "No value for Longitude found in Meteobridge"
        }
    }
}

/// Singleton "Platform" to interact with the rest of the weather model(s)
class WeatherPlatform: Weather {
    static let shared = WeatherPlatform()
    static let fireTimeOut = TimeInterval(15)
    
    /// Private init for the singleton
    private init() { }

    /// Get current readings from the meteobridge
    ///
    /// - Parameters:
    ///   - theBridge: the Meteobridge we wish to interrogate
    ///   - callback: callback to recieve the results
    ///
    func getConditions(theBridge: Meteobridge, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void) {
        let alamoManager = Alamofire.SessionManager.default
        alamoManager.session.configuration.timeoutIntervalForRequest     = WeatherPlatform.fireTimeOut
        alamoManager.session.configuration.timeoutIntervalForResource    = WeatherPlatform.fireTimeOut
        var templateString = "Time:[hh];[mm];[ss],"
        
        for (category, sensors) in theBridge.sensors {
            for sensor in sensors where category != .system  && sensor.isObserving {
                templateString.append("\(sensor.bridgeTemplate),")
            }
        }
        
        templateString = String(templateString[..<templateString.index(before: templateString.endIndex)])   // Remove the trailing ","
        templateString = templateString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!     // May contain spaces
        
        guard let bridgeEndpoint: URL = URL(string: "http://\(theBridge.ipAddress)/cgi-bin/template.cgi?template=\(templateString)") else {
            callback(nil, WeatherPlatformError.urlError)
            return
        }
        
        alamoManager.request(bridgeEndpoint).responseData { bridgeResponse in
            switch bridgeResponse.result {
            case .success (let stationData):
                callback(stationData as AnyObject, nil)
            case .failure(let stationError):
                callback(nil, PlatformError.passthroughSystem(systemError: stationError))
            }
        }
    }
    
    /// Get all supported system paramaters from the meteobridge
    ///
    /// - Parameters:
    ///   - theBridge: the Meteobridge we wish to interrogate
    ///   - callback: callback to recieve the results
    ///
    func getAllSupportedSystemParameters(theBridge: Meteobridge, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void) {
        let alamoManager = Alamofire.SessionManager.default
        alamoManager.session.configuration.timeoutIntervalForRequest     = WeatherPlatform.fireTimeOut
        alamoManager.session.configuration.timeoutIntervalForResource    = WeatherPlatform.fireTimeOut
        var templateString = "Time|[hh];[mm];[ss],"
        
        for (category, sensors) in theBridge.sensors {
            for sensor in sensors where category == .system {
                templateString.append("\(sensor.bridgeTemplate),")
            }
        }
        
        templateString = String(templateString[..<templateString.index(before: templateString.endIndex)])   // Remove the trailing ","
        templateString = templateString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!     // May contain spaces
        
        guard let bridgeEndpoint: URL = URL(string: "http://\(theBridge.ipAddress)/cgi-bin/template.cgi?template=\(templateString)") else {
            callback(nil, WeatherPlatformError.urlError)
            return
        }
        
        alamoManager.request(bridgeEndpoint).responseData { bridgeResponse in
            switch bridgeResponse.result {
            case .success (let stationData):
                callback(stationData as AnyObject, nil)
            case .failure(let stationError):
                callback(nil, PlatformError.passthroughSystem(systemError: stationError))
            }
        }
    }
    
    /// Get parameter "X: from the bridge
    ///
    /// - Parameters:
    ///   - theBridge: the Meteobridge we wish to interrogate
    ///   - param: the paramater we wish to get
    ///   - callback: callback to recieve the results
    ///
    func getBridgeParameter(theBridge: Meteobridge, param: MeteobridgeSystemParameter, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void) {
        let alamoManager = Alamofire.SessionManager.default
        alamoManager.session.configuration.timeoutIntervalForRequest     = WeatherPlatform.fireTimeOut
        alamoManager.session.configuration.timeoutIntervalForResource    = WeatherPlatform.fireTimeOut
        var templateString = "Time:[hh];[mm];[ss],"
       
        guard let sensor = (theBridge.sensors[.system]?.filter {$0.name == param.rawValue}.first) else {
            callback(nil, WeatherPlatformError.urlError)
            return
        }
        
        templateString.append("\(sensor.bridgeTemplate)")
        
        guard let bridgeEndpoint: URL = URL(string: "http://\(theBridge.ipAddress)/cgi-bin/template.cgi?template=\(templateString)") else {
            callback(nil, WeatherPlatformError.urlError)
            return
        }
        
        alamoManager.request(bridgeEndpoint).responseData { bridgeResponse in
            switch bridgeResponse.result {
            case .success (let stationData):
                callback(stationData as AnyObject, nil)
            case .failure(let stationError):
                callback(nil, PlatformError.passthroughSystem(systemError: stationError))
            }
        }
    }
    
    /// Based on the JSON model(s) in the "/Config" directory, build the represetnation of the Meteobridge that we can use throughout the app
    ///
    /// Our Structure for the model is as follows
    ///
    /// Instruments
    /// Simmplistic structure
    /// log.info("Sensor:\(sensor) --> Info:\(data[0]["description"]) -> Info:\(data[0]["type"]) -> Param:\(data[0]["parameter"])")
    ///
    /// [0] <-- Only weather sensor group "Zero" is supported
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
                            
                            /// System Sensors
                            for (sensor, data) in bridgeModel["system"]["instruments"] {    // Process System Sensors
                                let theSensor = MeteobridgeSensor(sensorName: sensor, sensorCat: MeteoSensorCategory(rawValue: data[0]["type"].string!)!,
                                                                  isSensorOutdoor: false, batteryParam: data[0]["parameter"].string!,
                                                                  info: data[0]["description"].string!)
                                theBridge?.addSensor(sensor: theSensor)
                            } /// System Sensors
                            
                            /// Weather Sensors
                            for (category, sensors) in bridgeModel["sensors"]["0"] {        // <-- Process Weather Sensors, which are at ["0"]
                                for sensor in sensors {                                     // <-- Categoruies (e.g., Temperature, wind, etc.)
                                    let theSensor = MeteobridgeSensor(sensorName: sensor.0, sensorCat: MeteoSensorCategory(rawValue: category)!,
                                                                      isSensorOutdoor: sensor.1[0]["outdoor"].bool!, batteryParam: sensor.1[0]["battery_parameter"].string!,
                                                                      info: sensor.1[0]["description"].string!)
                                    
                                    for unit in sensor.1[0]["supported_units"] {            // <-- Process the Compatible Units
                                        theSensor.addSuppoortedUnit(unit: MeteoSensorUnit(unitName: unit.0, unitParam: unit.1["parameter"].string!,
                                                                                          unitMax: unit.1["dayMax"].string!, unitMin: unit.1["dayMin"].string!,
                                                                                          unitRep: unit.1["unit"].string!, unitDefault: unit.1["default"].bool!))
                                    }
                                    theBridge?.addSensor(sensor: theSensor)
                                }
                            } /// Weather Sensors
                            callback (theBridge, nil)                                       // <-- We're finished; we should return the populated Meteobridge object
                        case .failure(let jsonError):   // JSON Read Failed
                            callback(nil, jsonError)
                        }
                    }
                }
            }
            
        } catch {
            callback(nil, PlatformError.passthroughSystem(systemError: error))
        }
    }
    
    /// Find a particular sensor in the Bridge
    ///
    /// - Parameter searchID: ID to search for
    /// - Returns: fully formed Meteobridge Sensor ... or nil if nothing was found
    ///
    func findSensorInBridge(searchID: String) -> MeteobridgeSensor? {
        var foundSensor: MeteobridgeSensor?
        
        guard let theBridge = theDelegate?.theBridge else {
            return foundSensor
        }
        
        for (_, sensors) in (theBridge.sensors) {
            foundSensor = sensors.filter {
                $0.sensorID == searchID }.first
            if foundSensor != nil {
                break
            }
        }
        
        return foundSensor
    }
    
    /// Grab Platform Image based on platform type
    ///
    /// # Usage #
    ///  getPlatformImage("image") { (image, error) in
    ///        if image != nil {
    ///            print(image)
    ///        }
    ///  }
    /// - Parameters:
    ///   - platform: string representation of platform
    ///   - callback: callback to return the image to
    ///
    func getPlatformImage(_ platform: String, handler: @escaping (NSImage?, Error?) -> Void) {
        let alamoManager = Alamofire.SessionManager.default
        alamoManager.session.configuration.timeoutIntervalForRequest     = WeatherPlatform.fireTimeOut
        alamoManager.session.configuration.timeoutIntervalForResource    = WeatherPlatform.fireTimeOut

        guard let ipAddress = theDelegate?.theBridge?.ipAddress else {
            handler(nil, WeatherPlatformError.platformImageError)
            return
        }
        
        let imgURL = "http://\(ipAddress)\(platformImages[platform]!)"
        
        alamoManager.request(imgURL).responseImage { response in
            guard let image = response.result.value else {
                handler(nil, WeatherPlatformError.platformImageError)
                return
            }
            handler(image, nil)
        }
    }
}
