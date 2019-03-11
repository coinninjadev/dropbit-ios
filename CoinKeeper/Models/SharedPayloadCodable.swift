//
//  SharedPayloadCodable.swift
//  DropBit
//
//  Created by Ben Winters on 1/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// Each payload version can override these if necessary
protocol SharedPayloadCodable: Codable {

  var encoder: JSONEncoder { get }
  static var decoder: JSONDecoder { get }

  func encoded() throws -> Data
  init(data: Data) throws

}

extension SharedPayloadCodable {

  var encoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .secondsSince1970
    return encoder
  }

  static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
  }

  func encoded() throws -> Data {
    do {
      return try encoder.encode(self)
    } catch {
      let typeDesc = String(describing: self)
      throw CKNetworkError.encodingFailed(type: typeDesc)
    }
  }

  init(data: Data) throws {
    do {
      self = try Self.decoder.decode(Self.self, from: data)
    } catch {
      let typeDesc = String(describing: Self.self)
      throw CKNetworkError.decodingFailed(type: typeDesc)
    }
  }

}
