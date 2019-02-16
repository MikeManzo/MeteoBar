//
//  SensorCollectionModel.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/27/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

enum SensorCollectionModelError: Error, CustomStringConvertible {
    case failedToLoadModel
    
    var description: String {
        switch self {
        case .failedToLoadModel: return "Failed to load sensor model for collection view"
        }
    }
}

///
/// Model for the collection view in the Bridge configuration screen
///
/// ## Important Notes ##
/// 1. section[0] = Energy Sensors
/// 2. section[1] = Humidity Sensors
/// 3. section[2] = Pressure Sensors
/// 4. section[3] = Rain Sensors
/// 5. section[4] = Solar Sensors
/// 6. section[5] = Temperature Sensors
/// 7. section[6] = Wind Sensors
/// 8. section[7] = System Sensors
///
///
class SensorCollectionModel: NSObject {
    private var sections = [Int: [MeteoSensorImage?]]()
    private var _modelLoaded = false
    
    var numberOfSections: Int {
        return sections.count
    }
    
    var validModel: Bool {
        return _modelLoaded
    }
    
    ///
    /// Cleanup the model when we deinit this object
    ///
    /// ## Important Notes ##
    /// None
    ///
    /// ## Parameters ###
    /// None
    /// - throws:       Nothing
    /// - returns:      Nothing
    ///
    deinit {
        resetModel()
    }
   
    ///
    /// Setup the model for our specific case: 2 Sections
    ///
    /// ## Important Notes ##
    /// 1. section[0] = Energy Sensors
    /// 2. section[1] = Humidity Sensors
    /// 3. section[2] = Pressure Sensors
    /// 4. section[3] = Rain Sensors
    /// 5. section[4] = Solar Sensors
    /// 6. section[5] = Temperature Sensors
    /// 7. section[6] = Wind Sensors
    /// 8. section[7] = System Sensors
    ///
    /// ## Parameters ###
    /// None
    /// - throws:       Nothing
    /// - returns:      Nothing
    ///
    open func setupModel() -> Error? {
        var sensorImage     = ""
        var sectionNumber   = 0

        guard let theBridge = theDelegate?.theBridge else {
            return SensorCollectionModelError.failedToLoadModel
        }

        for temp in 0...7 {
            sections[temp] = []
        }

        for (category, sensors) in theBridge.sensors {
            for sensor in sensors where category != .system {
                switch category {
                case .energy:
                    sensorImage = "energy.png"
                    sectionNumber = 0
                case .humidity:
                    sensorImage = "humidity"
                    sectionNumber = 1
                case .pressure:
                    sensorImage = "pressure.png"
                    sectionNumber = 2
                case .rain:
                    sensorImage = "drop.png"
                    sectionNumber = 3
                case .solar:
                    sensorImage = "solar-energy.png"
                    sectionNumber = 4
                case .temperature:
                    sensorImage = "thermometer.png"
                    sectionNumber = 5
                case .wind:
                    sensorImage = "wind-sock.png"
                    sectionNumber = 6
                case .system, .unk:
                    sensorImage = "system.png"
                    sectionNumber = 7
                }
                
                guard let meteoSensor = MeteoSensorImage(imageRef: sensorImage, stationID: theBridge.uuid,
                                                         sensorID: sensor.name, label: sensor.information,
                                                         desc: sensor.information) else {
                        return SensorCollectionModelError.failedToLoadModel
                }
                
                sections[sectionNumber]?.append(meteoSensor)
            }
            sections[sectionNumber]!.sort { $0!.label! < $1!.label! }
        }
        _modelLoaded = true
        return nil
    }

    ///
    /// Return the object containing the image and sensor info
    ///
    /// 1. section[0] = Energy Sensors
    /// 2. section[1] = Humidity Sensors
    /// 3. section[2] = Pressure Sensors
    /// 4. section[3] = Rain Sensors
    /// 5. section[4] = Solar Sensors
    /// 6. section[5] = Temperature Sensors
    /// 7. section[6] = Wind Sensors
    /// 8. section[7] = System Sensors
    ///
    /// - parameters:
    ///   - indexPath: the path of the section/item of interest
    /// - throws: Nothing
    /// - returns: The MeteoSenorImage for the prescribed indexPath
    ///
    func sensorImageForIndexPath(_ indexPath: IndexPath) -> MeteoSensorImage {
        return sections[indexPath.section]![indexPath.item]!
    }
    
