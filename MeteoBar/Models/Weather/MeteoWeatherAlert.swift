//
//  MeteoWeatherAlert.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/12/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import Cocoa

public enum MeteoAlertMessageType: String, Codable { case
    alert       = "Alert",
    update      = "Update",
    cancel      = "Cancel",
    unknown     = "Unknown"
}

public enum MeteoAlertSeverity: String, Codable { case
    extreme     = "Extreme",
    severe      = "Severe",
    moderate    = "Moderate",
    minor       = "Minor",
    unknown     = "Unknown"
}

public enum MeteoAlertCertainty: String, Codable { case
    observed    = "Observed",
    likely      = "Likely",
    possible    = "Possible",
    unlikely    = "Unlikley",
    unknown     = "Unknown"
}

public enum MeteoAlertUrgency: String, Codable { case
    immediate   = "Immediate",
    expected    = "Expected",
    future      = "Future",
    past        = "Past",
    unknown     = "Unknown"
}

///
/// Discreet Alert from NWS API
///
/// ## API Reference ##
/// [Documentation | National Weather Service](https://forecast-v3.weather.gov/documentation?preview=stations/KVSF/observations/current%7Capplication/rss%2Bxml)
///
/// ## Example API Call ##
/// [Exammple - VAZ505](https://api.weather.gov/alerts/active/zone/VAZ505)
///
class MeteoWeatherAlert: NSObject {
    /// Public Accessors
    public var messageType: MeteoAlertMessageType {return _messageType}
    public var severity: MeteoAlertSeverity {return _severity}
    public var certainty: MeteoAlertCertainty {return _certainty}
    public var urgency: MeteoAlertUrgency {return _urgency}
    public var detail: String {return _description}
    public var instruction: String {return _instruction}
    public var category: String {return _category}
    public var headline: String {return _headline}
    public var areaDescription: String {return _areaDesc}
    public var effectiveUntil: Date {return _effective}
    public var status: String {return _status}
    public var sender: String {return _sender}
    public var expiressOn: Date {return _expires}
    public var event: String {return _event}
    public var alertType: String {return _type}
    public var onset: Date {return _onset}
    public var sentOn: Date {return _sent}
    public var endsOn: Date {return _ends}
    public var identfier: String {return _identifier}
    public var referenceIDs: [String] {return _referenceIDs}

    /// Private Internals
    private var _acknowdleged: Bool
    private var _identifier: String
    private var _type: String
    private var _areaDesc: String
    private var _sent: Date
    private var _effective: Date
    private var _onset: Date
    private var _ends: Date
    private var _expires: Date
    private var _status: String
    private var _messageType: MeteoAlertMessageType
    private var _severity: MeteoAlertSeverity
    private var _category: String
    private var _certainty: MeteoAlertCertainty
    private var _urgency: MeteoAlertUrgency
    private var _event: String
    private var _headline: String
    private var _sender: String
    private var _description: String
    private var _instruction: String
    private var _referenceIDs = [String]()
    
    public init(anID: String, aType: String, aDesc: String, sentAt: Date,
                effectiveTill: Date, willStart: Date, willEnd: Date, willExpire: Date,
                aStatus: String, aMessageType: MeteoAlertMessageType, aSeverity: MeteoAlertSeverity,
                aCategory: String, aCertainty: MeteoAlertCertainty, anUrgency: MeteoAlertUrgency,
                anEvent: String, aHeadline: String, aSender: String, aDetail: String,
                anInstruction: String, references: [String]) {
        
        _identifier      = anID
        _type            = aType
        _areaDesc        = aDesc
        _sent            = sentAt
        _effective       = effectiveTill
        _onset           = willStart
        _ends            = willEnd
        _expires         = willExpire
        _status          = aStatus
        _messageType     = aMessageType
        _severity        = aSeverity
        _category        = aCategory
        _certainty       = aCertainty
        _urgency         = anUrgency
        _event           = anEvent
        _headline        = aHeadline
        _sender          = aSender
        _acknowdleged    = false
        _description     = aDetail
        _instruction     = anInstruction
        _referenceIDs    = references
    }
    
    ///
    /// Are the two Alerts the same?  We want to check IDs and Alert Types
    ///
    /// - throws: Nothing
    /// - returns: True/False depending on equality
    ///
    static func == (lhs: MeteoWeatherAlert, rhs: MeteoWeatherAlert) -> Bool {
        return lhs._identifier == rhs._identifier && lhs._type == rhs._type
    }
    
    ///
    /// Are the two Alerts the same?  We want to check IDs and Alert Types
    ///
    /// - throws: Nothing
    /// - returns: True/False depending on equality
    ///
    static func != (lhs: MeteoWeatherAlert, rhs: MeteoWeatherAlert) -> Bool {
        return !((lhs._identifier == rhs._identifier) && (lhs._type == rhs._type))
    }
    
    ///
    /// Mark the Alert as acknowledged
    ///
    /// - throws: Nothing
    /// - returns: Nothing
    ///
    public func acknowledge() {
        _acknowdleged = true
    }

    ///
    /// Has this Alert been acknowledged?
    ///
    /// - throws: Nothing
    /// - returns: True/False depending on equality
    ///
    public func isAcknoledged() -> Bool {
        return _acknowdleged
    }
}
