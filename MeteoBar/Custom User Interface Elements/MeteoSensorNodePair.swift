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

/// Easy way to group the sensors for teh compas view (etiher quad or tri-view)
final class MeteoSensorNodePair {
    private var _majorNode: SKShapeNode?
    private var _minorNode: SKShapeNode?
    private var _sensorID: String?
    
    /// Major Shape Node
    var major: SKShapeNode? {
        return _majorNode
    }
    
    /// Minor Shape Node
    var minor: SKShapeNode? {
        return _minorNode
    }
    
    /// Sensor ID assigned to the pair
    var sensorID: String? {
        get {
            return _sensorID
        }
        set {
            if _majorNode != nil || _minorNode != nil {
                _majorNode?.name = newValue
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
            guard let label = _majorNode?.children.first as? SKLabelNode else {
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
            guard let sensor = WeatherPlatform.shared.findSensorInBridge(searchID: _sensorID!) else {
                return
            }
            majorText = sensor.formattedMeasurement
        }
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - major: preformed SKShapeNode representing the major node
    ///   - minor: preformed SKShapeNode representing the major node
    ///   - sensorID: sensorID assigned to teh node
    ///
    init(major: SKShapeNode, minor: SKShapeNode, sensorID: String? = nil) {
        _sensorID   = sensorID
        _majorNode  = major
        _minorNode  = minor
    }
}
