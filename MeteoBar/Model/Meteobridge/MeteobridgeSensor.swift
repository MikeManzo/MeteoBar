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
    var measurement: String?
    var information: String
    var isOutdoor: Bool
    var name: String
    
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
                   info: String, sensorUnits: [MeteoSensorUnit]? = nil, sensorMeasurement: String? = nil,
                   sensorBattery: SensorBatteryStatus = .unknown) {
        
        self.isOutdoor          = isSensorOutdoor
        self.batteryStatus      = sensorBattery
        self.batteryParamater   = batteryParam
        self.name               = sensorName
        self.category           = sensorCat
        self.information        = info

        if sensorMeasurement != nil {
            self.measurement = sensorMeasurement
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
                                   sensorMeasurement: self.measurement, sensorBattery: self.batteryStatus)
    }
    
    /// Helper to add a supported unit to the sensor
    ///
    ///  - Parameter unit: fully-formed MeteoSensorUnit (based on Meteobridge specification)
    func addSuppoortedUnit(unit: MeteoSensorUnit) {
        supportedUnits.append(unit)
    }
}
