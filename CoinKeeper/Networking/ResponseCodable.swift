//
//  ResponseCodable.swift
//  DropBit
//
//  Created by Ben Winters on 10/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol ResponseCodable: ResponseEncodable & ResponseDecodable {}

/// Useful for converting an Encodable response object to encoded data for a mock response
protocol ResponseEncodable: Encodable {}

protocol ResponseDecodable: Decodable {
  static var sampleJSON: String { get }
  static var decoder: JSONDecoder { get }

  /// The decodable type should evaluate the provided response with its own requirements
  /// and either throw an error or return the response.
  /// This is called immediately after decoding the response.
  static func validateResponse(_ response: Self) throws -> Self

  /// These three arrays of KeyPath and WritableKeyPath are used for validating the string values of each response
  static var requiredStringKeys: [KeyPath<Self, String>] { get }

  /// These keys need to be defined as `var` so that they qualify as WritableKeyPath
  static var optionalStringKeys: [WritableKeyPath<Self, String?>] { get }

  /// Has a default implementation. Array of strings can be empty, but must not contain an empty string.
  static var requiredStringArrayKeys: [KeyPath<Self, [String]>] { get }

}

extension ResponseDecodable {

  static var sampleData: Data {
    return sampleJSON.data(using: String.Encoding.utf8)!
  }

  static func sampleInstance() -> Self? {
    return try? decoder.decode(Self.self, from: sampleData)
  }

  static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom(customDateDecodingStrategy)
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

  private static var customDateDecodingStrategy: (Decoder) throws -> Date {
    return { decoder in
      let container = try decoder.singleValueContainer()
      let secondsSinceEpoch = try container.decode(Int.self)
      return Date(timeIntervalSince1970: Double(secondsSinceEpoch))
    }
  }

  /// Only validates strings by default. If overriding this default implementation,
  /// be sure to call response.validateStringValues() as part of the custom validation.
  static func validateResponse(_ response: Self) throws -> Self {
    let validatedStringResponse = try response.validateStringValues()
    return validatedStringResponse
  }

  /// Potentially returns a new instance where empty strings have been replaced with nil for String? keys
  func validateStringValues() throws -> Self {
    try Self.validateRequiredStrings(in: self)
    return try Self.validateAndRepairOptionalStrings(in: self)
  }

  static var requiredStringArrayKeys: [KeyPath<Self, [String]>] {
    return []
  }

  private static func validateRequiredStrings(in response: Self) throws {
    for keyPath in Self.requiredStringKeys {
      let stringValue: String = response[keyPath: keyPath]
      guard stringValue.isNotEmpty else {
        let typeName = String(describing: response.self)
        // Swift cannot currently generate a description of the keyPath
        throw CKNetworkError.invalidValue(keyPath: "\(typeName).unknownStringKey", value: stringValue, response: response)
      }
    }

    for keyPath in Self.requiredStringArrayKeys {
      let stringArrayValue: [String] = response[keyPath: keyPath]
      for stringValue in stringArrayValue {
        guard stringValue.isNotEmpty else {
          let typeName = String(describing: response.self)
          // Swift cannot currently generate a description of the keyPath
          throw CKNetworkError.invalidValue(keyPath: "\(typeName).unknownStringArrayKey", value: stringValue, response: response)
        }
      }
    }
  }

  /// Returns a copy of the instance so that the values can be mutated within this function
  private static func validateAndRepairOptionalStrings(in response: Self) throws -> Self {
    var mutableResponse = response
    for keyPath in Self.optionalStringKeys {
      if let stringValue: String = mutableResponse[keyPath: keyPath], stringValue.isEmpty {
        mutableResponse[keyPath: keyPath] = nil // replace empty string value with nil
      }
    }
    return mutableResponse
  }

}

extension ResponseEncodable {

  var encoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .secondsSince1970
    return encoder
  }

  func asData() -> Data? {
    return try? encoder.encode(self)
  }

}

extension Array where Element: ResponseEncodable {

  private var encoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .secondsSince1970
    return encoder
  }

  func asData() -> Data? {
    return try? encoder.encode(self)
  }

}

protocol LNResponseDecodable: ResponseDecodable {

}

extension LNResponseDecodable {

  static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(CKDateFormatter.rfc3339Decoding)
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

}
