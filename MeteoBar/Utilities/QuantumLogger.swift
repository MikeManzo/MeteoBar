//
//  QuantumLogger.swift
//  MeteoBar
//
//  Created by Mike Manzo on 1/13/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//

import SwiftyBeaver
import Foundation
import GRDB

enum DBLogError: Error, CustomStringConvertible {
    case dateError
    case dbCreateError
    
    var description: String {
        switch self {
        case .dateError: return "Unable to sort logs by date"
        case .dbCreateError: return "Warning! Could not create folder /Library/Caches/<App Name>"
        }
    }
}

/// Subclass of SiftyBeaver logging system
/// [GRDB.swift](https://github.com/groue/GRDB.swift)
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
}

// A plain MeteoLogDB struct that represents what we want to store in th DB
struct MeteoLogDB {
    var function: String
    var context: String
    var thread: String
    var file: String
    var msg: String
    var date: Date
    var level: Int
    var id: Int64?
    var line: Int
}

// MARK: - Persistence

// Turn Player into a Codable Record.
// See https://github.com/groue/GRDB.swift/blob/master/README.md#records
extension MeteoLogDB: Codable, TableRecord, FetchableRecord, MutablePersistableRecord {
    // Add ColumnExpression to Codable's CodingKeys so that we can use them as database columns.
    //
    // [See](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types)
    private enum CodingKeys: String, CodingKey, ColumnExpression {
        case id, msg, thread, file, function, line, context, level, date
    }
    
    // Update a MeteoLogDB id after it has been inserted into the database.
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

// MARK: - Database access

// Define some useful MeteoLogDB requests.
// [See](https://github.com/groue/GRDB.swift/blob/master/README.md#requests)
///
extension MeteoLogDB {
    static func orderedByMsg() -> QueryInterfaceRequest<MeteoLogDB> {
        return MeteoLogDB.order(CodingKeys.msg)
    }

    static func orderedByDateAscending() -> QueryInterfaceRequest<MeteoLogDB> {
        return MeteoLogDB.order(CodingKeys.date.asc)
    }

    static func orderedByDateDescending() -> QueryInterfaceRequest<MeteoLogDB> {
        return MeteoLogDB.order(CodingKeys.date.desc)
    }

    static func orderedByLevelAscending() -> QueryInterfaceRequest<MeteoLogDB> {
        return MeteoLogDB.order(CodingKeys.level.asc, CodingKeys.level)
    }
    
    static func orderedByLevelDescending() -> QueryInterfaceRequest<MeteoLogDB> {
        return MeteoLogDB.order(CodingKeys.level.desc, CodingKeys.level)
    }
    
    static func orderedByLineDescending() -> QueryInterfaceRequest<MeteoLogDB> {
        return MeteoLogDB.order(CodingKeys.line.desc, CodingKeys.line)
    }
 
    static func orderedByLineAscending() -> QueryInterfaceRequest<MeteoLogDB> {
        return MeteoLogDB.order(CodingKeys.line.asc, CodingKeys.line)
    }
}

/// A type responsible for initializing the application database.
///
struct AppDatabase {
    
    /// Creates a fully initialized database at path
    static func openDatabase(atPath path: String) throws -> DatabaseQueue {
        // Connect to the database
        // [See](https://github.com/groue/GRDB.swift/blob/master/README.md#database-connections)
        let dbQueue = try DatabaseQueue(path: path)
        
        // Define the database schema
        try migrator.migrate(dbQueue)
        
        return dbQueue
    }
    
    /// The DatabaseMigrator that defines the database schema.
    ///
    /// [See](https://github.com/groue/GRDB.swift/blob/master/README.md#migrations)
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("createLog") { db in
            // Create the table [Example](https://github.com/groue/GRDB.swift#create-tables)
            try db.create(table: "meteologdb") { t in
                t.autoIncrementedPrimaryKey("id")
                
                // Sort player names in a localized case insensitive fashion by default
                // [See](https://github.com/groue/GRDB.swift/blob/master/README.md#unicode)
                t.column("date", .date).notNull().collate(.localizedCaseInsensitiveCompare)
                t.column("level", .integer).notNull()
                t.column("msg", .text).notNull().collate(.localizedCaseInsensitiveCompare)
                t.column("line", .integer).notNull()
                t.column("function", .text).notNull().collate(.localizedCaseInsensitiveCompare)
                t.column("file", .text).notNull().collate(.localizedCaseInsensitiveCompare)
                t.column("thread", .text).notNull().collate(.localizedCaseInsensitiveCompare)
                t.column("context", .text).notNull().collate(.localizedCaseInsensitiveCompare)
            }
        }
        
        return migrator
    }
}

/// SQLight Destination
public class SQLDestination: BaseDestination {
    public var logFileURL: URL?

    // The shared database queue
    var dbQueue: DatabaseQueue!
    
    override public var defaultHashValue: Int {return 2}
    
