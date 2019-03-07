//
//  MeteoPreferences.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/27/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import SwiftyUserDefaults
import SpriteKit
import Cocoa

enum CodingKeys: String, CodingKey {
    case compassCardinalMinorTickColor
    case compassCardinalMajorTickColor
    case compassCrosshairColor
    case compassShowSensorBox
    case compassSensorMajorColor
    case compassSensorMinorColor
    case compassCardinalMajorColor
    case compassCardinalMinorColor
    case showForecastPolygon
    case compassFrameColor
    case showCountyPolygon
    case showAlertPolygon
    case compassRingColor
    case compassFaceColor
    case compassCaratColor
    case compassULSensor
    case compassURSensor
    case compassLLSensor
    case compassLRSensor
    case menubarSensor
    case weatherAlerts
}

///
/// Class to store MeteoBar's User Defaults
/// To clear the defaults, open terminal and type: defaults delete com.quantumjoker.meteobar
///
///   These are our defults:
///   compassCardinalMinorTickColor:    SKColor.white
///   compassCardinalMajorTickColor:    SKColor.blue
///   compassCrosshairColor:            SKColor.white
///   compassSensorColor:               SKColor.white
///   compassRingColor:                 SKColor.yellow
///   compassFrameColor:                SKColor.black
///   compassFaceColor:                 SKColor.black
///   compassCaratColor:                SKColor.red
///   compassShowSensorBox:             false
///   menubarSensor:                    th0temp     // The menubar sensor defaults to the outside temperature
///   compassULSensor:                  th0temp     // Upper Left: Outside Temperature
///   compassURSensor:                  thb0press   // Upper Right: Outside Pressure
///   compassLLSensor:                  th0hum      // Lower Left: Outside Humidity
///   compassLRSensor:                  sol0rad     // Lower Right: Outside Solar Radiation
///   weatherAlerts:                    true
///   showForecastPolygon               true
///   showCountyPolygon                 true
///   showAlertPolygon                  true
///
final class MeteoPreferences: NSObject, Codable, DefaultsSerializable {
    // MARK: - Compass Defaults
    var compassCardinalMinorTickColor: SKColor = SKColor.white
    var compassCardinalMajorTickColor: SKColor = SKColor.blue
    var compassCrosshairColor: SKColor = SKColor.white
    var compassSensorMajorColor: SKColor = SKColor.white
    var compassSensorMinorColor: SKColor = SKColor.white
    var compassCardinalMinorColor: SKColor = SKColor.white
    var compassCardinalMajorColor: SKColor = SKColor.white
    var compassRingColor: SKColor = SKColor.yellow
    var compassFrameColor: SKColor = SKColor.black
    var compassFaceColor: SKColor = SKColor.black
    var compassCaratColor: SKColor = SKColor.red
    var compassShowSensorBox: Bool = false
    var menubarSensor: String = "th0temp"       // Temp outside
    var compassULSensor: String = "th0temp"     // Upper Left:  Temp
    var compassURSensor: String = "thb0press"   // Upper Right: Pressure
    var compassLLSensor: String = "th0hum"      // Lower Left:  Humidity
    var compassLRSensor: String = "sol0rad"     // Lower Right: Solar Radiation
    var weatherAlerts: Bool = true
    var showForecastPolygon: Bool = true
    var showCountyPolygon: Bool = true
    var showAlertPolygon: Bool = true

    // MARK: - Codable Compliance
    /// Required for an empty object (because we hve defaults above)
    required override init() {
        super.init()
    }
    
    /// We have to roll our own Codable class due to SKColor (aka NSColor)
    ///
    /// - Parameter decoder: decoder to act on
    /// - Throws: error
    ///
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        compassShowSensorBox = try container.decode(Bool.self, forKey: .compassShowSensorBox)
        showForecastPolygon = try container.decode(Bool.self, forKey: .showForecastPolygon)
        showCountyPolygon = try container.decode(Bool.self, forKey: .showCountyPolygon)
        showAlertPolygon = try container.decode(Bool.self, forKey: .showAlertPolygon)
        weatherAlerts = try container.decode(Bool.self, forKey: .weatherAlerts)
        
        var colorData = try container.decode(Data.self, forKey: .compassCardinalMinorTickColor)
        compassCardinalMinorTickColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black
        
        colorData = try container.decode(Data.self, forKey: .compassCardinalMajorTickColor)
        compassCardinalMajorTickColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black
        