    ///
    /// The user has dropped an image ... insert it
    ///
    /// ## Important Notes ##
    /// 1. section[0] = Energy Sensors
    /// 2. section[1] = Humidity Sensors
    /// 3. section[2] = Pressure Sensors
    /// 4. section[3] = Rain Sensors
    /// 5. section[4] = Solar Sensors
    /// 6. section[5] = Temperature Sensors
    /// 7. section[6] = Wind Sensors
    /// 8. section[7] = System Sensors
    ///
    /// - parameters:
    ///   - indexPath: the path of the section/item of interest
    ///   - image: the image to insert
    /// - throws: Nothing
    /// - returns: Nothing
    ///
    func insertImageAtIndexPath(image: MeteoSensorImage, atIndexPath: NSIndexPath) {
        sections[atIndexPath.section]?.insert(image, at: atIndexPath.item)
    }

    ///
    /// We have dropped an image; remove it from its source
    ///
    /// ## Important Notes ##
    /// 1. section[0] = Energy Sensors
    /// 2. section[1] = Humidity Sensors
    /// 3. section[2] = Pressure Sensors
    /// 4. section[3] = Rain Sensors
    /// 5. section[4] = Solar Sensors
    /// 6. section[5] = Temperature Sensors
    /// 7. section[6] = Wind Sensors
    /// 8. section[7] = System Sensors
    ///
    /// - parameters:
    ///   - indexPath: the path of the section/item of interest
    ///   - image: the image to insert
    /// - throws: Nothing
    /// - returns: Nothing
    ///
    func removeImageAtIndexPath(indexPath: NSIndexPath) -> MeteoSensorImage {
        return (sections[indexPath.section]?.remove(at: indexPath.item))!
    }

    ///
    /// Move an image
    ///
    /// ## Important Notes ##
    /// 1. section[0] = Energy Sensors
    /// 2. section[1] = Humidity Sensors
    /// 3. section[2] = Pressure Sensors
    /// 4. section[3] = Rain Sensors
    /// 5. section[4] = Solar Sensors
    /// 6. section[5] = Temperature Sensors
    /// 7. section[6] = Wind Sensors
    /// 8. section[7] = System Sensors
    ///
    /// - parameters:
    ///   - indexPath: the path of the section/item of interest
    ///   - image: the image to insert
    /// - throws: Nothing
    /// - returns: Nothing
    ///
    func moveImageFromIndexPath(indexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        var fromImage: MeteoSensorImage?
        
        fromImage = (sections[indexPath.section]?.remove(at: indexPath.item))!
        insertImageAtIndexPath(image: fromImage!, atIndexPath: toIndexPath)
    }

    ///
    /// Returns the number images in section "X"
    ///
    /// ## Important Notes ##
    /// 1. section[0] = Energy Sensors
    /// 2. section[1] = Humidity Sensors
    /// 3. section[2] = Pressure Sensors
    /// 4. section[3] = Rain Sensors
    /// 5. section[4] = Solar Sensors
    /// 6. section[5] = Temperature Sensors
    /// 7. section[6] = Wind Sensors
    /// 8. section[7] = System Sensors
    ///
    /// - parameters:
    ///   - section: the section of interest for the # of items
    /// - throws: Nothing
    /// - returns: The number of items in the given section
    ///
    func numberOfItemsInSection(_ section: Int) -> Int {
        return (sections[section]?.count)!
    }
    
    ///
    ///  Prepare for a new suite of sensors, or just general cleanup
    ///
    /// ## Important Notes ##
    /// -- None --
    ///
    /// ## Parameters ###
    /// None
    /// - throws: Nothing
    /// - returns: Nothing
    ///
    open func resetModel() {
        for (key, var ssImages) in sections {
            ssImages.removeAll()
            sections[key]?.removeAll()
        }
        sections.removeAll()
        _modelLoaded = false
    }
}
