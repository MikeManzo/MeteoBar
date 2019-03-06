//
//  Meteobridge.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/18/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import SwiftyUserDefaults
import MapKit
import Cocoa

enum MeteobridgeError: Error, CustomStringConvertible {
    case observationDateError
    case observationError
    case unknownSensor
    case dataError
    case weatherModelError
    case unknownModel
    
    var description: String {
        switch self {
        case .observationError: return "Error reading observation from Meteobridge"
        case .dataError: return "Error reading data from Meteobridg"
        case .unknownSensor: return "Unknown sensor detected"
        case .observationDateError: return "Unbale to determine timestamp for observation - observation skipped"
        case .weatherModelError: return "Unable to update weather model"
        case .unknownModel: return "Unknown Weather Model"
        }
    }
}

enum MeteobridgeSystemParameter: String {
    case mac
    case swversion
    case buildnum
    case platform
    case station
    case stationnum
    case timezone
    case altitude
    case latitude
    case longitude
    case lastgooddate
    case uptime
}

let platformImages = [
                        "TL-MR3020": "/meteobridge/pix/TL-MR3020.png",
                        "TL-WR902AC": "/meteobridge/pix/TL-WR902AC.png",
                        "TL-MR3020v3": "/meteobridge/pix/TL-MR3020V3.png",
                        "TL-WR703N": "/meteobridge/pix/TL-WR703N.png",
                        "WL-330N3G": "/meteobridge/pix/WL-330N3G.png",
                        "DIR-505": "/meteobridge/pix/DIR-505.png",
                        "TL-MR3040": "/meteobridge/pix/TL-MR3040.png",
                        "Meteobridge PRO": "/meteobridge/pix/mbpro.png"
                     ]

/*
 let stationImages = [

                    ]
*/

enum MeteobridgeCodingKeys: String, CodingKey {
    case updateInterval
    case weatherModel
    case ipAddress
    case sensors
    case cCode
    case name
    case uuid
}

///
/// As an homage to smartbedded, we will default the lat/lon to their headquarters.
/// Assuming the
/// [Location](https://www.google.com/maps/place/smartbedded+UG+(haftungsbeschränkt)/@53.8772027,9.8823447,16.99z/data=!4m5!3m4!1s0x0:0xc777d79da56902d4!8m2!3d53.8772!4d9.8845699)
///
final class Meteobridge: NSObject, Codable, Copyable, DefaultsSerializable, MKAnnotation {
    /// Properties
    var sensors = [MeteoSensorCategory: [MeteobridgeSensor]]()
    private var _weatherModel: MeteoWeather?
    private var _cCode: String
    var updateInterval: Int
    var ipAddress: String
    var uuid: String
    var name: String

    var weatherModel: MeteoWeather? {
        return _weatherModel
    }
   
    var forecastPolyLine: MKPolyline? {
        return _weatherModel?.forecastPolygon
    }
    
    var polygonOverlays: [String: MKPolyline] {
        var overlays = [String: MKPolyline]()
        
        switch countryCode {
        case "US":
            guard let model = weatherModel as? MeteoUSWeather else {
                break
            }
            // 1. Add the Forecast Polygon
            overlays["Forecast"] = model.forecastPolygon
            // 2. Add the County Polygon
            overlays["County"] = model.countyPolygon
            // 3. ToDo: Add the Alert Polygons
        default:
            overlays["Forecast"] = forecastPolyLine
        }
        return overlays
    }
    
    var countryCode: String {
        return _cCode
    }
    
    var isUnitedStates: Bool {
        return _cCode == "US" ? true : false
    }
    
    var totalSensors: Int {
        var numSensor = 0
        
        for (_, sensors) in sensors {
            for _ in sensors {
                numSensor += 1
            }
        }

        return numSensor
    }
    
    var latitude: Double {
        var lat = 53.877382 // Defaults to the latitude of smartbedded GmbH
        guard let sensor = (sensors[.system]?.filter {$0.name == "latitude"}.first) else {
            log.warning("Check Bridge Latitude.  Using Default longitude.  The Meteobridge is either not configured with a valid latitude or there is a different problem.")
            return lat
        }

        lat = (sensor.formattedMeasurement?.toDouble())!
        
        return lat
    }

    var longitude: Double {
        var lon = 9.884578 // Defaults to the longitude of smartbedded GmbH
        guard let sensor = (sensors[.system]?.filter {$0.name == "longitude"}.first) else {
            log.warning("Check Bridge longitude.  Using Default longitude.  The Meteobridge is either not configured with a valid longitude or there is a different problem.")
            return lon
        }
        
        lon = (sensor.formattedMeasurement?.toDouble())!
        
        return lon
    }
    
