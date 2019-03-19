//
//  HashingManager.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/31/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CommonCrypto
import PhoneNumberKit

struct HashingManager {

  func salt() throws -> Data {
    guard let salt = keyDerivation.salt.data(using: .utf8) else {
      throw CKPersistenceError.missingValue(key: "salt as Data")
    }
    return salt
  }

  /// This function always requires a GlobalPhoneNumber for hashing. If a parsedNumber is already available, providing
  /// it will skip the step of parsing the global number in this function, increasing efficiency. Passing nil for the parsedNumber
  /// and relying on parsing inside this function is acceptable and the more common scenario.
  func hash(phoneNumber number: GlobalPhoneNumber, salt: Data, parsedNumber: PhoneNumber?, kit: PhoneNumberKit) -> String {
    let normalizedNumber = normalizeNumber(number, parsedNumber: parsedNumber, kit: kit)
    return pbkdf2SHA256(password: normalizedNumber,
                        salt: salt,
                        keyByteCount: 32,
                        rounds: keyDerivation.iterations)
  }

  private func normalizeNumber(_ number: GlobalPhoneNumber, parsedNumber: PhoneNumber?, kit: PhoneNumberKit) -> String {
    let transformablePhoneNumber: PhoneNumber? = parsedNumber ?? (try? kit.parse(number.asE164()))

    let originalNationalNumber = number.sanitizedNationalNumber()
    let trimmedNationalNumber = originalNationalNumber.dropFirstCharacter(ifEquals: "0")
    var normalizedNationalNumber = trimmedNationalNumber

    // Similar to Signal, we ignore the national prefix for Brazil whose token is "$2", prefix "0"
    let token = "$1"

    if let number = transformablePhoneNumber,
      let regionCode = kit.getRegionCode(of: number),
      let transformRule = kit.nationalPrefixTransformRule(forCountry: regionCode),
      transformRule.contains(token) {

      // The prefix precedes the token in the transform rule
      let prefix = transformRule.replacingOccurrences(of: token, with: "")

      // Trim leading 0 from transform rule to match Android
      let trimmedTransformRule = transformRule.dropFirstCharacter(ifEquals: "0")

      if originalNationalNumber.starts(with: prefix) == false {
        normalizedNationalNumber = trimmedTransformRule.replacingOccurrences(of: token, with: trimmedNationalNumber)
      }
    }

    let normalizedGlobalNumber = GlobalPhoneNumber(countryCode: number.countryCode, nationalNumber: normalizedNationalNumber)
    return normalizedGlobalNumber.sanitizedGlobalNumber()
  }

  func pbkdf2SHA256(password: String, salt: Data, keyByteCount: Int, rounds: Int) -> String {
    if let data = pbkdf2(hash: CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256), password: password, salt: salt, keyByteCount: keyByteCount, rounds: rounds) {
      return data.hexString
    }

    return ""
  }

  private func pbkdf2(hash: CCPBKDFAlgorithm, password: String, salt: Data, keyByteCount: Int, rounds: Int) -> Data? {
    guard let passwordData = password.data(using: String.Encoding.utf8) else {
      return nil
    }

    var derivedKeyData = Data(repeating: 0, count: keyByteCount)
    var localDerivedKeyData = Data(repeating: 0, count: keyByteCount)

    let derivationStatus = localDerivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
      salt.withUnsafeBytes { saltBytes in

        CCKeyDerivationPBKDF(
          CCPBKDFAlgorithm(kCCPBKDF2),
          password, passwordData.count,
          saltBytes, salt.count,
          hash,
          UInt32(rounds),
          derivedKeyBytes, derivedKeyData.count)
      }
    }

    if derivationStatus != 0 {
      return nil
    }

    derivedKeyData = localDerivedKeyData
    return derivedKeyData
  }
}
