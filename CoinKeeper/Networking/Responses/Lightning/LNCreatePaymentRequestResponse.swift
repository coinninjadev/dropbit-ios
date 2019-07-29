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
    let requestString = """
    lnbcrt20u1pwn7zkppp5t8d93ude4d4mrwyktxlmt02g5q3pcsxa626ae63myha4ssa43kwqdz523jhxapqwfjhz
    at9wd6zqem9dejhyct5v4jzqct58gsryvp38yknqdedxgujqvf48gcrxw3j8yszkvpsxqcqcqzpgf7t6whaqkal
    pe9lprsm0vyjrrsue5t2yskzxtfzq3nqcz8rm7r24c22vqr9klcdd84g0urye3wjfkc9x2p0rt2fmv50gdgg7lxvyrxgq3pvdn5
    """.removingMultilineLineBreaks(replaceBreaksWithSpaces: false)
    return """
    "request" : "\(requestString)"
    """
  }

  static var requiredStringKeys: [KeyPath<LNCreatePaymentRequestResponse, String>] {
    return [\.request]
  }

  static var optionalStringKeys: [WritableKeyPath<LNCreatePaymentRequestResponse, String?>] {
    return []
  }

}
