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
    
    /// Observing property
    var isObserving: Bool {
        get {
            return _isObserving
        } set {
            _isObserving = newValue
        }
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

    /// Return the string required to get take a weather measurement from the Meteobridge (e.g., non-system)
    ///
    /// We prepend the sensor name to the request.  We'll get something back like: th0temp:54.2.  We can then
    /// parse parse teh sensor name and measurement and feed it back as an observation
    ///
    /// - Returns: formatted string for a measurement --> (e.g., th0temp:[th0temp-act=.1:---] )
    ///
    func getFormattedWeatherMeasurement( ) -> String {
        var strResult = ""
        
        let activeUnit = supportedUnits.filter { $0.isCurrent == true}
        
        if !activeUnit.isEmpty {
            strResult = "\(activeUnit.first!.name):\(activeUnit.first!.parameter))"
        }
        
        return strResult
    }
    
    /// Update the sensor with the latest data
    ///
    /// - Parameter newMeasurement: formatted measurement
    ///
    func updateMeasurement(newMeasurement: MeteoObservation) {
        _measurement.update(observation: newMeasurement)
    }
}
