//
//  QLExtensions.swift
//  MeteoBar
//
//  [How to type superscript in xcode](https://stackoverflow.com/questions/32091586/how-to-type-superscript-in-xcode)
//
//  Created by Mike Manzo on 1/14/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Foundation
import SpriteKit
import MapKit
import Cocoa

/// Handy non-class related variables
var theDelegate: AppDelegate? {
    guard let appDelegate = NSApplication.shared.delegate as? AppDelegate else {
        return nil
    }
    return appDelegate
}

/// Extensions
extension Bundle {
    class var applicationVersionNumber: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Version Number Not Available"
    }
    
    class var applicationBuildNumber: String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "Build Number Not Available"
    }    
}

extension FloatingPoint {
    var minutes: Self {
        return (self*3600)
            .truncatingRemainder(dividingBy: 3600)/60
    }
    var seconds: Self {
        return (self*3600)
            .truncatingRemainder(dividingBy: 3600)
            .truncatingRemainder(dividingBy: 60)
    }
}

extension CLGeocoder {
    func getCountryCode(lat: Double, lon: Double, _ callback: @escaping (_ country: String?, _ error: Error?) -> Void) {
        reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon)) { (placemarks, err) in
            if err == nil {
                if let placemark = placemarks?[0] {
                    callback(placemark.isoCountryCode, nil)
                }
            } else {
                callback(nil, err)
            }
        }
    }
}

extension CLLocationCoordinate2D {
    ///
    /// [Reference](https://www.latlong.net/lat-long-dms.html)
    ///
    var dms: (latitude: String, longitude: String) {
        return (String(format: "%d° %d' %.2f\" %@",
                       Int(abs(latitude)),
                       Int(abs(latitude.minutes)),
                       abs(latitude.seconds),
                       latitude >= 0 ? "N" : "S"),
                String(format: "%d° %d' %.2f\" %@",
                       Int(abs(longitude)),
                       Int(abs(longitude.minutes)),
                       abs(longitude.seconds),
                       longitude >= 0 ? "E" : "W"))
    }
}

public extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: pointCount)
        
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        
        return coords
    }
}

extension MKPolyline {
    /// SwifterSwift: Create a new MKPolyline from a provided Array of coordinates.
    ///
    /// - Parameter coordinates: Array of CLLocationCoordinate2D(s).
    public convenience init(coordinates: [CLLocationCoordinate2D]) {
        var refCoordinates = coordinates
        self.init(coordinates: &refCoordinates, count: refCoordinates.count)
    }
    
    /// Make MKPolyLine decodable
    ///
    /// - Parameter polylineArchive: Data description of MKPolyLine
    /// - Returns: MKPolyLine
    //
    static func fromArchive(polylineArchive: Data) -> MKPolyline? {
        guard let data = NSKeyedUnarchiver.unarchiveObject(with: polylineArchive as Data),
            let polyline = data as? [[String: AnyObject]] else {
                return nil
        }
        var locations: [CLLocation] = []
        for item in polyline {
            if let latitude = item["latitude"]?.doubleValue,
                let longitude = item["longitude"]?.doubleValue {
                let location = CLLocation(latitude: latitude, longitude: longitude)
                locations.append(location)
            }
        }
        var coordinates = locations.map({(location: CLLocation) -> CLLocationCoordinate2D in return location.coordinate})
        let result = MKPolyline(coordinates: &coordinates, count: locations.count)
        return result
    }
    
    /// Make MKPolyLine encodable
    ///
    /// - Parameter polylineArchive: MKPolyLine
    /// - Returns: Data to safely encode
    //
    static func toArchive(polyline: MKPolyline) -> Data {
        let coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: polyline.pointCount)
        polyline.getCoordinates(coordsPointer, range: NSRange(location: 0, length: polyline.pointCount))
        var coords: [[String: AnyObject]] = []
        for index in 0..<polyline.pointCount {
            let latitude = NSNumber(value: coordsPointer[index].latitude)
            let longitude = NSNumber(value: coordsPointer[index].longitude)
            let coord = ["latitude": latitude, "longitude": longitude]
            coords.append(coord)
        }
        let polylineData = NSKeyedArchiver.archivedData(withRootObject: coords)
        return polylineData as Data
    }
}

extension NSApplicationDelegate {
    /// Ask the system if it's in Dark Mode
    ///
    /// - Returns: Yes if the Mac is in Dark Mode, No if it is not
    func isVibrantMode() -> Bool {
        return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ?  true : false
    }
}

extension CGFloat {
    var degreesToRadians: CGFloat { return self * .pi / 180 }
    var radiansToDegrees: CGFloat { return self * 180 / .pi }
}

extension Int64 {
    static func randomNumber<T: SignedInteger>(inRange range: ClosedRange<T> = 1...6) -> T {
        let length = Int64(range.upperBound - range.lowerBound + 1)
        let value = Int64(arc4random()) % length + Int64(range.lowerBound)
        return T(value)
    }
}

//[How to apply bold and italics](https://stackoverflow.com/questions/34499735/how-to-apply-bold-and-italics-to-an-nsmutableattributedstring-range))
extension NSFont {
    func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        // create a new font descriptor with the given traits
        let fontDesc = fontDescriptor.withSymbolicTraits(traits)
            // return a new font with the created font descriptor
        return NSFont(descriptor: fontDesc, size: pointSize)!
    }
    
    func setItalics() -> NSFont {
        return withTraits(.italic)
    }
    
    func setBold() -> NSFont {
        return withTraits(.bold)
    }
    
    func setBoldandItalics() -> NSFont {
        return withTraits([ .bold, .italic ])
    }
}

extension NSImage {
    /// Apply snadard filters to an NSImage
    ///
    /// - Parameter filter: Filter Name
    /// - Returns: NSImage based on the valid filter requested
    func filter(filter: String) -> NSImage? {
        let context = CIContext(options: nil)
        
        if let currentFilter = CIFilter(name: filter) {
            let imageData = self.tiffRepresentation!
            let beginImage = CIImage(data: imageData)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            if let output = currentFilter.outputImage {
                if let cgimg = context.createCGImage(output, from: output.extent) {
                    return NSImage(cgImage: cgimg, size: NSSize(width: 0, height: 0))
                } else {return nil}
            } else {return nil}
        } else {return nil}
    }
}

extension NSTextField {
    func bestheight(text: String, width: CGFloat) -> CGFloat {
        self.stringValue = text
        let getnumber = self.cell!.cellSize(forBounds: NSRect(x: CGFloat(0.0), y: CGFloat(0.0),
                                                              width: width, height: CGFloat(CGFloat.greatestFiniteMagnitude))).height
        
        return getnumber
    }

    func bestwidth(text: String, height: CGFloat) -> CGFloat {

        self.stringValue = text
        let getnumber = self.cell!.cellSize(forBounds: NSRect(x: CGFloat(0.0), y: CGFloat(0.0),
                                                              width: CGFloat(CGFloat.greatestFiniteMagnitude), height: height)).width
        
        return getnumber
    }
}

extension NSView {
    var backgroundColor: NSColor? {
        get {
            guard let layer = layer, let backgroundColor = layer.backgroundColor else { return nil }
            return NSColor(cgColor: backgroundColor)
        }
        set {
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
        }
    }
}

extension Optional {
    public var value: String {
        switch self {
        case .some(let wrappedValue):
            return "\(wrappedValue)"
        default:
            return "<nil>"
        }
    }
}

extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
}

/// Handy protocols
protocol Copyable: class {
    func copy() -> Self
}
