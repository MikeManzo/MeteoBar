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
        
        var viewPoint = theKitScene!.convertPoint(toView: midPoint)
        viewPoint.x += 8
        viewPoint.y += 9
        
        var dropView = CollectionItemDropView(identifier: "Upper Right", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
        dropView.wantsLayer = true
        dropView.delegate = self
        dropViews.append(dropView)
        
        viewPoint.x -= 97
        dropView = CollectionItemDropView(identifier: "Upper Left", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
        dropView.wantsLayer = true
        dropView.delegate = self
        dropViews.append(dropView)
        
        viewPoint.y -= 107
        dropView = CollectionItemDropView(identifier: "Lower Left", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
        dropView.wantsLayer = true
        dropView.delegate = self
        dropViews.append(dropView)
        
        viewPoint = theKitScene!.convertPoint(toView: midPoint)
        viewPoint.x += 8
        viewPoint.y -= 97
        dropView = CollectionItemDropView(identifier: "Lower Right", frameRect: NSRect(origin: viewPoint, size: CGSize(width: 80, height: 90)))
        dropView.wantsLayer = true
        dropView.delegate = self
        dropViews.append(dropView)
        
        for myView in dropViews {
            addSubview(myView)
        }
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
