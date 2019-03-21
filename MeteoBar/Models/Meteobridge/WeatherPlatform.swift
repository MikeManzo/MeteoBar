//
//  WeatherPlatform.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/18/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import AlamofireImage
import SwiftyJSON
import Alamofire
import Cocoa
import MapKit

enum WeatherPlatformError: Error, CustomStringConvertible {
    case NWSPolygonForecastZoneError
    case NWSPolygonCountyZoneError
    case NWSMalformedDataError
    case platformImageError
    case NWSEndpointError
    case jsonModelError
    case noLongitudeSet
    case NWSAlertsError
    case noLatitudeSet
    case NWSZoneError
    case urlError
    
    var description: String {
        switch self {
        case .NWSEndpointError: return "Cannot retrieve forecast endpoints from the U.S. NAtional Weather Service"
        case .NWSMalformedDataError: return "Unable to read the alert data from the U.S. National Weather Service"
        case .NWSPolygonForecastZoneError: return "Cannot determine polygon enclosing your forecast zone"
        case .NWSAlertsError: return "Unable to determine alerts from the U.S. National Weather Service"
        case .NWSZoneError: return "Cannot retrieve alert zone from the U.S. NAtional Weather Service"
        case .NWSPolygonCountyZoneError: return "Cannot determine polygon enclosing your county zone"
        case .urlError: return "Failed to form proper URL to retrieve Meteobridge parameters"
        case .jsonModelError: return "Error reading Meteobridge configuration file"
        case .noLongitudeSet: return "No value for Longitude found in Meteobridge"
        case .noLatitudeSet: return "No value for Latitude found in Meteobridge"
        case .platformImageError: return "Failed to retrieve platform image"
        }
    }
}

/// Protocol for future use
protocol Weather: class {
    static func getNWSZones(lat: Double, lon: Double, responseHandler: @escaping (_ forecastZone: String?, _ countyZone: String?, _ radar: String?, _ point: NSPoint?, _ error: Error?) -> Void)
    static func getNWSPolygon(forecastZone: String, countyZone: String, responseHandler: @escaping (_ forecastZone: MKMeteoPolyline?, _ countyZone: MKMeteoPolyline?,_ error: Error?) -> Void)
    static func getNWSForecastEndpoints(lat: Double, lon: Double, responseHandler: @escaping (_ city: String?, _ forecast: String?, _ forecastHourly: String?, _ error: Error?) -> Void)
    static func getBridgeParameter(theBridge: Meteobridge, param: MeteobridgeSystemParameter, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void)
    static func getConditionsForSensor(theBridge: Meteobridge, sensor: MeteobridgeSensor, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void)
    static func initializeBridgeSpecification(ipAddress: String, bridgeName: String, callback: @escaping (_ station: Meteobridge?, _ error: Error?) -> Void)
    static func getConditions(theBridge: Meteobridge, allParamaters: Bool, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void)
    static func getAllSupportedSystemParameters(theBridge: Meteobridge, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void)
    static func getPlatformImage(_ platform: String, handler: @escaping (NSImage?, Error?) -> Void)
    static func findSensorInBridge(searchID: String) -> MeteobridgeSensor?
}

/// Static "Platform" to interact with the rest of the weather model(s)
class WeatherPlatform: Weather {
    static var nwsEndPoint: String {get {return "https://api.weather.gov"}} // Static endpoint for the NWS service
    static var fireTimeOut: TimeInterval {get {return TimeInterval(15)}}    // Use 15 seconds as the default for all network timeouts

