//
//  MeteoUSWeather.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/2/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import MapKit
import Cocoa

enum MeteoUSWeatherCodingKeys: String, CodingKey {
    case forecastZoneID
    case gridCoordinate
    case countyZoneID
    case countyShape
    case radarID
}

///
/// US Weather Model
///
/// [API Calls](https://api.weather.gov)
/// [Documentation | National Weather Service](https://forecast-v3.weather.gov/documentation)
///
class MeteoUSWeather: MeteoWeather, NWS {
    internal var countyShape: MKMeteoPolyline?
    internal var gridCoordinate: NSPoint
    internal var forecastZoneID: String
    internal var countyZoneID: String
    internal var radarID: String
    
    /// Return the ID for the forecast Zone (e.g., VAZ505)
    var forecastID: String {
        return forecastZoneID
    }
    
    /// Return the ID for the county Zone (e.g., VAC107)
    var countyID: String {
        return countyZoneID
    }

    /// Return the gridpoint for the zone (e.g., gridX: 70, gridY: 77)
    var gridPoint: NSPoint {
        return gridCoordinate
    }
    
    /// Return the ID for the radar station servicing the given zone (e.g., KLWX)
    var radar: String {
        return radarID
    }
    
    /// Return the bounding polygon for the forecast area
    var countyPolygon: MKMeteoPolyline? {
        return boundingShape
    }
    
    /// Initialize the US Weather Object based on data from the NWS endpoints
    ///
    /// - Parameters:
    ///   - city: closest city
    ///   - forecastURL: the URL that we can call for the standard forecast
    ///   - forecastHourlyURL: the URL that we can call for the hourly forecast
    ///   - grid: the gridpoint for the zone (e.g., gridX: 70, gridY: 77)
    ///   - forecastID: the ID for the forecast Zone (e.g., VAZ505)
    ///   - countyID: the ID for the county Zone (e.g., VAC107)
    ///   - radarID: the ID for the radar station servicing the given zone (e.g., KLWX)
    ///
    required init(city: String, forecastURL: String, forecastHourlyURL: String, grid: NSPoint,
                  forecastID: String, countyID: String, radarID: String, boundingPoly: MKMeteoPolyline?, countyPoly: MKMeteoPolyline?) {

        self.forecastZoneID = forecastID
        self.countyShape = countyPoly
        self.countyZoneID = countyID
        self.gridCoordinate = grid
        self.radarID = radarID
        
        super.init(city: city, forecastURL: forecastURL, forecastHourlyURL: forecastHourlyURL, bounding: boundingPoly)
    }
    
    /// We have to roll our own Codable class due to MKMeteoPolyline
    ///
    /// - Parameter decoder: decoder to act on
    /// - Throws: error
    ///
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MeteoUSWeatherCodingKeys.self)
        var name: String?

        let myCountryShape = try container.decode(Data.self, forKey: .countyShape)
        (countyShape, name) = MKMeteoPolyline.fromArchive(polylineArchive: myCountryShape)
        countyShape?.lineName = name!
        
        gridCoordinate = try container.decode(NSPoint.self, forKey: .gridCoordinate)
        forecastZoneID = try container.decode(String.self, forKey: .forecastZoneID)
        countyZoneID = try container.decode(String.self, forKey: .countyZoneID)
        radarID = try container.decode(String.self, forKey: .radarID)

        try super.init(from: decoder)
//        print ("MeteoUSWeather decoded: \(countyShape?.pointCount ?? -1) points")
    }
    
    /// We have to roll our own Codable class due to MKMeteoPolyline
    ///
    /// - Parameter encoder: encoder to act on
    /// - Throws: error
    ///
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: MeteoUSWeatherCodingKeys.self)
        
        if countyShape != nil {
            let myCountryShape = MKMeteoPolyline.toArchive(polyline: countyShape!, lineName: (countyShape?.lineName)!)
            try container.encode(myCountryShape, forKey: .countyShape)
        }
        
        try container.encode(gridCoordinate, forKey: .gridCoordinate)
        try container.encode(forecastZoneID, forKey: .forecastZoneID)
        try container.encode(countyZoneID, forKey: .countyZoneID)
        try container.encode(radarID, forKey: .radarID)
        
        try super.encode(to: encoder)
//        print ("MeteoUSWeather encoded: \(countyShape?.pointCount ?? -1) points")
    }
}
