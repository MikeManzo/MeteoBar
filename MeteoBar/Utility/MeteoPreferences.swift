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
    case compassSensorColor
    case compassFrameColor
    case compassRingColor
    case compassFaceColor
    case compassCaratColor
}

///
/// Class to store MeteoBar's User Defaults
/// To clear the defaults, open terminal and type: defaults delete com.quantumjoker.MeteoBar
///
final class MeteoPreferences: NSObject, Codable, DefaultsSerializable {

    // MARK: - Compass Preferences
    var compassCardinalMinorTickColor: SKColor = SKColor.white
    var compassCardinalMajorTickColor: SKColor = SKColor.blue
    var compassCrosshairColor: SKColor = SKColor.white
    var compassSensorColor: SKColor = SKColor.white
    var compassRingColor: SKColor = SKColor.yellow
    var compassFrameColor: SKColor = SKColor.black
    var compassFaceColor: SKColor = SKColor.black
    var compassCaratColor: SKColor = SKColor.red
    var compassShowSensorBox: Bool = false

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
        
        var colorData = try container.decode(Data.self, forKey: .compassCardinalMinorTickColor)
        compassCardinalMinorTickColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black
        
        colorData = try container.decode(Data.self, forKey: .compassCardinalMajorTickColor)
        compassCardinalMajorTickColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black
        
        colorData = try container.decode(Data.self, forKey: .compassSensorColor)
        compassSensorColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? SKColor ?? SKColor.black

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
    }
    
    /// We have to roll our own Codable class due to SKColor (aka NSColor)
    ///
    /// - Parameter encoder: encoder to act on
    /// - Throws: error
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(compassShowSensorBox, forKey: .compassShowSensorBox)
        
        var colorData = NSKeyedArchiver.archivedData(withRootObject: compassCardinalMinorTickColor)
        try container.encode(colorData, forKey: .compassCardinalMinorTickColor)

        colorData = NSKeyedArchiver.archivedData(withRootObject: compassCardinalMajorTickColor)
        try container.encode(colorData, forKey: .compassCardinalMajorTickColor)

        colorData = NSKeyedArchiver.archivedData(withRootObject: compassSensorColor)
        try container.encode(colorData, forKey: .compassSensorColor)
        
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
    }
}
