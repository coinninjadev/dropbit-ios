//
//  Country.swift
//  DropBit
//
//  Created by Ben Winters on 2/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

struct CKCountry {
  let regionCode: String //e.g. "US", "CN"
  let countryCode: Int //e.g. 1, 86
  let localizedName: String

  private let flagFactory = FlagEmojiFactory()

  func flag() -> String? {
    return flagFactory.emojiFlag(for: regionCode)
  }

  init(regionCode: String, countryCode: Int, localizedName: String) {
    self.regionCode = regionCode
    self.countryCode = countryCode
    self.localizedName = localizedName
  }

  init(regionCode: String, kit: PhoneNumberKit) {
    let countryCode = kit.countryCode(for: regionCode) ?? 1
    let countryName = Locale.current.localizedString(forRegionCode: regionCode) ?? ""
    self.init(regionCode: regionCode, countryCode: Int(countryCode), localizedName: countryName)
  }

  init(locale: Locale, kit: PhoneNumberKit) {
    let regionCode = locale.regionCode ?? "US"
    self.init(regionCode: regionCode, kit: kit)
  }

  /// Returns an uppercased string of the first letter of each word in the localizedName, diacritics removed.
  func localizedAcronym() -> String {
    let words = localizedName.components(separatedBy: " ")
    let letters = words.compactMap { $0.first }.reduce("", { $0 + String($1) })
    return letters.uppercased().folding(options: [.diacriticInsensitive], locale: nil)
  }

}

extension CKCountry: Comparable {
  static func < (lhs: CKCountry, rhs: CKCountry) -> Bool {
    let result = lhs.localizedName.compare(rhs.localizedName, options: [.caseInsensitive, .diacriticInsensitive])
    return result == .orderedAscending
  }

  static func == (lhs: CKCountry, rhs: CKCountry) -> Bool {
    let result = lhs.localizedName.compare(rhs.localizedName, options: [.caseInsensitive, .diacriticInsensitive])
    return result == .orderedSame
  }
}
