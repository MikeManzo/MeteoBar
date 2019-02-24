//
//  QuantumLogger.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/13/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Foundation
import SwiftyBeaver

/// Subclass of SiftyBeaver logging system
open class QuantumLogger: SwiftyBeaver {
    
    /// Catch errors so we can notify the user
    ///
    /// - Parameters:
    ///   - message: <#message description#>
    ///   - file: <#file description#>
    ///   - function: <#function description#>
    ///   - line: <#line description#>
    ///   - context: <#context description#>
    override open class func error(_ message: @autoclosure () -> Any, _
                                    file: String = #file,
                                   _ function: String = #function,
                                   line: Int = #line,
                                   context: Any? = nil) {
        
        super.error(message, file, function,  line: line,  context: context)
        
        let alert = NSAlert()
        alert.messageText = "Meteobar has encountred an error"
        alert.informativeText = message() as? String ?? "Something went wrong. No Message provided."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Resume")
        
        DispatchQueue.main.async {
            alert.runModal()
        }
    }
    
    /// log something which help during debugging (low priority)
    ///
    /// - Parameters:
    ///   - message: <#message description#>
    ///   - file: <#file description#>
    ///   - function: <#function description#>
    ///   - line: <#line description#>
    ///   - context: <#context description#>
    override open class func verbose(_ message: @autoclosure () -> Any, _
                                    file: String = #file,
                                     _ function: String = #function,
                                     line: Int = #line,
                                     context: Any? = nil) {
        
        super.verbose(message, file, function,  line: line,  context: context)
    }
    
    ///
    /// log something which help during debugging (low priority)
    ///
    /// - Parameters:
    ///   - message: <#message description#>
    ///   - file: <#file description#>
    ///   - function: <#function description#>
    ///   - line: <#line description#>
    ///   - context: <#context description#>
    override open class func debug(_ message: @autoclosure () -> Any, _
                                   file: String = #file,
                                   _ function: String = #function,
                                   line: Int = #line,
                                   context: Any? = nil) {
        
        super.debug(message, file, function,  line: line,  context: context)
    }
    
    /// log something which you are really interested but which is not an issue or error (normal priority)
    ///
    /// - Parameters:
    ///   - message: <#message description#>
    ///   - file: <#file description#>
    ///   - function: <#function description#>
    ///   - line: <#line description#>
    ///   - context: <#context description#>
    override open class func info(_ message: @autoclosure () -> Any, _
                                  file: String = #file,
                                  _ function: String = #function,
                                  line: Int = #line,
                                  context: Any? = nil) {
        
        super.info(message, file, function,  line: line,  context: context)
    }
    
    /// log something which may cause big trouble soon (high priority)
    ///
    /// - Parameters:
    ///   - message: <#message description#>
    ///   - file: <#file description#>
    ///   - function: <#function description#>
    ///   - line: <#line description#>
    ///   - context: <#context description#>
    override open class func warning(_ message: @autoclosure () -> Any, _
                                    file: String = #file,
                                     _ function: String = #function,
                                     line: Int = #line,
                                     context: Any? = nil) {
        
        super.warning(message, file, function,  line: line,  context: context)
    }
}