    /// Create (or open) the database for storing the log(s)
    ///
    /// - Parameter dbName: desired DB Name
    /// - Throws: if we cannot open or create the DB ... throw an error
    ///
    public init(dbName: String = "swiftybeaver.sqlite") throws {
        let fileManager = FileManager.default
        var baseURL: URL?

        #if os(OSX)
        if let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            baseURL = url
            if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String {
                do {
                    if let appURL = baseURL?.appendingPathComponent(appName, isDirectory: true) {
                        try fileManager.createDirectory(at: appURL, withIntermediateDirectories: true, attributes: nil)
                        baseURL = appURL
                    }
                } catch {
                    throw(DBLogError.dbCreateError)
                }
            }
        }
        #else
        #if os(Linux)
        baseURL = URL(fileURLWithPath: "/var/cache")
        #else
        // iOS, watchOS, etc. are using the caches directory
        if let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            baseURL = url
        }
        #endif
        #endif
        
        if let baseURL = baseURL {
            logFileURL = baseURL.appendingPathComponent(dbName, isDirectory: false)
            dbQueue = try AppDatabase.openDatabase(atPath: logFileURL!.path)
        }
        super.init()
    }

    /// send the log to the destination (DB in this case)
    ///
    /// - Parameters:
    ///   - level: level of loggable event
    ///   - msg: message of loggable event
    ///   - thread: thread of loggable event
    ///   - file: file of loggable event
    ///   - function: function of loggable event
    ///   - line: line of loggable event
    ///   - context: context of loggable event
    /// - Returns: a string representation of loggable event
    ///
    override public func send(_ level: SwiftyBeaver.Level, msg: String, thread: String,
                              file: String, function: String, line: Int, context: Any? = nil) -> String? {
        let formattedString = super.send(level, msg: msg, thread: thread, file: file, function: function, line: line, context: context)
        do {
            try dbQueue.write { db in
                var newLog = MeteoLogDB(function: function, context: "", thread: thread, file: file, msg: msg,
                                 date: Date(), level: level.rawValue, id: nil, line: line)
                try newLog.insert(db)
            }
        } catch let error as DatabaseError {
            print("Code: \(error.resultCode), Extended:\(error.extendedResultCode), Message:\(error.message ?? ""), SQL:\(error.sql ?? ""), Desc:\(error.description)")
        } catch {
            print("Huh?")
        }
        
        return formattedString
    }
    
    /// return an array of MeteoDB objects in date-ascending order
    ///
    /// - Returns: MeteoDB objects in date-ascending order
    /// - Throws: error if we cannot make this happen
    ///
    func orderByDateAscending() throws -> [MeteoLogDB]? {
        var logs: [MeteoLogDB]?
    
        dbQueue.read { db in
            do {
                logs = try MeteoLogDB.orderedByDateAscending().fetchAll(db)
            } catch {
                log.debug(DBLogError.dateError)
            }
        }
        
        return logs
    }

    /// return an array of MeteoDB objects in date-descending order
    ///
    /// - Returns: MeteoDB objects in date-descending order
    /// - Throws: error if we cannot make this happen
    ///
    func orderByDateDescending() throws -> [MeteoLogDB]? {
        var logs: [MeteoLogDB]?
        
        dbQueue.read { db in
            do {
                logs = try MeteoLogDB.orderedByDateDescending().fetchAll(db)
            } catch {
                log.debug(DBLogError.dateError)
            }
        }
        
        return logs
    }

    /// return an array of MeteoDB objects in line-ascending order
    ///
    /// - Returns: MeteoDB objects in line-ascending order
    /// - Throws: error if we cannot make this happen
    ///
    func orderByLineAscending() throws -> [MeteoLogDB]? {
        var logs: [MeteoLogDB]?
        
        dbQueue.read { db in
            do {
                logs = try MeteoLogDB.orderedByLineAscending().fetchAll(db)
            } catch {
                log.debug(DBLogError.dateError)
            }
        }
        
        return logs
    }
    
    /// return an array of MeteoDB objects in line-descending order
    ///
    /// - Returns: MeteoDB objects in line-descending order
    /// - Throws: error if we cannot make this happen
    ///
    func orderByLineDescending() throws -> [MeteoLogDB]? {
        var logs: [MeteoLogDB]?
        
        dbQueue.read { db in
            do {
                logs = try MeteoLogDB.orderedByLineDescending().fetchAll(db)
            } catch {
                log.debug(DBLogError.dateError)
            }
        }
        
        return logs
    }

    /// return an array of MeteoDB objects in level-ascending order
    ///
    /// - Returns: MeteoDB objects in line-ascending order
    /// - Throws: error if we cannot make this happen
    ///
    func orderByLevelAscending() throws -> [MeteoLogDB]? {
        var logs: [MeteoLogDB]?
        
        dbQueue.read { db in
            do {
                logs = try MeteoLogDB.orderedByLevelAscending().fetchAll(db)
            } catch {
                log.debug(DBLogError.dateError)
            }
        }
        
        return logs
    }
    
    /// return an array of MeteoDB objects in level-descending order
    ///
    /// - Returns: MeteoDB objects in level-descending order
    /// - Throws: error if we cannot make this happen
    ///
    func orderByLevelDescending() throws -> [MeteoLogDB]? {
        var logs: [MeteoLogDB]?
        
        dbQueue.read { db in
            do {
                logs = try MeteoLogDB.orderedByLevelDescending().fetchAll(db)
            } catch {
                log.debug(DBLogError.dateError)
            }
        }
        
        return logs
    }
    
    /// Let's do some housecleaning
    ///
    deinit {
        if let dbQueue = dbQueue {
            dbQueue.releaseMemory()
        }
    }
}