    /// Get current readings from the meteobridge
    ///
    /// - Parameters:
    ///   - theBridge:      the Meteobridge we wish to interrogate
    ///   - allParamaters:  do we want to ignore the isObserving flag and just get them all?
    ///   - callback:       callback to recieve the results
    ///
    static func getConditions(theBridge: Meteobridge, allParamaters: Bool = false, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void) {
        let alamoManager = Alamofire.SessionManager.default
        alamoManager.session.configuration.timeoutIntervalForRequest     = fireTimeOut
        alamoManager.session.configuration.timeoutIntervalForResource    = fireTimeOut
        var templateString = "Time:[hh];[mm];[ss],"
        
        if !allParamaters {
            for (category, sensors) in theBridge.sensors {
                for sensor in sensors where category != .system  && sensor.isObserving {
                    templateString.append("\(sensor.bridgeTemplate),")
                }
            }
        } else {
            for (category, sensors) in theBridge.sensors {
                for sensor in sensors where category != .system {
                    templateString.append("\(sensor.bridgeTemplate),")
                }
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
    
    /// Get current readings for the given sensor on teh given bridge
    ///
    /// - Parameters:
    ///   - theBridge:  the Meteobridge we wish to interrogate
    ///   - sensor:     the sensor to get data for
    ///   - callback:   callback to recieve the results
    ///
    static func getConditionsForSensor(theBridge: Meteobridge, sensor: MeteobridgeSensor, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void) {
        let alamoManager = Alamofire.SessionManager.default
        alamoManager.session.configuration.timeoutIntervalForRequest     = fireTimeOut
        alamoManager.session.configuration.timeoutIntervalForResource    = fireTimeOut
        var templateString = "Time:[hh];[mm];[ss],"
        
        templateString.append("\(sensor.bridgeTemplate)")
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
    static func getAllSupportedSystemParameters(theBridge: Meteobridge, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void) {
        let alamoManager = Alamofire.SessionManager.default
        alamoManager.session.configuration.timeoutIntervalForRequest     = fireTimeOut
        alamoManager.session.configuration.timeoutIntervalForResource    = fireTimeOut
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
    static func getBridgeParameter(theBridge: Meteobridge, param: MeteobridgeSystemParameter, callback: @escaping (_ response: AnyObject?, _ error: Error?) -> Void) {
        let alamoManager = Alamofire.SessionManager.default
        alamoManager.session.configuration.timeoutIntervalForRequest     = fireTimeOut
        alamoManager.session.configuration.timeoutIntervalForResource    = fireTimeOut
        var templateString = "Time|[hh];[mm];[ss],"
       
        guard let sensor = (theBridge.sensors[.system]?.filter {$0.name == param.rawValue}.first) else {
            callback(nil, WeatherPlatformError.urlError)
            return
        }
        
        templateString.append("\(sensor.bridgeTemplate)")
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
    static func initializeBridgeSpecification(ipAddress: String, bridgeName: String, callback: @escaping (_ station: Meteobridge?, _ error: Error?) -> Void) {
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
    static func findSensorInBridge(searchID: String) -> MeteobridgeSensor? {
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
    static func getPlatformImage(_ platform: String, handler: @escaping (NSImage?, Error?) -> Void) {
        let alamoManager = Alamofire.SessionManager.default
        alamoManager.session.configuration.timeoutIntervalForRequest     = fireTimeOut
        alamoManager.session.configuration.timeoutIntervalForResource    = fireTimeOut

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
    
    ///
    /// Parse the NWS weather end point for the Zones
    /// We'll use this for alerts and forecasts
    ///
    /// ## Important Notes ##
    /// 1. Example: [VAZ505](https://api.weather.gov/points/lat,lon)
    ///
    /// - Parameters:
    ///   - Parameter lat: Latitude of the station
    ///   - Parameter lon: Longitude of the station
    ///   - Parameter responseHandler: The Callback
    ///
    /// - throws: Nothing
    /// - returns:
    ///   - forecastZone: NWS forecast Zone
    ///   - countyZone: NWS county Zone
    ///   - radar: NWS Radar Station
    ///   - point: Grid Point for zone(s)
    ///   - error: error message (nil if succesful)
    ///
    static func getNWSZones(lat: Double, lon: Double, responseHandler: @escaping (_ forecastZone: String?, _ countyZone: String?, _ radar: String?, _ point: NSPoint?, _ error: Error?) -> Void) {
        let stationEndpoint = URL(string: "\(nwsEndPoint)/points/\(lat),\(lon)")
        var grid = NSPoint(x: 0, y: 0)
        var forecastZone: String?
        var countyZone: String?
        var radar: String?
        
        Alamofire.request(stationEndpoint!).responseJSON { response in
            switch response.result {
            case .success(let retJSON):
                var data: JSON = JSON(retJSON)
                grid.x          = CGFloat(Int(data["properties"]["gridX"].stringValue)!)
                grid.y          = CGFloat(Int(data["properties"]["gridY"].stringValue)!)
                forecastZone    = data["properties"]["forecastZone"].stringValue
                radar           = data["properties"]["radarStation"].stringValue
                countyZone      = data["properties"]["county"].stringValue

                // the forecast zone is formatted like this: "https://api.weather.gov/zones/forecast/VAZ505"
                // we need to trim the string to just get the zone
                if let theForecastRange = forecastZone?.range(of: "/", options: .backwards) {
                    forecastZone = String(forecastZone![theForecastRange.upperBound...])
                } else {
                    forecastZone = "*****"
                }

                // the county zone is formatted like this: "https://api.weather.gov/zones/forecast/VAC107"
                // we need to trim the string to just get the zone
               if let theCountyRange = countyZone?.range(of: "/", options: .backwards) {
                    countyZone = String(countyZone![theCountyRange.upperBound...])
                } else {
                    countyZone = "*****"
                }
                
                responseHandler(forecastZone, countyZone, radar, grid, nil)
            case .failure:
                responseHandler("*****", "*****", "***", grid, WeatherPlatformError.NWSZoneError)
            }
        }
    }
    
    ///
    /// Parse the NWS weather end point for endpoints
    /// We'll use this for alerts and forecasts
    ///
    /// ## Important Notes ##
    /// 1. Example: [VAZ505](https://api.weather.gov/points/lat,lon)
    ///
    /// - Parameters:
    ///   - Parameter lat: Latitude of the station
    ///   - Parameter lon: Longitude of the station
    ///   - Parameter responseHandler: The Callback
    ///
    /// - throws: Nothing
    /// - returns:
    ///   - city: closest city to lat/lon provided
    ///   - forecast: URL For Forecast
    ///   - forecastHourly: URL For Hourly Forrecast
    ///   - error: error message (nil if succesful)
    ///
    static func getNWSForecastEndpoints(lat: Double, lon: Double, responseHandler: @escaping (_ city: String?, _ forecast: String?, _ forecastHourly: String?, _ error: Error?) -> Void) {
        let stationEndpoint = URL(string: "\(nwsEndPoint)/points/\(lat),\(lon)")
        var forecastHourly: String?
        var forecast: String?
        var city: String?
        
        Alamofire.request(stationEndpoint!).responseJSON { response in
            switch response.result {
            case .success(let retJSON):
                var data: JSON = JSON(retJSON)
                forecast        = data["properties"]["forecast"].stringValue
                forecastHourly  = data["properties"]["forecastHourly"].stringValue
                city            = data["properties"]["relativeLocation"]["properties"]["city"].stringValue
                
                responseHandler(city, forecast, forecastHourly, nil)
            case .failure:
                responseHandler("** UNKNOWN **", "*****", "*****", WeatherPlatformError.NWSEndpointError)
            }
        }
    }
    
    ///
    /// Parse the NWS weather end point for endpoints
    /// We'll use this for alerts and forecasts
    ///
    /// ## Important Notes ##
    /// 1. Example: [VAZ505](https://api.weather.gov/zones/forecast/VAZ505)
    ///
    /// - Parameters:
    ///   - Parameter forecastEndpoint: NWS endpoint for forecast zone polygon
    ///   - Parameter lon: Longitude of the station
    ///   - Parameter responseHandler: The Callback
    ///
    /// - throws: Nothing
    /// - returns:
    ///   - forecastZone: MKMeteoPolyline array representing the forecast zone
    ///   - countyZone: MKMeteoPolyline array repreenting the county zone
    ///   - error: error message (nil if succesful)
    ///
    static func getNWSPolygon(forecastZone: String, countyZone: String,
                              responseHandler: @escaping (_ forecastZone: MKMeteoPolyline?, _ countyZone: MKMeteoPolyline?,_ error: Error?) -> Void) {
        let forecastEndpoint    = URL(string: "\(nwsEndPoint)/zones/forecast/\(forecastZone)")
        let zoneEndpoint        = URL(string: "\(nwsEndPoint)/zones/county/\(countyZone)")
        var forecastZonePoly: MKMeteoPolyline?
        var countyZonePoly: MKMeteoPolyline?

        Alamofire.request(forecastEndpoint!).responseJSON { response in
            switch response.result {
            case .success(let retJSON):
                var retData: JSON = JSON(retJSON)
                var forecastPoints = [CLLocationCoordinate2D]()
                
                if let coordinates: Array = retData["geometry"]["coordinates"][0][0].array {
                    for coordinate in coordinates {
                        forecastPoints.append(CLLocationCoordinate2D(latitude: coordinate[1].double!, longitude: coordinate[0].double!))
                    }
                }
                forecastZonePoly = MKMeteoPolyline(coordinates: forecastPoints)
                
                Alamofire.request(zoneEndpoint!).responseJSON { response in
                    switch response.result {
                    case .success(let retJSON):
                        var retData: JSON = JSON(retJSON)
                        var countyPoints = [CLLocationCoordinate2D]()

                        if let coordinates: Array = retData["geometry"]["coordinates"][0][0].array {
                            for coordinate in coordinates {
                                countyPoints.append(CLLocationCoordinate2D(latitude: coordinate[1].double!, longitude: coordinate[0].double!))
                            }
                        }
                        countyZonePoly = MKMeteoPolyline(coordinates: countyPoints)

                        responseHandler(forecastZonePoly, countyZonePoly, nil)
                    case .failure: // Zone Failure
                        responseHandler(forecastZonePoly, countyZonePoly, WeatherPlatformError.NWSPolygonCountyZoneError)
                    }
                }
            case .failure:  // Forecast Failure
                responseHandler(forecastZonePoly, countyZonePoly, WeatherPlatformError.NWSPolygonForecastZoneError)
            }
        }
    }
    
    ///
    /// Parse the NWS weather end point for the "Daily Forecast"
    ///
    /// ## Important Notes ##
    /// - [Exammple](https://api.weather.gov/alerts/active/zone/VAZ505)
    /// - [All Alerts](https://api.weather.gov/alerts/active)
    ///
    /// ## Notes ##
    /// The Feature Array will be the key to the creation of any alerts
    ///
    /// - Parameters:
    ///   - Parameter station: the Meteobridge of interest
    ///
    /// - throws: Nothing
    /// - returns:  An array of weather alerts
    ///
    static func getNWSAlerts(theBridge: Meteobridge, responseHandler: @escaping (_ response: [MeteoWeatherAlert]?, _ error: Error?) -> Void) {
        guard let usModel = theBridge.weatherModel as? MeteoUSWeather else {
            responseHandler(nil, WeatherPlatformError.NWSAlertsError)
            return
        }
        let stationEndpoint = URL(string: "\(nwsEndPoint)/alerts/active/zone/\(usModel.forecastZoneID)")
//        let stationEndpoint = URL(string: "\(nwsEndPoint)/alerts/active/zone/NEC155")   ///  TESTING!!!!!!

        Alamofire.request(stationEndpoint!).responseJSON { response in
            switch response.result {
            case .success(let retJSON):
                let data: JSON = JSON(retJSON)
                var alerts = [MeteoWeatherAlert]()
                
                for property in data["features"] {
                    guard let myEffectiveDate = property.1["properties"]["effective"].stringValue as String?,
                        let myDescription = property.1["properties"]["description"].stringValue as String?,
                        let myInstruction = property.1["properties"]["instruction"].stringValue as String?,
                        let myMessageType = property.1["properties"]["messageType"].stringValue as String?,
                        let myCertainty = property.1["properties"]["certainty"].stringValue as String?,
                        let myExpireDate = property.1["properties"]["expires"].stringValue as String?,
                        let myCategory = property.1["properties"]["category"].stringValue as String?,
                        let mySeverity = property.1["properties"]["severity"].stringValue as String?,
                        let myHeadline = property.1["properties"]["headline"].stringValue as String?,
                        let myStartDate = property.1["properties"]["onset"].stringValue as String?,
                        let myUrgency = property.1["properties"]["urgency"].stringValue as String?,
                        let myDesc = property.1["properties"]["areaDesc"].stringValue as String?,
                        let mySendDate = property.1["properties"]["sent"].stringValue as String?,
                        let myStatus = property.1["properties"]["status"].stringValue as String?,
                        let mySender = property.1["properties"]["sender"].stringValue as String?,
                        let myEndDate = property.1["properties"]["ends"].stringValue as String?,
                        let myEvent = property.1["properties"]["event"].stringValue as String?,
                        let myType = property.1["properties"]["@type"].stringValue as String?,
                        let myID = property.1["properties"]["id"].stringValue as String?
                        
                        else {
                            responseHandler(nil, WeatherPlatformError.NWSMalformedDataError)
                            return
                        }
                    
                    var referenceIDs = [String]()
                    for reference in property.1["properties"]["references"] {
                        referenceIDs.append(reference.1["identifier"].stringValue)
                    }
                    
                    let newAlert = MeteoWeatherAlert(anID: myID, aType: myType, aDesc: myDesc, sentAt: mySendDate.toISODate(),
                                                     effectiveTill: myEffectiveDate.toISODate(), willStart: myStartDate.toISODate(),
                                                     willEnd: (!myEndDate.isEmpty) ? myEndDate.toISODate() : myExpireDate.toISODate(),
                                                     willExpire: myExpireDate.toISODate(), aStatus: myStatus,
                                                     aMessageType: MeteoAlertMessageType(rawValue: myMessageType)!,
                                                     aSeverity: MeteoAlertSeverity(rawValue: mySeverity)!,
                                                     aCategory: myCategory, aCertainty: MeteoAlertCertainty(rawValue: myCertainty)!,
                                                     anUrgency: MeteoAlertUrgency(rawValue: myUrgency)!,
                                                     anEvent: myEvent, aHeadline: myHeadline, aSender: mySender,
                                                     aDetail: myDescription, anInstruction: myInstruction, references: referenceIDs)
                    
                    alerts.append(newAlert)
                }
                responseHandler(alerts, nil)
            case .failure(let error):
                responseHandler(nil, error)
            }
        }
    }
}
