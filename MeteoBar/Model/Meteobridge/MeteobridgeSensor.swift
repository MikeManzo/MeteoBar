//
//  WeatherSensor.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/17/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

/// Enum to describe the health of the sensor's battery
enum SensorBatteryStatus: String, Codable { case
    good        = "Good",
    low         = "Low",
    unknown     = "Unknown"
}

/// Enum to describe the type of sensor
enum MeteoSensorCategory: String, Codable { case
    energy          = "Energy",
    humidity        = "Humidity",
    temperature     = "Temperature",
    pressure        = "Pressure",
    rain            = "Rain",
    solar           = "Solar",
    wind            = "Wind",
    system          = "System"
}

enum MeteobridgeSensorError: Error, CustomStringConvertible {
    case sensorNotFound
    
    var description: String {
        switch self {
        case .sensorNotFound: return "Unable to find unit in available units for given sensor"
        }
    }
}

/// Atomic class to describe a Meteobridge sensor
class MeteobridgeSensor: NSObject, Codable, Copyable {
    var supportedUnits = [MeteoSensorUnit]()
    var batteryStatus: SensorBatteryStatus
    var category: MeteoSensorCategory
    var batteryParamater: String
    var information: String
    var isOutdoor: Bool
    var name: String

    /// Internal properties for our getters and setters
    private var _measurement =  MeteoObservation()
    private var _isObserving: Bool
    
    /// Measurement property
    var measurement: MeteoObservation {
        get {
            return _measurement
        } set {
            _measurement.update(observation: newValue)
        }
    }

    /// Current Unit
    var currentUnit: MeteoSensorUnit? {
        return supportedUnits.filter {$0.isCurrent == true}.first
    }
    
    /// Formatted Measurement
    var formattedMeasurement: String? {
        var prettyMeasurement: String?
        
        switch category {
        case .energy, .humidity, .pressure, .rain, .solar, .wind, .temperature:
            prettyMeasurement = String("\(measurement.value ?? "--") \(currentUnit!.representation)")
        case .system:
            break
        }
        
        return prettyMeasurement
    }
    
    /// Observing property
    var isObserving: Bool {
        get {
            return _isObserving
        } set {
            _isObserving = newValue
        }
    }
    
    /// Return the template required to get something from the Meteobridge
    ///
    /// - Format:
    ///   - We prepend the sensor name and append the battery parameter
    ///   - Example **sensorName:sensorTemplate|batteryTemplate**
    ///     - th0temp:[th0temp-act=.1:--]|[th0lowbat-act.0:--]
    ///   - If it works we get:
    ///     - th0temp:54.2|0.0 <-- **Sensor:** _th0temp_, **Reading:** _54.2_, **Battery Health:** _Good_
    ///
    var bridgeTemplate: String {
        var strResult = ""
        
        let activeUnit = supportedUnits.filter { $0.isCurrent == true }
        
        if !activeUnit.isEmpty {
            strResult = "\(name):\(activeUnit.first!.parameter)|\(batteryParamater)"
        }
        
        return strResult
    }
    
    /// Return the Name as our Unique SensorID (by definition the sensors are unique)
    var sensorID: String {
        return name
    }
    
    /// Initialize the sensor
    ///
    /// - Parameters:
    ///   - sensorName: name of sensor
    ///   - sensorType: type of sensor
    ///   - isSensorOutdoor: is this sensor outside?
    ///   - sensorUnits: which units can this sensor support?
    ///   - sensorMeasurement: the latest measurement
    ///   - sensorBattery: battery status for this sensor
    ///
    ///   - Returns: fully-formed Meteobridge object
    required init (sensorName: String, sensorCat: MeteoSensorCategory, isSensorOutdoor: Bool, batteryParam: String,
                   info: String, sensorUnits: [MeteoSensorUnit]? = nil, sensorMeasurement: MeteoObservation? = nil,
                   isObserving: Bool = false, sensorBattery: SensorBatteryStatus = .unknown) {
        
        self.isOutdoor          = isSensorOutdoor
        self.batteryStatus      = sensorBattery
        self.batteryParamater   = batteryParam
        self._isObserving       = isObserving
        self.name               = sensorName
        self.category           = sensorCat
        self.information        = info

        if sensorMeasurement != nil {
            self._measurement = sensorMeasurement!
        }
        
        if sensorUnits != nil {
            self.supportedUnits = sensorUnits!
        }
        
        super.init()
    }
    
    /// Copy MeteobridgeSensor
    ///
    /// - Returns: fully constructed MeteobridgeSensor object
    func copy() -> Self {
        return type(of: self).init(sensorName: self.name, sensorCat: self.category, isSensorOutdoor: self.isOutdoor,
                                   batteryParam: self.batteryParamater, info: self.information, sensorUnits: self.supportedUnits,
                                   sensorMeasurement: self._measurement, isObserving: self._isObserving, sensorBattery: self.batteryStatus)
    }
    
    /// Helper to add a supported unit to the sensor
    ///
    ///  - Parameter unit: fully-formed MeteoSensorUnit (based on Meteobridge specification)
    func addSuppoortedUnit(unit: MeteoSensorUnit) {
        supportedUnits.append(unit)
    }
   
    /// Update the sensor with the latest data
    ///
    /// - Parameter newMeasurement: formatted measurement
    ///
    func updateMeasurement(newMeasurement: MeteoObservation) {
        _measurement.update(observation: newMeasurement)
    }
    
    /// Updte the health of the battery
    ///
    /// - Parameter observation: battery descriptor
    func updateBatteryHealth(observation: String) {
        switch observation {
        case "0.0":
            batteryStatus = .good
        case "1.0":
            batteryStatus = .low
        case "--":
            batteryStatus = .unknown
        default:
            batteryStatus = .unknown
        }
    }
    
    /// Update the sensor with one of the validated (and available) units
    ///
    /// - Parameter stringUnit: Desired Unit
    /// - Returns: success or falure of the set
    ///
    func setCurrentUnit(stringUnit: String) -> Error? {
        guard let unit = supportedUnits.filter({ $0.name == stringUnit}).first else {
            return MeteobridgeSensorError.sensorNotFound
        }
        
        return setCurrentUnit(meteoUnit: unit)
    }
    
    /// Update the sensor with one of the validated (and available) units
    ///
    /// - Parameter meteoUnit: Sensor Unit
    /// - Returns: success or falure of the set
    ///
    func setCurrentUnit(meteoUnit: MeteoSensorUnit) -> Error? {

        guard let currentUnit = supportedUnits.filter({ $0.isCurrent == true}).first else {
            return MeteobridgeSensorError.sensorNotFound
        }

        currentUnit.isCurrent   = false
        meteoUnit.isCurrent     = true

        return nil
    }
}