    /// Initialize the Meteobridge object
    ///
    /// - Parameters:
    ///   - bridgeIP: IP Address of the meteobridge
    ///   - bridgeName: the name we are giving the meteobridge
    ///   - bridgeSensors: the collection of sensors that this meteobridge has
    required init? (bridgeIP: String, bridgeName: String, bridgeSensors: [MeteoSensorCategory: [MeteobridgeSensor]]? = nil, uniqueID: String? = nil) {
        self.name           = bridgeName
        self.ipAddress      = bridgeIP
        self.updateInterval = 3
        self._cCode         = ""
        
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
        guard let copy = type(of: self).init(bridgeIP: self.ipAddress, bridgeName: self.name, bridgeSensors: self.sensors, uniqueID: self.uuid) else {
            _weatherModel = self._weatherModel
            return self
        }
        
        return copy
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
    
    /// Interrogate the bridge for system parameter "X"
    ///
    /// - Parameters:
    ///   - systemParam: parameter needed
    ///   - callback: return function
    ///
    func getSystemParameter(systemParam: MeteobridgeSystemParameter, callback: @escaping (_ theBridge: MeteobridgeSensor?, _ error: Error?) -> Void) {
        WeatherPlatform.getBridgeParameter(theBridge: self, param: systemParam, callback: { [unowned self] bridgeData, bridgeError in
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
                    guard let filteredSensor = self.findSensor(sensorName: subPair[0]) else {   // Find the sensor with this tag
                        callback(nil, PlatformError.custom(message: "Unknown sensor:[\(subPair[0])] detected"))
                        return
                    }
                    filteredSensor.updateMeasurement(newMeasurement: MeteoObservation(value: subPair[1], time: timeCollect))     // Record the observation
                    callback(filteredSensor, nil) // <-- Just return the filtered (and now populated) system sensor
                }
            }
//            callback(self, nil)
        })
    }
 
    /// Interrogate the bridge for all supported system parameters
    ///
    /// - Parameters:
    ///   - systemParam: parameter needed
    ///   - callback: return function
    ///
    func getAllSystemParameters(_ callback: @escaping (_ theBridge: Meteobridge?, _ error: Error?) -> Void) {
        WeatherPlatform.getAllSupportedSystemParameters(theBridge: self, callback: { [unowned self] bridgeData, bridgeError in
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
            guard let hourPair = timeArray[0].components(separatedBy: "|")  as Array? else {  // [0] = Time [1] = HH
                callback(nil, MeteobridgeError.observationError)
                return
            }
            guard let timeCollect = Calendar.current.date(bySettingHour: Int(hourPair[1])!, minute: Int(timeArray[1])!, second: Int(timeArray[2])!, of: Date())! as Date? else {
                callback(nil, MeteobridgeError.observationError)
                return
            }
            
            /// we're going to get something like this back for each sensor
            /// th0temp:[th0temp-act=.1:--]|[thb0temp-dmax=F.1:--]|[thb0temp-dmin=F.1:--]|[th0lowbat-act.0:--]
            /// Using the model below
            /// subPair[0] = Sensor Name
            /// subPair[1] = Measurement
            /// subPair[2] = Max measurment
            /// subPair[3] = Min Measurement
            /// subPair[4] = Battery
            for pair in bridgeResponse {
                let subPair = pair.components(separatedBy: "|")                                 // th0temp:30.4 <-- We want to break this into [0]th0temp & [1]30.4
                if subPair[0] != "Time" {
                    guard let filteredSensor = self.findSensor(sensorName: subPair[0]) else {   // Find the sensor with this tag
                        callback(nil, PlatformError.custom(message: "Unknown sensor:[\(subPair[0])] detected"))
                        return
                    }
                    filteredSensor.updateMeasurement(newMeasurement: MeteoObservation(value: subPair[1], time: timeCollect))     // Record the observation
                }
            }
            
            CLGeocoder.getCountryCode(lat: self.latitude, lon: self.longitude, { [unowned self] countryCode, error in
                if error == nil {
                    self._cCode = countryCode!
                }
                callback(self, error)
            })
            //            callback(self, nil)
        })
    }

    /// Interrogate the bridge for an observation of all present sensors
    ///
    /// ## Important Notes ##
    /// The data comes to us in a response array like
    /// 1. [0] == Time:12;00;00 <-- Always
    /// 2. [1] == THB0TEMP:29.9 <-- Optional
    /// 3. [2] == ... etc.
    ///
    /// We want to separate the keys and values so we can apply them to the appropriate sensors
    ///
    /// - Parameters:
    ///     - allParams:    do we want to grab everything and ignore the 'isObserving' flag?
    ///     - callback:     return function
    ///
    func getObservation(allParams: Bool = false, _ callback: @escaping (_ theBridge: Meteobridge?, _ error: Error?) -> Void) {
        WeatherPlatform.getConditions(theBridge: self, allParamaters: allParams, callback: { [unowned self] bridgeData, bridgeError in
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
            
            // Guard against poor data data
            if hourPair.count != 2 {
                log.warning("Meteobridge Timestamp returned:\(hourPair)")
                callback(nil, MeteobridgeError.observationDateError)
                return
            }
            // Guard against poor data data

            guard let timeCollect = Calendar.current.date(bySettingHour: Int(hourPair[1])!, minute: Int(timeArray[1])!, second: Int(timeArray[2])!, of: Date())! as Date? else {
                callback(nil, MeteobridgeError.observationError)
                return
            }
            
            /// we're going to get something like this back for each sensor
            /// th0temp:[th0temp-act=.1:--]|[thb0temp-dmax=F.1:--]|[thb0temp-dmin=F.1:--]|[th0lowbat-act.0:--]
            /// Using the model below
            /// battPair[0] = Measurement
            /// battPair[1] = Max measurment
            /// battPair[2] = Min Measurement
            /// battPair[3] = Battery
            for pair in bridgeResponse {
                let subPair = pair.components(separatedBy: ":")                                 // th0temp:30.4 <-- We want to break this into [0]th0temp & [1]30.4
                if subPair[0] != "Time" {
                guard let filteredSensor = self.findSensor(sensorName: subPair[0]) else {       // Find the sensor with this tag
                    callback(nil, PlatformError.custom(message: "Unknown sensor:[\(subPair[0])] detected"))
                    return
                }
                    let battPair = subPair[1].components(separatedBy: "|")                      // We're going to get something like this "993.0|--" for the observation / battery health
                    filteredSensor.updateMeasurement(newMeasurement: MeteoObservation(value: battPair[0], time: timeCollect),
                                                     maxMeasurement: MeteoObservation(value: battPair[1], time: timeCollect),
                                                     minMeasurement: MeteoObservation(value: battPair[2], time: timeCollect))     // Record the observation, max & min
                    filteredSensor.updateBatteryHealth(observation: battPair[3])                // Record the battery health
                }
            }
            callback(self, nil)
        })
    }

    /// Interrogate the bridge for an observation of the given sensors
    ///
    /// ## Important Notes ##
    /// The data comes to us in a response array like
    /// 1. [0] == Time:12;00;00 <-- Always
    /// 2. [1] == THB0TEMP:29.9 <-- Optional
    /// 3. [2] == ... etc.
    ///
    /// We want to separate the keys and values so we can apply them to the appropriate sensors
    ///
    /// - Parameters:
    ///     - sensor:   sensor to get measurement for
    ///     - callback: return function
    ///
    func getObservation(sensor: MeteobridgeSensor, _ callback: @escaping (_ theBridge: Meteobridge?, _ error: Error?) -> Void) {
        WeatherPlatform.getConditionsForSensor(theBridge: self, sensor: sensor, callback: { [unowned self] bridgeData, bridgeError in
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
            
            // Guard against poor data data
            if hourPair.count != 2 {
                log.warning("Meteobridge Timestamp returned:\(hourPair)")
                callback(nil, MeteobridgeError.observationDateError)
                return
            }
            // Guard against poor data data
            
            guard let timeCollect = Calendar.current.date(bySettingHour: Int(hourPair[1])!, minute: Int(timeArray[1])!, second: Int(timeArray[2])!, of: Date())! as Date? else {
                callback(nil, MeteobridgeError.observationError)
                return
            }
            
            /// we're going to get something like this back for each sensor
            /// th0temp:[th0temp-act=.1:--]|[thb0temp-dmax=F.1:--]|[thb0temp-dmin=F.1:--]|[th0lowbat-act.0:--]
            /// Using the model below
            /// battPair[0] = Measurement
            /// battPair[1] = Max measurment
            /// battPair[2] = Min Measurement
            /// battPair[3] = Battery
            for pair in bridgeResponse {
                let subPair = pair.components(separatedBy: ":")                                 // th0temp:30.4 <-- We want to break this into [0]th0temp & [1]30.4
                if subPair[0] != "Time" {
                    guard let filteredSensor = self.findSensor(sensorName: subPair[0]) else {       // Find the sensor with this tag
                        callback(nil, PlatformError.custom(message: "Unknown sensor:[\(subPair[0])] detected"))
                        return
                    }
                    let battPair = subPair[1].components(separatedBy: "|")                      // We're going to get something like this "993.0|--" for the observation / battery health
                    filteredSensor.updateMeasurement(newMeasurement: MeteoObservation(value: battPair[0], time: timeCollect),
                                                     maxMeasurement: MeteoObservation(value: battPair[1], time: timeCollect),
                                                     minMeasurement: MeteoObservation(value: battPair[2], time: timeCollect))     // Record the observation, max & min
                    filteredSensor.updateBatteryHealth(observation: battPair[3])                // Record the battery health
                }
            }
            callback(self, nil)
        })
    }
    
    /// Based on the weather model, update the object accodringly
    ///
    /// - Parameter callback: calling function
    ///
    func updateWeatherModel(_ callback: @escaping (_ theBridge: Meteobridge?, _ error: Error?) -> Void) {
        CLGeocoder.getCountryCode(lat: latitude, lon: longitude, { [unowned self] countryCode, error in
            if error != nil {
                callback(self, MeteobridgeError.weatherModelError)
            } else {
                switch countryCode {
                case "US":
                    WeatherPlatform.getNWSForecastEndpoints(lat: self.latitude, lon: self.longitude, responseHandler: { [unowned self] city, forecast, forecastHourly, error in
                        if error == nil {
                            WeatherPlatform.getNWSZones(lat: self.latitude, lon: self.longitude, responseHandler: { [unowned self] forecastZone, countyZone, radar, point, error in
                                if error == nil {
                                    WeatherPlatform.getNWSPolygon(forecastZone: forecastZone!, countyZone: countyZone!, responseHandler: { forecastPoly, countyPoly, error in
                                        if error == nil {
                                            self._weatherModel = MeteoUSWeather(city: city!, forecastURL: forecast!, forecastHourlyURL: forecastHourly!, grid: point!,
                                                                                forecastID: forecastZone!, countyID: countyZone!, radarID: radar!,
                                                                                boundingPoly: forecastPoly, countyPoly: countyPoly)
                                            callback(self, nil)
                                        } else {
                                            callback(self, error)
                                        }
                                    })
                                } else {    // Polygon
                                    callback(self, error)
                                }
                            })
                        } else {    // NWS Zones
                            callback(self, error)
                        }
                    })  // NWS Endpoints
                default:
                    callback(self, MeteobridgeError.unknownModel)
                }
            }
        })
    }

    /// We have to roll our own Codable class due to MKPolyline
    ///
    /// - Parameter decoder: decoder to act on
    /// - Throws: error
    ///
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MeteobridgeCodingKeys.self)
        
        updateInterval = try container.decode(Int.self, forKey: .updateInterval)
        ipAddress = try container.decode(String.self, forKey: .ipAddress)
        _cCode = try container.decode(String.self, forKey: .cCode)
        name = try container.decode(String.self, forKey: .name)
        uuid = try container.decode(String.self, forKey: .uuid)

        switch _cCode {
        case "US":
            _weatherModel = try container.decode(MeteoUSWeather.self, forKey: .weatherModel)
        default:
            _weatherModel = try container.decode(MeteoWeather.self, forKey: .weatherModel)
        }
        
        sensors = try container.decode([MeteoSensorCategory: [MeteobridgeSensor]].self, forKey: .sensors)
    }
    
    /// We have to roll our own Codable class
    ///
    /// - Parameter encoder: encoder to act on
    /// - Throws: error
    ///
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MeteobridgeCodingKeys.self)
        
        try container.encode(updateInterval, forKey: .updateInterval)
        try container.encode(ipAddress, forKey: .ipAddress)
        try container.encode(_cCode, forKey: .cCode)
        try container.encode(name, forKey: .name)
        try container.encode(uuid, forKey: .uuid)
        
        try container.encode(_weatherModel, forKey: .weatherModel)
        try container.encode(sensors, forKey: .sensors)
    }

    // MARK: - MKAnnotation Conformance
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public var title: String? {
        return String("Bridge: \(name)")
    }
    
    public var subtitle: String? {
        let dms = coordinate.dms
        return String("Lat: \(dms.latitude)\nLon: \(dms.longitude)\nIP: \(ipAddress)")
    }
}
