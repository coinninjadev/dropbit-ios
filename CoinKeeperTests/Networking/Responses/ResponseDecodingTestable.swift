//
//  ResponseDecodingTestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation

protocol ResponseDecodingTestable: AnyObject {
  associatedtype ResponseType: ResponseDecodable // defines the sut
}

extension ResponseDecodingTestable {

  /// Decodes the sample JSON using the ResponseType
  func decodedSampleJSON() -> ResponseType? {
    do {
      let response = try ResponseType.decoder.decode(ResponseType.self, from: ResponseType.sampleData)
      return response
    } catch {
      log.error(error, message: nil)
      return nil
    }
  }

  var decodingFailureMessage: String {
    return "Failed to decode sample JSON for \(String(describing: ResponseType.self))"
  }

}
