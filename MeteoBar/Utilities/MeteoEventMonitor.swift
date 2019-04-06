//
//  MeteoEventMonitor.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/15/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

class MeteoEventMonitor/*: NSObject*/ {
    private let eventMask: NSEvent.EventTypeMask
    private let eventHandler: (NSEvent?) -> Void
    private var theMonitor: AnyObject?
    private var _listening = false

    var listening: Bool {
        return _listening
    }
    
    ///
    /// You initialize an instance of this class by passing in a mask of events to listen for
    /// things like key down, scroll wheel moved, left mouse button click, etc – and an event handler.
    ///
    /// ## Important Notes ##
    ///
    /// 1. Initialize an instance of this class by passing in a mask of events to listen for (e.g., key down, scroll wheel moved, left mouse button click, etc) and an event handler).
    /// 2. start() returns an object for you to hold on to. Any time the event specified in the mask occurs, the system calls your handler.
    /// 3. To remove the global event monitor, call removeMonitor() in stop() and delete the returned object by setting it to nil.
    ///
    /// - parameters: None
    /// - throws: Nothing
    /// - returns:  Nothing
    ///
    public init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        eventHandler    = handler
        eventMask       = mask
        _listening      = false
    }
    
    ///
    /// Start the event monitor
    ///
    /// - parameters: None
    /// - throws: Nothing
    /// - returns:  Nothing
    ///
    public func start() {
        if _listening {
            log.warning("MeteoEventMonitor already listening; returning with no action.")
            return
        }
        theMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask, handler: eventHandler) as AnyObject?
        _listening = true
    }
    
    ///
    /// Stop the event monitor
    ///
    /// - parameters: None
    /// - throws: Nothing
    /// - returns:  Nothing
    ///
    public func stop() {
        if theMonitor != nil {
            print("Stopping Event Monitor")
            NSEvent.removeMonitor(theMonitor!)
            theMonitor = nil
            _listening = false
        }
    }
    
    ///
    /// We are be deallocated ... kill the monitor
    ///
    /// - parameters: None
    /// - throws: Nothing
    /// - returns:  Nothing
    ///
    deinit {
        print("DEINIT: Event Monitor")
        stop()
    }
}