        colorData = try container.decode(Data.self, forKey: .compassSensorMajorColor)
        compassSensorMajorColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black

        colorData = try container.decode(Data.self, forKey: .compassSensorMinorColor)
        compassSensorMinorColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black
        
        colorData = try container.decode(Data.self, forKey: .compassCardinalMajorColor)
        compassCardinalMajorColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black
        
        colorData = try container.decode(Data.self, forKey: .compassCardinalMinorColor)
        compassCardinalMinorColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black
        
        colorData = try container.decode(Data.self, forKey: .compassRingColor)
        compassRingColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black

        colorData = try container.decode(Data.self, forKey: .compassFaceColor)
        compassFaceColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black
        
        colorData = try container.decode(Data.self, forKey: .compassCaratColor)
        compassCaratColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black
        
        colorData = try container.decode(Data.self, forKey: .compassCaratColor)
        compassCaratColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black

        colorData = try container.decode(Data.self, forKey: .compassCrosshairColor)
        compassCrosshairColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black
    
        var strSensor = try container.decode(Data.self, forKey: .compassULSensor)
        compassULSensor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(strSensor) as? String ?? ""
        
        strSensor = try container.decode(Data.self, forKey: .compassURSensor)
        compassURSensor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(strSensor) as? String ?? ""

        strSensor = try container.decode(Data.self, forKey: .compassLLSensor)
        compassLLSensor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(strSensor) as? String ?? ""

        strSensor = try container.decode(Data.self, forKey: .compassLRSensor)
        compassLRSensor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(strSensor) as? String ?? ""

        strSensor = try container.decode(Data.self, forKey: .menubarSensor)
        menubarSensor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(strSensor) as? String ?? ""
    }
    
    /// We have to roll our own Codable class due to SKColor (aka NSColor)
    ///
    /// - Parameter encoder: encoder to act on
    /// - Throws: error
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(compassShowSensorBox, forKey: .compassShowSensorBox)
        try container.encode(showForecastPolygon, forKey: .showForecastPolygon)
        try container.encode(showCountyPolygon, forKey: .showCountyPolygon)
        try container.encode(showAlertPolygon, forKey: .showAlertPolygon)
        try container.encode(weatherAlerts, forKey: .weatherAlerts)

        var colorData = NSKeyedArchiver.archivedData(withRootObject: compassCardinalMinorTickColor)
        try container.encode(colorData, forKey: .compassCardinalMinorTickColor)

        colorData = NSKeyedArchiver.archivedData(withRootObject: compassCardinalMajorTickColor)
        try container.encode(colorData, forKey: .compassCardinalMajorTickColor)

        colorData = NSKeyedArchiver.archivedData(withRootObject: compassSensorMajorColor)
        try container.encode(colorData, forKey: .compassSensorMajorColor)
        
        colorData = NSKeyedArchiver.archivedData(withRootObject: compassSensorMinorColor)
        try container.encode(colorData, forKey: .compassSensorMinorColor)
        
        colorData = NSKeyedArchiver.archivedData(withRootObject: compassCardinalMajorColor)
        try container.encode(colorData, forKey: .compassCardinalMajorColor)
        
        colorData = NSKeyedArchiver.archivedData(withRootObject: compassCardinalMinorColor)
        try container.encode(colorData, forKey: .compassCardinalMinorColor)
        
        colorData = NSKeyedArchiver.archivedData(withRootObject: compassRingColor)
        try container.encode(colorData, forKey: .compassRingColor)

        colorData = NSKeyedArchiver.archivedData(withRootObject: compassFaceColor)
        try container.encode(colorData, forKey: .compassFaceColor)

        colorData = NSKeyedArchiver.archivedData(withRootObject: compassCaratColor)
        try container.encode(colorData, forKey: .compassCaratColor)
        
        colorData = NSKeyedArchiver.archivedData(withRootObject: compassFrameColor)
        try container.encode(colorData, forKey: .compassFrameColor)
        
        colorData = NSKeyedArchiver.archivedData(withRootObject: compassCrosshairColor)
        try container.encode(colorData, forKey: .compassCrosshairColor)
        
        var strSensor = NSKeyedArchiver.archivedData(withRootObject: compassULSensor)
        try container.encode(strSensor, forKey: .compassULSensor)

        strSensor = NSKeyedArchiver.archivedData(withRootObject: compassURSensor)
        try container.encode(strSensor, forKey: .compassURSensor)

        strSensor = NSKeyedArchiver.archivedData(withRootObject: compassLLSensor)
        try container.encode(strSensor, forKey: .compassLLSensor)

        strSensor = NSKeyedArchiver.archivedData(withRootObject: compassLRSensor)
        try container.encode(strSensor, forKey: .compassLRSensor)
        
        strSensor = NSKeyedArchiver.archivedData(withRootObject: menubarSensor)
        try container.encode(strSensor, forKey: .menubarSensor)
    }
}

