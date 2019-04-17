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

// MARK: - Bundle Extensions
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

// MARK: - Date Extensions
extension Date {
    func dayOfWeek() -> String? {
        
        var stringDay: String?
        
        let cal: Calendar = Calendar.current
        let comp: DateComponents = (cal as NSCalendar).components(.weekday, from: self)
        
        switch comp.weekday {
        case 1?:
            stringDay = "Sunday"
        case 2?:
            stringDay = "Monday"
        case 3?:
            stringDay = "Tuesday"
        case 4?:
            stringDay = "Wednesday"
        case 5?:
            stringDay = "Thursday"
        case 6?:
            stringDay = "Friday"
        case 7?:
            stringDay = "Saturday"
        default:
            break
        }
        
        return stringDay
    }
    
    func hour() -> Int {
        //Get Hour
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components(.hour, from: self)
        let hour = components.hour
        
        //Return Hour
        return hour!
    }
    
    func minute() -> Int {
        //Get Minute
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components(.minute, from: self)
        let minute = components.minute
        
        //Return Minute
        return minute!
    }
    
    func toShortTimeString() -> String {
        //Get Short Time String
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: self)
        
        //Return Short Time String
        return timeString
    }
    
    func toLongTimeString() -> String {
        //Get Short Time String
        let formatter = DateFormatter()
        formatter.timeStyle = .long
        let timeString = formatter.string(from: self)
        
        //Return Short Time String
        return timeString
    }

    func toLongDateString() -> String {
        //Get Short Time String
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let timeString = formatter.string(from: self)
        
        //Return Short Time String
        return timeString
    }
    
    func toShortDateString() -> String {
        //Get Short Time String
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let timeString = formatter.string(from: self)
        
        //Return Short Time String
        return timeString
    }
    
    func toLongDateTimeString() -> String {
        //Get Short Time String
        let formatter = DateFormatter()
        formatter.timeStyle = .long
        formatter.dateStyle = .long
        let timeString = formatter.string(from: self)
        
        //Return Short Time String
        return timeString
    }
    
    func toShortDateTimeString() -> String {
        //Get Short Time String
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        let timeString = formatter.string(from: self)
        
        //Return Short Time String
        return timeString
    }
    
    func localToUTCDateTime() -> String {
        // 2019-01-08T17:04:16-08:00 (RFC3339 accounting for local time zone)
        let format = ISO8601DateFormatter()
        format.formatOptions = [.withInternetDateTime]
        format.timeZone = TimeZone.current
        return format.string(from: self)
    }
}

// MARK: - FloatingPoint Extensions
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

// MARK: - CLGeocoder Extensions
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

// MARK: - CLLocationCoordinate2D Extensions
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

// MARK: - MKMultiPoint Extensions
public extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: pointCount)
        
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        
        return coords
    }
}

// MARK: - MKMapView Extensions
extension MKMapView {
    /// This Mercator is valid for 21 zoom levels
    private var mercatorOffset: Double {
        return 268435456.0
    }
    
    /// This Mercator is valid for 21 zoom levels
    private var mercatorRadius: Double {
        return 85445659.44705395
    }

    /// Zooms out a MKMapView to enclose all its annotations (inc. current location)
    ///
    ///  ## Notes ##
    ///    [Zooms out to enclose all annotations](https://gist.github.com/andrewgleave/915374)
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
    
    /// Zoom map to desired zoom level
    ///
    /// - Parameters:
    ///   - centerCoordinate: point to zoom on
    ///   - zoomLevel: How far to zoom
    ///   - shouldAnimate: should we animate the map while zooming
    ///
    func zoomToPoint(toCenterCoordinate centerCoordinate: CLLocationCoordinate2D, zoomLevel: UInt, shouldAnimate: Bool = true) {
        let zoomLevel = min(zoomLevel, 20)
        let span = self.coordinateSpan(centerCoordinate: centerCoordinate, zoomLevel: zoomLevel)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        self.setRegion(region, animated: shouldAnimate)
    }
    
    /// Get Pixel on Map for Given Longitude
    ///
    /// - Parameter longitude: longitude
    /// - Returns: pixel value
    ///
    private func longitudeToPixelSpaceX(longitude: Double) -> Double {
        return round(mercatorOffset + mercatorRadius * longitude * Double.pi / 180.0)
    }
    
