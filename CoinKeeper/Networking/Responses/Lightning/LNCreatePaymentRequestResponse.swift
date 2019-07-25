//
//  LNCreatePaymentRequestResponse.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Moya

struct LNCreatePaymentRequestResponse: LNResponseDecodable {
  let request: String

  static var sampleJSON: String {
    return ""
  }

  static var requiredStringKeys: [KeyPath<LNCreatePaymentRequestResponse, String>] {
    return [\.request]
  }

  static var optionalStringKeys: [WritableKeyPath<LNCreatePaymentRequestResponse, String?>] {
    return []
  }

}
