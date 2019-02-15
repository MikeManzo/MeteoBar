//
//  MeteoCompassSettingsView.swift
//  MeteoBar
//
//  Created by Mike Manzo on 2/2/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

class MeteoCompassSettingsView: MeteoCompassView {
    // MARK: - Drop Sensors
    var dropViews   = [CollectionItemDropView]()    // Sensor "Vew" Drop Sites

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if theDelegate?.theBridge != nil {
            var viewPoint = theKitScene!.convertPoint(toView: midPoint)
            viewPoint.x += 8
            viewPoint.y += 9
            
            var dropView = CollectionItemDropView(identifier: "Upper Right", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
            dropView.wantsLayer = true
            dropView.delegate = self
            if (theDelegate?.theDefaults?.compassURSensor.isEmpty)! {
                dropView.showDrop = true
            } else {
                if theDelegate?.theBridge != nil { upperRight?.update() }
                dropView.showDrop = false
                guard let sensor = WeatherPlatform.shared.findSensorInBridge(searchID: ((theDelegate?.theDefaults?.compassURSensor)!)) else {
                    log.error("Unable to find sensor: \(theDelegate?.theDefaults?.compassURSensor ?? "") for display")
                    return
                }
                dropView.toolTip = sensor.formattedSummary
            }
            dropViews.append(dropView)
            
            viewPoint.x -= 97
            dropView = CollectionItemDropView(identifier: "Upper Left", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
            dropView.wantsLayer = true
            dropView.delegate = self
            if (theDelegate?.theDefaults?.compassULSensor.isEmpty)! {
                dropView.showDrop = true
            } else {
                if theDelegate?.theBridge != nil { upperLeft?.update() }
                dropView.showDrop = false
                guard let sensor = WeatherPlatform.shared.findSensorInBridge(searchID: ((theDelegate?.theDefaults?.compassULSensor)!)) else {
                    log.error("Unable to find sensor: \(theDelegate?.theDefaults?.compassULSensor ?? "") for display")
                    return
                }
                dropView.toolTip = sensor.formattedSummary
            }
            dropViews.append(dropView)
            
            viewPoint.y -= 107
            dropView = CollectionItemDropView(identifier: "Lower Left", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
            dropView.wantsLayer = true
            dropView.delegate = self
            if (theDelegate?.theDefaults?.compassLLSensor.isEmpty)! {
                dropView.showDrop = true
            } else {
                if theDelegate?.theBridge != nil { lowerLeft?.update() }
                dropView.showDrop = false
                guard let sensor = WeatherPlatform.shared.findSensorInBridge(searchID: ((theDelegate?.theDefaults?.compassLLSensor)!)) else {
                    log.error("Unable to find sensor: \(theDelegate?.theDefaults?.compassLLSensor ?? "") for display")
                    return
                }
                dropView.toolTip = sensor.formattedSummary
            }
            dropViews.append(dropView)
            
            viewPoint = theKitScene!.convertPoint(toView: midPoint)
            viewPoint.x += 8
            viewPoint.y -= 97
            dropView = CollectionItemDropView(identifier: "Lower Right", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
            dropView.wantsLayer = true
            dropView.delegate = self
            if (theDelegate?.theDefaults?.compassLRSensor.isEmpty)! {
                dropView.showDrop = true
            } else {
                if theDelegate?.theBridge != nil { lowerRight?.update() }
                dropView.showDrop = false
                guard let sensor = WeatherPlatform.shared.findSensorInBridge(searchID: ((theDelegate?.theDefaults?.compassLRSensor)!)) else {
                    log.error("Unable to find sensor: \(theDelegate?.theDefaults?.compassLRSensor ?? "") for display")
                    return
                }
                dropView.toolTip = sensor.formattedSummary
            }
            dropViews.append(dropView)
            
            for myView in dropViews {
                addSubview(myView)
            }
        }
    }
    
    override func updatePreferences() {
        super.updatePreferences()
    }
}

extension MeteoCompassSettingsView: CollectionItemDropViewDelegate {
    func dragDropView(_ dragDropView: CollectionItemDropView, uuID: String, dropValue: String) {
        log.info("[**\(uuID)**] recieved a valid sensor drop for:\(dropValue)")
        switch uuID {
        case "Upper Left":
            if upperLeft != nil {
                upperLeft?.sensorID = dropValue
                upperLeft?.update()
                dragDropView.showDrop = false
            }
        case "Upper Right":
            if upperRight != nil {
                upperRight?.sensorID = dropValue
                upperRight?.update()
                dragDropView.showDrop = false
            }
        case "Lower Left":
            if lowerLeft != nil {
                lowerLeft?.sensorID = dropValue
                lowerLeft?.update()
                dragDropView.showDrop = false
            }
        case "Lower Right":
            if lowerRight != nil {
                lowerRight?.sensorID = dropValue
                lowerRight?.update()
                dragDropView.showDrop = false
            }
        default:
            log.error(MeteoCompassViewError.unknownView)
        }
    }
}
