//
//  MeteoSensorImage.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/27/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

class MeteoSensorImage: NSObject {
    private var _sensorDescription: String?
    private var _sensorLabel: String?
    private var _thumbnail: NSImage?
    private var _stationID: String?
    private var _sensorID: String?
    
    deinit {
        _stationID          = nil
        _sensorID           = nil
        _thumbnail          = nil
        _sensorLabel        = nil
        _sensorDescription  = nil
    }
    
    var sensorID: String? {
        return _sensorID
    }
    
    var stationID: String? {
        return _stationID
    }
    
    var label: String? {
        return _sensorLabel
    }
    
    /*weak*/ var thumb: NSImage? {
        return _thumbnail
    }
    
    var theDescription: String? {
        return _sensorDescription
    }
    
    init(cgHeight: CGFloat) {
        super.init()
        
        _stationID          = ""
        _sensorID           = ""
        _sensorLabel        = ""
        _sensorDescription  = ""
        _thumbnail          = NSImage(size: NSSize(width: 1, height: cgHeight))
    }
    
    init?(imageRef: String, stationID: String, sensorID: String, label: String, desc: String) {
        super.init()
        
        _stationID          = stationID
        _sensorID           = sensorID
        _sensorLabel        = label
        _sensorDescription  = desc
        
        guard let imageSource: NSImage = NSImage(named: NSImage.Name(imageRef)) else {
            return nil
        }
        
        _thumbnail = imageSource
    }
}
