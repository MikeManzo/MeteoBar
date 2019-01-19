//
//  QLExtensions.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/14/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Foundation
import Cocoa

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

extension NSApplicationDelegate {
    /// Ask the system if it's in Dark Mode
    ///
    /// - Returns: Yes if the Mac is in Dark Mode, No if it is not
    static func isVibrantMode() -> Bool {
        return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ?  true : false
    }
}

/// Handy protocols
protocol Copyable: class {
    func copy() -> Self
}
