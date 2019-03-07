//
//  MeteoWeather.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/2/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import MapKit
import Cocoa

protocol MeteoBaseWeather {
    var closestCity: String { get }
    var forecastEndpoint: String { get }
    var forecastHourlyEndpoint: String { get }
    var boundingShape: MKPolyline? {get set}
}

protocol NWS: MeteoBaseWeather {
    var gridCoordinate: NSPoint { get }
    var forecastZoneID: String { get }
    var countyZoneID: String { get }
    var radarID: String { get }

    init(city: String, forecastURL: String, forecastHourlyURL: String,
         grid: NSPoint, forecastID: String, countyID: String, radarID: String,
         boundingPoly: MKPolyline?, countyPoly: MKPolyline?)
}

enum MeteoWeatherCodingKeys: String, CodingKey {
    case forecastHourlyEndpoint
    case forecastEndpoint
    case boundingShape
    case closestCity
}

///
/// Base class for wether models ... right now, the only one supported is the NWS
///
class MeteoWeather: NSObject, Codable, MeteoBaseWeather {
    internal var forecastHourlyEndpoint: String
    internal var boundingShape: MKPolyline?
    internal var forecastEndpoint: String
    internal var closestCity: String

    /// Return the closest city for the given Zone (e.g., "My Town")
    var city: String {
        return closestCity
    }

    /// Return the URL that we can call for the standard forecast
    var forecastURL: String {
        return forecastEndpoint
    }
    
    /// Return the URL that we can call for the hourly forecast
    var forecastHourlyURL: String {
        return forecastHourlyEndpoint
    }
    
    /// Return the bounding polygon for the forecast area
    var forecastPolygon: MKPolyline? {
        return boundingShape
    }
    
    /// Initialize the base Object based on data from the givem endpoints
    ///
    /// - Parameters:
    ///   - city: closest city
    ///   - forecastURL: the URL that we can call for the standard forecast
    ///   - forecastHourlyURL: the URL that we can call for the hourly forecast
    ///
    init(city: String, forecastURL: String, forecastHourlyURL: String, bounding: MKPolyline? = nil) {
        self.forecastHourlyEndpoint = forecastHourlyURL
        self.forecastEndpoint = forecastURL
        self.boundingShape = bounding
        self.closestCity = city
    }
    
    /// We have to roll our own Codable support due to MKPolyline
    ///
    /// # How to decode an array #
    ///
    ///     let myBoundingShape = try container.decode(Data.self, forKey: .boundingShape)
    ///     let interimData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(myBoundingShape) as? NSArray
    ///     var interimShape = [MKPolyline]()
    ///     for data in interimData! {
    ///         interimShape.append(MKPolyline.fromArchive(polylineArchive: (data as? Data ?? nil)!)!)
    ///     }
    ///     boundingShape = interimShape
    ///
    /// - Parameter decoder: decoder to act on
    /// - Throws: error
    ///
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MeteoWeatherCodingKeys.self)

        let myBoundingShape = try container.decode(Data.self, forKey: .boundingShape)
        boundingShape = MKPolyline.fromArchive(polylineArchive: myBoundingShape)
        
        forecastHourlyEndpoint = try container.decode(String.self, forKey: .forecastHourlyEndpoint)
        forecastEndpoint = try container.decode(String.self, forKey: .forecastEndpoint)
        closestCity = try container.decode(String.self, forKey: .closestCity)
    }
    
    /// We have to roll our own Codable support due to MKPolyline
    ///
    /// # How to encode an array #
    ///
    ///     if boundingShape != nil {
    ///        var dataArray = [Data]()
    ///        for point in boundingShape! {
    ///           dataArray.append(MKPolyline.toArchive(polyline: point))
    ///        }
    ///        let myBoundingShape = NSKeyedArchiver.archivedData(withRootObject: dataArray)
    ///        try container.encode(myBoundingShape, forKey: .boundingShape)
    ///     }
    ///
    /// - Parameter encoder: encoder to act on
    /// - Throws: error
    ///
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MeteoWeatherCodingKeys.self)

        if boundingShape != nil {
            let myBoundingShape = MKPolyline.toArchive(polyline: boundingShape!)
            try container.encode(myBoundingShape, forKey: .boundingShape)
        }

        try container.encode(forecastHourlyEndpoint, forKey: .forecastHourlyEndpoint)
        try container.encode(forecastEndpoint, forKey: .forecastEndpoint)
        try container.encode(closestCity, forKey: .closestCity)
    }
}