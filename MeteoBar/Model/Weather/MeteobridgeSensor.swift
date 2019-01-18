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
enum MeteoSensorType: String, Codable { case
    energy         = "Energy",
    humidity       = "Humidity",
    temperature    = "Temperature",
    pressure       = "Pressure",
    rain           = "Rain",
    solar          = "Solar",
    wind           = "Wind"
}

/// Atomic class to describe a Meteobridge sensor
class MeteobridgeSensor: NSObject, Codable {
    var supportedUnits = [MeteoSensorUnit]()
    var batteryStatus: SensorBatteryStatus
    var type: MeteoSensorType
    var measurement: String?
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
    init (sensorName: String, sensorType: MeteoSensorType, isSensorOutdoor: Bool, sensorUnits: [MeteoSensorUnit],
          sensorMeasurement: String?, sensorBattery: SensorBatteryStatus = .unknown) {
        
        self.batteryStatus = sensorBattery
        self.isOutdoor  = isSensorOutdoor
        self.name = sensorName
        self.type = sensorType

        if sensorMeasurement != nil {
            self.measurement = sensorMeasurement
        }
        
        super.init()
    }
}
