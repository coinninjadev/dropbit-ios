//
//  PhoneNumberKit+AreaCodes.swift
//  CoinKeeper
//
//  Created by Ben Winters on 9/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PhoneNumberKit

extension PhoneNumberKit {

  /// Get an array of area codes for an ISO 639 compliant region code.
  ///
  /// - parameter country: ISO 639 compliant region code (e.g "GB" for the UK).
  ///
  /// - returns: Optional array of area codes as [Int]?
  ///
  /// - Source: https://www.areacodelocations.info/allcodes.html
  func knownAreaCodes(forCountry country: String) -> [UInt64]? {
    switch country {
    case "CA":
      return [204, 226, 236, 249, 250, 289, 306, 343, 365, 403, 416, 418, 431, 437, 438, 450,
              506, 514, 519, 548, 579, 581, 587, 604, 613, 639, 647, 705, 709, 778, 780, 782,
              807, 819, 825, 867, 873, 902, 905]
    default:
      return nil
    }
  }

}