    /// Get Pixel on Map for Given Latitude
    ///
    /// - Parameter latitude: latitude
    /// - Returns: pixel value for given latitude
    ///
    private func latitudeToPixelSpaceY(latitude: Double) -> Double {
        return round(mercatorOffset - mercatorRadius * simd.log((1 + sin(latitude * Double.pi / 180.0)) / (1 - sin(latitude * Double.pi / 180.0))) / 2.0)
    }
    
    /// Get Longitude for given Pixel
    ///
    /// - Parameter pixelX: pixel
    /// - Returns: longitude for given pixel
    ///
    private  func pixelSpaceXToLongitude(pixelX: Double) -> Double {
        return ((round(pixelX) - mercatorOffset) / mercatorRadius) * 180.0 / Double.pi
    }
    
    /// Get Latitude for given Pixel
    ///
    /// - Parameter pixelX: pixel
    /// - Returns: latitude for given pixel
    ///
    private func pixelSpaceYToLatitude(pixelY: Double) -> Double {
        return (Double.pi / 2.0 - 2.0 * atan(exp((round(pixelY) - mercatorOffset) / mercatorRadius))) * 180.0 / Double.pi
    }
    
    /// Determines the map span of the given Lat/Lon
    ///
    /// - Parameters:
    ///   - mapView: given MapView
    ///   - centerCoordinate: Lat/Lon
    ///   - zoomLevel: desird zoom level
    /// - Returns: Map Span
    ///
    private func coordinateSpan(centerCoordinate: CLLocationCoordinate2D, zoomLevel: UInt) -> MKCoordinateSpan {
        let centerPixelX = longitudeToPixelSpaceX(longitude: centerCoordinate.longitude)
        let centerPixelY = latitudeToPixelSpaceY(latitude: centerCoordinate.latitude)
        
        let zoomExponent = Double(20 - zoomLevel)
        let zoomScale = pow(2.0, zoomExponent)
        
        let mapSizeInPixels = self.bounds.size
        let scaledMapWidth =  Double(mapSizeInPixels.width) * zoomScale
        let scaledMapHeight = Double(mapSizeInPixels.height) * zoomScale
        
        let topLeftPixelX = centerPixelX - (scaledMapWidth / 2)
        let topLeftPixelY = centerPixelY - (scaledMapHeight / 2)
        
        // find delta between left and right longitudes
        let minLng = pixelSpaceXToLongitude(pixelX: topLeftPixelX)
        let maxLng = pixelSpaceXToLongitude(pixelX: topLeftPixelX + scaledMapWidth)
        let longitudeDelta = maxLng - minLng
        
        let minLat = pixelSpaceYToLatitude(pixelY: topLeftPixelY)
        let maxLat = pixelSpaceYToLatitude(pixelY: topLeftPixelY + scaledMapHeight)
        let latitudeDelta = -1 * (maxLat - minLat)
        
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        return span
    }
}

// MARK: - MKMapRect Extensions
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

// MARK: - MKPolygon Extensions
extension MKPolygon {
    func doesContain(coordinate: CLLocationCoordinate2D) -> Bool {
        let polygonRenderer = MKPolygonRenderer(polygon: self)
        let currentMapPoint: MKMapPoint = MKMapPoint(coordinate)
        let polygonViewPoint: CGPoint = polygonRenderer.point(for: currentMapPoint)

        return polygonRenderer.path.contains(polygonViewPoint)
    }
}

// MARK: - MKMeteoPolyline Extensions
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
        locations.removeAll()
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
        
        coords.removeAll()
        coordsPointer.deallocate()
        return polylineData as Data
    }
}

// MARK: - NSApplication Extensions
extension NSApplicationDelegate {
    /// Ask the system if it's in Dark Mode
    ///
    /// - Returns: Yes if the Mac is in Dark Mode, No if it is not
    func isVibrantMode() -> Bool {
        return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ?  true : false
    }
}

// MARK: - CGFloat Extensions
extension CGFloat {
    var degreesToRadians: CGFloat { return self * .pi / 180 }
    var radiansToDegrees: CGFloat { return self * 180 / .pi }
}

// MARK: - Int64 Extensions
extension Int64 {
    static func randomNumber<T: SignedInteger>(inRange range: ClosedRange<T> = 1...6) -> T {
        let length = Int64(range.upperBound - range.lowerBound + 1)
        let value = Int64(arc4random()) % length + Int64(range.lowerBound)
        return T(value)
    }
}

// MARK: - NSFont Extensions
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

