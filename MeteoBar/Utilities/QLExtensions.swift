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
    static func getCountryCode(lat: Double, lon: Double, _ callback: @escaping (_ country: String?, _ error: Error?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon)) { (placemarks, err) in
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

///
/// [Zooms out a MKMapView to enclose all its annotations](https://gist.github.com/andrewgleave/915374)
///
extension MKMapView {
    /// Zooms out a MKMapView to enclose all its annotations (inc. current location)
    ///
    /// - Parameter animated: animate the map when we wish to change extent
    /// - Parameter shouldIncludeUserAccuracyRange: show accuracy range circle
    /// - Parameter padding: Edge constraints to apply to map
    ///
    func fitToAnnotaions(animated: Bool = true,
                         shouldIncludeUserAccuracyRange: Bool = true,
                         edgePadding: NSEdgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)) {
        var mapOverlays = overlays
        
        if shouldIncludeUserAccuracyRange, let userLocation = userLocation.location {
            let userAccuracyRangeCircle = MKCircle(center: userLocation.coordinate, radius: userLocation.horizontalAccuracy)
            mapOverlays.append(MKOverlayRenderer(overlay: userAccuracyRangeCircle).overlay)
        }
        
        let zoomRect = MKMapRect.boundingForOverlays(forOverlays: mapOverlays)
        setVisibleMapRect(zoomRect, edgePadding: edgePadding, animated: animated)
    }
}

///
/// [Zooms out a MKMapView to enclose all its annotations](https://gist.github.com/andrewgleave/915374)
///
extension MKMapRect {
    /// Get the bounding box for the given arrat of overlays
    ///
    /// - Parameter overlays: the overlays to check
    /// - Returns: THE rect that represents the minimum rect that encompasses the overlays
    ///
    static func boundingForOverlays(forOverlays overlays: [MKOverlay]) -> MKMapRect {
        var resultRect: MKMapRect = .null
        
        overlays.forEach { overlay in
            let rect: MKMapRect = overlay.boundingMapRect
            resultRect = resultRect.union(rect)
        }
        
        return resultRect
    }
}

extension MKPolygon {
    func doesContain(coordinate: CLLocationCoordinate2D) -> Bool {
        let polygonRenderer = MKPolygonRenderer(polygon: self)
        let currentMapPoint: MKMapPoint = MKMapPoint(coordinate)
        let polygonViewPoint: CGPoint = polygonRenderer.point(for: currentMapPoint)

        return polygonRenderer.path.contains(polygonViewPoint)
    }
}

///
/// [To-From Archive Reference](https://stackoverflow.com/questions/36761841/how-to-store-an-mkpolyline-attribute-as-transformable-in-ios-coredata-with-swift#)
///
extension MKMeteoPolyline {
    /// SwifterSwift: Create a new MKMeteoPolyline from a provided Array of coordinates.
    ///
    /// - Parameter coordinates: Array of CLLocationCoordinate2D(s)
    ///
    public convenience init(coordinates: [CLLocationCoordinate2D]) {
        var refCoordinates = coordinates
        self.init(coordinates: &refCoordinates, count: refCoordinates.count)
    }
    
    /// Make MKPolyLine decodable
    ///
    /// - Parameter polylineArchive: Data description of MKPolyLine
    /// - Returns: MKPolyLine
    //
    static func fromArchive(polylineArchive: Data) -> (MKMeteoPolyline?, String?) {
        guard let data = NSKeyedUnarchiver.unarchiveObject(with: polylineArchive as Data),
        let myData = data as? [String: [[String: AnyObject]]] else {
                return (nil, nil)
        }
        var locations: [CLLocation] = []
        var lineName: String?
        for (name, polyline) in myData {
            print ("Name-->\(name)")
            lineName = name
            for item in polyline {
                if let latitude = item["latitude"]?.doubleValue,
                    let longitude = item["longitude"]?.doubleValue {
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    locations.append(location)
                }
            }
        }
        var coordinates = locations.map({(location: CLLocation) -> CLLocationCoordinate2D in return location.coordinate})
        let result = MKMeteoPolyline(coordinates: &coordinates, count: locations.count)
        return (result, lineName)
    }
    
    /// Make MKPolyLine encodable
    ///
    /// - Parameter polylineArchive: MKPolyLine
    /// - Returns: Data to safely encode
    //
    static func toArchive(polyline: MKMeteoPolyline, lineName: String) -> Data {
        let coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: polyline.pointCount)
        polyline.getCoordinates(coordsPointer, range: NSRange(location: 0, length: polyline.pointCount))
        var coords: [[String: AnyObject]] = []
        for index in 0..<polyline.pointCount {
            let latitude = NSNumber(value: coordsPointer[index].latitude)
            let longitude = NSNumber(value: coordsPointer[index].longitude)
            let coord = ["latitude": latitude, "longitude": longitude]
            coords.append(coord)
        }
        let polylineData = NSKeyedArchiver.archivedData(withRootObject: [lineName: coords])
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
