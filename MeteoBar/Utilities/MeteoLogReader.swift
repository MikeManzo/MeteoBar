//
//  MeteoLogReader.swift
//  MeteoBar
//
//  Created by Mike Manzo on 3/24/19.
//  Copyright © 2019 Quantum Joker. All rights reserved.
//
// To parse the JSON, add this file to your project and do:
//
//   let meteoLogReader = try MeteoLogReader(json)
//
// To parse values from Alamofire responses:
//
//   Alamofire.request(url).responseMeteoLogReader { response in
//     if let meteoLogReader = response.result.value {
//       ...
//     }
//   }
//   SwiftyBeaver output Example.  Note - one line is a self-contained JSON entry; there are no arrays of entries
//   {"thread":"","function":"addBridgeToQueue()","level":2,"message":"Meteobridge[Hirst Farm] will poll every 3 seconds.","file":"filename","line":185,"timestamp":1553449651.575336}
//
//  Pretty:
//   {
//    "timestamp": 1553449411.2047319,
//    "message": "File Logging Enabled",
//    "thread": "",
//    "function": "enableFileLogging()",
//    "level": 2,
//    "line": 105,
//    "file": "\/Users\/mike\/Documents\/Dev\/MeteoBar\/MeteoBar\/AppDelegate.swift"
//    }
//
import Foundation
import Alamofire

class MeteoLogReader: Codable {
    let file, thread, function: String
    let timestamp: Double
    let message: String
    let line, level: Int
    
    init(file: String, thread: String, function: String, timestamp: Double, message: String, line: Int, level: Int) {
        self.file = file
        self.thread = thread
        self.function = function
        self.timestamp = timestamp
        self.message = message
        self.line = line
        self.level = level
    }
}

// MARK: Convenience initializers and mutators
extension MeteoLogReader {
    convenience init(data: Data) throws {
        let me = try newJSONDecoder().decode(MeteoLogReader.self, from: data)
        self.init(file: me.file, thread: me.thread, function: me.function, timestamp: me.timestamp, message: me.message, line: me.line, level: me.level)
    }
    
    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        file: String? = nil,
        thread: String? = nil,
        function: String? = nil,
        timestamp: Double? = nil,
        message: String? = nil,
        line: Int? = nil,
        level: Int? = nil
        ) -> MeteoLogReader {
        return MeteoLogReader(
            file: file ?? self.file,
            thread: thread ?? self.thread,
            function: function ?? self.function,
            timestamp: timestamp ?? self.timestamp,
            message: message ?? self.message,
            line: line ?? self.line,
            level: level ?? self.level
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

private func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

private func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}

// MARK: - Alamofire response handlers
extension DataRequest {
    fileprivate func decodableResponseSerializer<T: Decodable>() -> DataResponseSerializer<T> {
        return DataResponseSerializer { _, _, data, error in
            guard error == nil else { return .failure(error!) }
            
            guard let data = data else {
                return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
            }
            
            return Result { try newJSONDecoder().decode(T.self, from: data) }
        }
    }
    
    @discardableResult
    fileprivate func responseDecodable<T: Decodable>(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: decodableResponseSerializer(), completionHandler: completionHandler)
    }
    
    @discardableResult
    func responseMeteoLogReader(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<MeteoLogReader>) -> Void) -> Self {
        return responseDecodable(queue: queue, completionHandler: completionHandler)
    }
}

/// StreamReader is a helper class for reading a single line at a time
/// Our log file is JSON formatted ... BUT ... each line is its own container
/// So ...we need to feed the MeteoLogReader a one-line formatted string object to
/// decode into our object.  This only exists because of the way SwiftyBeaver writes out logs
///
/// [Read a large text file line by line - Swift 3](https://gist.github.com/sooop/a2b110f8eebdf904d0664ed171bcd7a2)
///
class StreamReader {
    let encoding: String.Encoding
    let fileHandle: FileHandle
    var isAtEOF: Bool = false
    let delimPattern: Data
    let chunkSize: Int
    var buffer: Data
    
    /// Create the stream to read a file - line, by line.
    ///
    /// - Parameters:
    ///   - url: filename
    ///   - delimeter: what we use to end each line
    ///   - encoding: how is the file encoded
    ///   - chunkSize: buffer for each read
    ///
    init?(url: URL, delimeter: String = "\n", encoding: String.Encoding = .utf8, chunkSize: Int = 4096) {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return nil }
        self.fileHandle = fileHandle
        self.chunkSize = chunkSize
        self.encoding = encoding
        buffer = Data(capacity: chunkSize)
        delimPattern = delimeter.data(using: .utf8)!
    }

    ///
    /// Tidy up
    ///
    deinit {
        fileHandle.closeFile()
    }
    
    ///
    /// Set the pointer back to the beginning of the file
    ///
    func rewind() {
        fileHandle.seek(toFileOffset: 0)
        buffer.removeAll(keepingCapacity: true)
        isAtEOF = false
    }
    
    /// Step through he file, reading a new line each time
    ///
    /// - Returns: the line of text (MUST be < chunkSize)
    func nextLine() -> String? {
        if isAtEOF { return nil }
        repeat {
            if let range = buffer.range(of: delimPattern, options: [], in: buffer.startIndex..<buffer.endIndex) {
                let subData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                let line = String(data: subData, encoding: encoding)
                buffer.replaceSubrange(buffer.startIndex..<range.upperBound, with: [])
                return line
            } else {
                let tempData = fileHandle.readData(ofLength: chunkSize)
                if tempData.isEmpty {
                    isAtEOF = true
                    return (!buffer.isEmpty) ? String(data: buffer, encoding: encoding) : nil
                }
                buffer.append(tempData)
            }
        } while true
    }
}