// MARK: - NSImage Extensions
extension NSImage {
    /// Apply snadard filters to an NSImage
    ///
    /// - Parameter filter: Filter Name
    /// - Returns: NSImage based on the valid filter requested
/*
    func filter(filter: String) -> NSImage? {
        let image = CIImage(data: (self.tiffRepresentation!))
            
            if let filter = CIFilter(name: filter) {
                filter.setDefaults()
                filter.setValue(image, forKey: kCIInputImageKey)
                
                let context = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
                return autoreleasepool { () -> NSImage? in
                    guard let imageRef = context.createCGImage(filter.outputImage!, from: image!.extent) else {
                        context.clearCaches()
                        context.reclaimResources()
                        return nil
                    }
                    context.clearCaches()
                    context.reclaimResources()
                    return NSImage(cgImage: imageRef, size: NSSize(width: 0, height: 0))
                }
            } else {
                return nil
            }
    }
*/
/*    func filter(filter: String) -> NSImage? {
        return autoreleasepool { [weak self] () -> NSImage? in
            let image = CIImage(data: (self?.tiffRepresentation!)!)
            
            if let filter = CIFilter(name: filter) {
                filter.setDefaults()
                filter.setValue(image, forKey: kCIInputImageKey)
                
                let context = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
                guard let imageRef = context.createCGImage(filter.outputImage!, from: image!.extent) else {
                    context.clearCaches()
                    context.reclaimResources()
                    return nil
                }
                context.clearCaches()
                context.reclaimResources()
                return NSImage(cgImage: imageRef, size: NSSize(width: 0, height: 0))
            } else {
                return nil
            }
        }
    }
*/
    func filter(filter: String) -> NSImage? {
        return autoreleasepool { [weak self] () -> NSImage? in
            let image = CIImage(data: (self?.tiffRepresentation!)!)
            var imageRef: CGImage?
            
            if let filter = CIFilter(name: filter) {
                filter.setDefaults()
                filter.setValue(image, forKey: kCIInputImageKey)
                
                let context = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
                imageRef = context.createCGImage(filter.outputImage!, from: image!.extent)

                context.clearCaches()
                context.reclaimResources()
                let img =  NSImage(cgImage: imageRef!, size: NSSize(width: 0, height: 0))
                
                imageRef = nil
                return img
            } else {
                return nil
            }
        }
    }

    /// Resize existing image to new size
    ///
    /// - Parameter newSize: desired width and height
    /// - Returns: new image (or nil on error)
    ///
    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
            ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()
            
            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }
        
        return nil
    }
}

// MARK: - NSTableView Extensions
extension NSTableView {
    func reloadDataKeepingSelection(extendSelection: Bool = false) {
        let selectedRowIndexes = self.selectedRowIndexes
        self.reloadData()
        self.selectRowIndexes(selectedRowIndexes, byExtendingSelection: extendSelection)
    }
    
    func selectRow(at index: Int) {
        selectRowIndexes(.init(integer: index), byExtendingSelection: false)
        if let action = action {
            perform(action)
        }
    }
}

// MARK: - NSTextField Extensions
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

// MARK: - NSView Extensions
extension NSView {
    var viewBackgroundColor: NSColor? {
        get {
            guard let layer = layer, let backgroundColor = layer.backgroundColor else { return nil }
            return NSColor(cgColor: backgroundColor)
        }
        set {
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
        }
    }
/*
    func bringSubviewToFront(_ view: NSView) {
        var theView = view
        self.sortSubviews({ [unowned self] (viewA,viewB,rawPointer) in
            let view = rawPointer?.load(as: NSView.self)
            
            switch view {
            case viewA:
                return ComparisonResult.orderedDescending
            case viewB:
                return ComparisonResult.orderedAscending
            default:
                return ComparisonResult.orderedSame
            }
        }, context: &theView)
    }
*/
}

// MARK: - Optional Extensions
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

// MARK: - String Extensions
extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }

    func toISODate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"
        return (dateFormatter.date(from: self)!)
    }
    
    //Convert UTC To Local Date by passing date formats value
    func UTCToLocal(incomingFormat: String, outGoingFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = incomingFormat
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let dt = dateFormatter.date(from: self)
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = outGoingFormat
        
        return dateFormatter.string(from: dt ?? Date())
    }
    
    //Convert Local To UTC Date by passing date formats value
    func localToUTC(incomingFormat: String, outGoingFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = incomingFormat
        dateFormatter.calendar = NSCalendar.current
        dateFormatter.timeZone = TimeZone.current
        
        let dt = dateFormatter.date(from: self)
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = outGoingFormat
        
        return dateFormatter.string(from: dt ?? Date())
    }
}

/// Handy protocols
protocol Copyable: class {
    func copy() -> Self
}
