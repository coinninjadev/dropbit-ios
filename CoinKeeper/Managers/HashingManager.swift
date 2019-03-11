//
//  HashingManager.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/31/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CommonCrypto

struct HashingManager {

  func salt() throws -> Data {
    guard let salt = keyDerivation.salt.data(using: .utf8) else {
      throw CKPersistenceError.missingValue(key: "salt as Data")
    }
    return salt
  }

  func hash(phoneNumber number: GlobalPhoneNumber, salt: Data) -> String {
    let sanitizedNumber = number.sanitizedGlobalNumber()
    return pbkdf2SHA256(password: sanitizedNumber,
                        salt: salt,
                        keyByteCount: 32,
                        rounds: keyDerivation.iterations)
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