/// Defaults - in case we want to individually reset a parameter
extension MeteoPreferences {
    func resetDefautls() {
        compassCardinalMinorTickColor   = SKColor.white
        compassCardinalMajorTickColor   = SKColor.blue
        compassCrosshairColor           = SKColor.white
        compassSensorMajorColor         = SKColor.white
        compassSensorMinorColor         = SKColor.white
        compassCardinalMajorColor       = SKColor.white
        compassCardinalMinorColor       = SKColor.white
        compassRingColor                = SKColor.yellow
        compassFrameColor               = SKColor.black
        compassFaceColor                = SKColor.black
        compassCaratColor               = SKColor.red
        menubarSensor                   = "th0temp"         // Temp outside
        compassULSensor                 = "th0temp"         // Upper Left:  Temp
        compassURSensor                 = "thb0press"       // Upper Right: Pressure
        compassLLSensor                 = "th0hum"          // Lower Left:  Humidity
        compassLRSensor                 = "sol0rad"         // Lower Right: Solar Radiation
        compassShowSensorBox            = false
        weatherAlerts                   = true
        showForecastPolygon             = true
        showCountyPolygon               = true
        showAlertPolygon                = true
    }
    
    func resetCompassCardinalMinorTickColor() -> SKColor {
        compassCardinalMinorTickColor = SKColor.white
        return compassCardinalMinorTickColor
    }
    
    func resetCompassCardinalMajorTickColor() -> SKColor {
        compassCardinalMajorTickColor = SKColor.blue
        return compassCardinalMajorTickColor
    }
    
    func resetCompassCrosshairColor() -> SKColor {
        compassCrosshairColor = SKColor.white
        return compassCrosshairColor
    }
    
    func resetCompassSensorMajorColor() -> SKColor {
        compassSensorMajorColor = SKColor.white
        return compassSensorMajorColor
    }
    
    func resetCompassSensorMinorColor() -> SKColor {
        compassSensorMinorColor = SKColor.white
        return compassSensorMinorColor
    }
    
    func resetCompassCardinalMajorColor() -> SKColor {
        compassCardinalMajorColor = SKColor.white
        return compassCardinalMajorColor
    }
    
    func resetCompassCardinalMinorColor() -> SKColor {
        compassCardinalMinorColor = SKColor.white
        return compassCardinalMinorColor
    }
    
    func resetCompassRingColor() -> SKColor {
        compassRingColor = SKColor.yellow
        return compassRingColor
    }
    
    func resetCompassFrameColor() -> SKColor {
        compassFrameColor = SKColor.black
        return compassFrameColor
    }
    
    func resetCompassFaceColor() -> SKColor {
        compassFaceColor = SKColor.black
        return compassFaceColor
    }
    
    func resetCompassCaratColor() -> SKColor {
        compassCaratColor = SKColor.red
        return compassCaratColor
    }
    
    func resetCompassShowSensorBox() -> Bool {
        compassShowSensorBox = false
        return compassShowSensorBox
    }
    
    func resetMenubarSensor() -> String {
        menubarSensor = "th0temp"
        return menubarSensor
    }
    
    func resetCompassULSensor() -> String {
        compassULSensor = "th0temp"
        return compassULSensor
    }
    
    func resetCompassURSensor() -> String {
        compassURSensor = "thb0press"
        return compassURSensor
    }
    
    func resetCompassLLSensor() -> String {
        compassLLSensor = "th0hum"
        return compassLLSensor
    }
    
    func resetCompassLRSensor() -> String {
        compassLRSensor = "sol0rad"
        return compassLRSensor
    }
    
    func resetWeatherAlerts() -> Bool {
        weatherAlerts = true
        return weatherAlerts
    }
    func resetShowForecastPolygon() -> Bool {
        showForecastPolygon = true
        return showForecastPolygon
    }
    func resetShowCountyPolygon() -> Bool {
        showCountyPolygon = true
        return showCountyPolygon
    }
    func resetShowAlertPolygon() -> Bool {
        showAlertPolygon = true
        return showAlertPolygon
    }
}
