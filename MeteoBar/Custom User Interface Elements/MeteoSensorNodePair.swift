//
//  MeteoSensorNodePair.swift
//  MeteoBar
//
//  Created by Mike Manzo on 2/2/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Foundation
import SpriteKit
import SceneKit

enum MeteoSensorNodePairError: Error, CustomStringConvertible {
    case invalidSensorID (sensor: String)
    case invalidSprite
    
    var description: String {
        switch self {
        case .invalidSensorID(let sensor): return "Sensor:[\(sensor)] not found.  If you have not yet initialized yor Meteobridge, this is normal."
        case .invalidSprite: return "Sprite not found"
        }
    }
}

/// Easy way to group the sensors for teh compas view (etiher quad or tri-view)
final class MeteoSensorNodePair {
    private var _majorNode: SKShapeNode?
    private var _minorNode: SKShapeNode?
    private var _iconNode: SKEffectNode?
    private var _battery: SKSpriteNode?
    private var _sensorID: String?
    
    /// Major Shape Node
    var major: SKShapeNode? {
        return _majorNode
    }
    
    /// Minor Shape Node
    var minor: SKShapeNode? {
        return _minorNode
    }

    /// Battery
    var battery: SKSpriteNode? {
        return _battery
    }
    
    /// Sensor Icon
    var sensorIcon: SKEffectNode? {
        return _iconNode
    }
    
    /// Sensor ID assigned to the pair
    var sensorID: String? {
        get {
            return _sensorID
        }
        set {
            if _majorNode != nil || _minorNode != nil {
                _majorNode = nil    // MRM: Memoeyr Leak?
                _majorNode?.name = newValue
                _minorNode = nil    // MRM: Memoeyr Leak?
                _minorNode?.name = newValue
            }
            _sensorID = newValue
        }
    }
    
    /// Major Node text display
    var majorText: String? {
        get {
            guard let label = _majorNode?.children.first as? SKLabelNode else {
                return nil
            }
            return label.text
        }
        set {
            guard let label = _majorNode?.children.first as? QJSKMultiLineLabel else {
                return
            }
            label.text = newValue
        }
    }
    
    /// Minor Node text display
    var minorText: String? {
        get {
            guard let label = _minorNode?.children.first as? SKLabelNode else {
                return nil
            }
            return label.text
        }
        set {
            guard let label = _minorNode?.children.first as? SKLabelNode else {
                return
            }
            label.text = newValue
        }
    }
    
    /// Update the pair with the latest data
    ///
    /// - Returns: true if we succeeded; false if we could not find the sensor
    ///
    func update() {
        if _sensorID != nil {
            guard let sensor = WeatherPlatform.findSensorInBridge(searchID: _sensorID!) else {
                return
            }
            majorText = sensor.formattedMeasurement
            minorText = sensor.formattedMinMax
            
            battery?.isHidden = false
            battery?.removeAllChildren()
//            battery?.removeFromParent()
            switch sensor.batteryStatus {
            case .good:
                battery?.texture = SKTexture(imageNamed: "full-battery-color")
            case .low:
                battery?.texture = SKTexture(imageNamed: "empty-battery-color")
            case .unknown:
                battery?.texture = SKTexture(imageNamed: "unknown-battery-color")
            }
        }
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - major: preformed SKShapeNode representing the major node
    ///   - minor: preformed SKShapeNode representing the major node
    ///   - battery: preformed SKSpriteNode represneitngt the battery state
    ///   - icon: preformed SKEffectNode representing the sensor icon
    ///   - sensorID: sensorID assigned to teh node
    ///
    init(major: SKShapeNode, minor: SKShapeNode, battery: SKSpriteNode, icon: SKEffectNode, sensorID: String? = nil) {
        _sensorID   = sensorID
        _battery    = battery
        _majorNode  = major
        _minorNode  = minor
        _iconNode   = icon
        
        if _sensorID != nil {
            guard let sensor = WeatherPlatform.findSensorInBridge(searchID: _sensorID!) else {
                log.warning(MeteoSensorNodePairError.invalidSensorID(sensor: _sensorID!))
                return
            }

            guard let sprite = _iconNode?.children.first as? SKSpriteNode else {
                log.error(MeteoSensorNodePairError.invalidSprite)
                return
            }
            
            switch sensor.category {
            case .energy:
                sprite.texture = SKTexture(imageNamed: "energy.png")
            case .humidity:
                sprite.texture = SKTexture(imageNamed: "humidity.png")
            case .pressure:
                sprite.texture = SKTexture(imageNamed: "pressure.png")
            case .rain:
                sprite.texture = SKTexture(imageNamed: "drop.png")
            case .solar:
                sprite.texture = SKTexture(imageNamed: "solar-energy.png")
            case .temperature:
                sprite.texture = SKTexture(imageNamed: "thermometer.png")
            case .wind:
                sprite.texture = SKTexture(imageNamed: "wind-sock.png")
            case .system, .unk:
                break
            }
            
            if (theDelegate?.isVibrantMode())! {
                _iconNode!.filter = CIFilter(name: "CIColorInvert")
            }
        }
    }
    
    deinit {
//        print("Deinitializing SensorNodePair")
        _majorNode?.path    = nil
        _minorNode?.path    = nil
        _iconNode           = nil
        _battery            = nil
        _sensorID           = nil
    }
}
