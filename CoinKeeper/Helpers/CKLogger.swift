//
//  CKLogger.swift
//  DropBit
//
//  Created by Ben Winters on 7/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Willow

let loggingQueue = DispatchQueue(label: "com.coinkeeper.cklogger.serial", qos: .utility)

let log = CKLogger()

class CKLogger: Logger {

  init() {
    var writers: [LogWriter] = []
    writers.append(ConsoleWriter(method: .nslog, modifiers: [CKLogPrefixModifier()]))
    do {
      let fileWriter = try CKFileWriter()
      writers.append(fileWriter)
    } catch {
      print("Failed to initialize CKFileWriter: \(error.localizedDescription)")
    }
    super.init(logLevels: [.all],
               writers: writers,
               executionMethod: .asynchronous(queue: loggingQueue))
  }

  func debug(_ message: String, privateArgs: [CVarArg] = [],
             file: String = #file, function: String = #function, line: Int = #line) {
    let location = self.logLocation(file, function, line)
    logMessage(message, privateArgs: privateArgs, level: .debug, location: location)
  }

  func info(_ message: String, privateArgs: [CVarArg] = [],
            file: String = #file, function: String = #function, line: Int = #line) {
    let location = self.logLocation(file, function, line)
    logMessage(message, privateArgs: privateArgs, level: .info, location: location)
  }

  func event(_ message: String, privateArgs: [CVarArg] = [],
             file: String = #file, function: String = #function, line: Int = #line) {
    let location = self.logLocation(file, function, line)
    logMessage(message, privateArgs: privateArgs, level: .event, location: location)
  }

  func warn(_ message: String, privateArgs: [CVarArg] = [],
            file: String = #file, function: String = #function, line: Int = #line) {
    let location = self.logLocation(file, function, line)
    logMessage(message, privateArgs: privateArgs, level: .warn, location: location)
  }

  func error(_ message: String, privateArgs: [CVarArg] = [],
             file: String = #file, function: String = #function, line: Int = #line) {
    let location = self.logLocation(file, function, line)
    logMessage(message, privateArgs: privateArgs, level: .error, location: location)
  }

  private func logMessage(_ message: String, privateArgs: [CVarArg], level: LogLevel, location: String) {
    #if DEBUG
    let prefixedMessage = "[\(location)] \(message)"
    let string = String(format: prefixedMessage, arguments: privateArgs)
    super.logMessage({string}, with: level)

    #else
    let prefixedMessage = "[\(location)] \(message)"
    let cleanedMessage = prefixedMessage.replacingOccurrences(of: "%@", with: "[private]")
    super.logMessage({cleanedMessage}, with: level)
    #endif
  }

  private func logLocation(_ file: String, _ function: String, _ line: Int) -> String {
    return "\(file) \(function), line: \(line)"
  }

}

class CKLogPrefixModifier: LogModifier {

  func modifyMessage(_ message: String, with logLevel: LogLevel) -> String {
    let timestamp = Date().debugDescription
    let levelPrefix = self.prefix(for: logLevel)
    return "[Willow] \(timestamp) \(levelPrefix)\(message)"
  }

  private func prefix(for logLevel: LogLevel) -> String {
    if logLevel.contains(.error) {
      return "🔴 error: "
    } else if logLevel.contains(.warn) {
      return "🔶 warning: "
    } else if logLevel.contains(.event) {
      return "🏁 event: "
    } else if logLevel.contains(.info) {
      return "🔷 info: "
    } else {
      return ""
    }
  }

}

class CKFileWriter: LogModifierWriter {

  var modifiers: [LogModifier] = [CKLogPrefixModifier()]

  static var fileURL: URL = {
    let documentURLs = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)
    return documentURLs.first!.appendingPathComponent("DropBitLog.txt")
  }()

  let fileHandle: FileHandle

  var lineCount: Int
  private let lineCountLowerBound = 10_000
  private let lineCountUpperBound = 15_000 //limit frequency of line counts

  lazy var outputStream: CKLogOutputStream = {
    return CKLogOutputStream(fileHandle)
  }()

  init() throws {
    let url = CKFileWriter.fileURL
    _ = FileManager.default.createFile(atPath: url.path, contents: nil)
    self.fileHandle = try FileHandle(forWritingTo: url)
    self.lineCount = CKFileWriter.countLines(fileURL: url)
  }

  func writeMessage(_ message: String, logLevel: LogLevel) {
    updateLineCount(for: message)
    removeLinesFromFileIfNeeded()
    outputStream.write(message)
  }

  func writeMessage(_ message: LogMessage, logLevel: LogLevel) {
    self.writeMessage(message.name, logLevel: logLevel)
  }

  private func updateLineCount(for message: String) {
    let newLines = message.components(separatedBy: .newlines).count
    self.lineCount += newLines
  }

  private func removeLinesFromFileIfNeeded() {
    guard self.lineCount > lineCountUpperBound else { return }
    let fileURL = CKFileWriter.fileURL

    do {
      let fileData = try Data(contentsOf: fileURL, options: .dataReadingMapped)
      let newLineData = "\n".data(using: String.Encoding.utf8)!

      var lineNumber = 0
      var pos = fileData.count - 1
      while lineNumber <= lineCountLowerBound {
        // Find next newline character:
        guard let range = fileData.range(of: newLineData, options: [.backwards], in: 0..<pos) else {
          return // File has less than `trimmedLineCount` lines.
        }
        lineNumber += 1
        pos = range.lowerBound
      }

      let trimmedData = fileData.subdata(in: pos..<fileData.count)
      try trimmedData.write(to: fileURL)

    } catch let error as NSError {
      print(error.localizedDescription)
    }
  }

  static func countLines(fileURL: URL) -> Int {
    guard let fileAsString = try? String(contentsOf: fileURL, encoding: .utf8) else {
      return 0
    }

    let lineComponents = fileAsString.components(separatedBy: .newlines)
    return lineComponents.count
  }

}

struct CKLogOutputStream: TextOutputStream {
  private let fileHandle: FileHandle
  let encoding: String.Encoding

  init(_ fileHandle: FileHandle, encoding: String.Encoding = .utf8) {
    self.fileHandle = fileHandle
    self.encoding = encoding
  }

  mutating func write(_ string: String) {
    if let data = string.data(using: encoding) {
      fileHandle.write(data)
    }
  }
}
