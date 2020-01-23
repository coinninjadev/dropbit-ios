//
//  CKCryptor.swift
//  DropBit
//
//  Created by BJ Miller on 1/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

enum CKCryptorError: Error {
  case missingWalletManager
  case payloadNotBase64Encoded
}

class CKCryptor {

  private weak var walletManager: WalletManagerType?

  init(walletManager: WalletManagerType) {
    self.walletManager = walletManager
  }

  /// Encrypt a message with a recipient's uncompressed public key,
  /// and returns the encrypted data with the sender's uncompressed pubkey apended after encrypted data,
  /// and converts it to a Base64-encoded hex string.
  ///
  /// - Parameters:
  ///   - message: message to encrypt
  ///   - pubkey: recipient's uncompressed EC public key
  ///   - isEphemeral: If `true`, encryptor uses secure entropy to create an ephemeral key pair. If `false`, it uses the m/42 key by default.
  /// - Returns: Base64-encoded hex string representation of data, comprised of encrypted payload + sender's uncompressed EC public key
  /// - Throws: CKCryptorError
  func encryptAsBase64String(message: Data, withRecipientUncompressedPubkey pubkey: Data, isEphemeral: Bool) throws -> String {
    guard let wmgr = walletManager else { throw CKCryptorError.missingWalletManager }
    let wallet = wmgr.wallet
    let pubkeyString = pubkey.hexString
    if isEphemeral {
      let entropy = WalletManager.secureEntropy()
      let pubkeyString = pubkey.hexString
      let enc = try wallet.encrypt(withEphemeralKey: entropy, body: message, recipientUncompressedPubkey: pubkeyString)
      return enc.base64EncodedString()
    } else {
      let enc = try wallet.encryptMessage(message, recipientUncompressedPubkey: pubkeyString)
      return enc.base64EncodedString()
    }
  }

  /// Decrypt a message from CoinNinja API in Base64-encoded format.
  ///
  /// - Parameters:
  ///   - base64String: the payload string from the API as a Base64-encoded hex string
  ///   - address: address used by receiver when they provided the uncompressed public key for encryption
  ///   - context: the Core Data context within which to search for address/path properties
  /// - Returns: a data object containing the decrypted bytes. If known to be a string, use `String(bytes: decryptedData, encoding: .utf8)`
  /// - Throws: CKCryptorError
  func decrypt(payloadAsBase64String base64String: String, withReceiveAddress address: String, in context: NSManagedObjectContext) throws -> Data {
    guard let wmgr = walletManager else { throw CKCryptorError.missingWalletManager }
    guard let path: CKMDerivativePath = CKMAddress.find(withAddress: address, in: context)?.derivativePath else {
      throw DBTError.Persistence.missingValue(key: "address")
    }

    let data = Data(base64Encoded: base64String)
    return try wmgr.wallet.decryptWithKey(from: path.asCNBDerivationPath(), body: data)
  }

  func decryptWithDefaultPrivateKey(payloadAsBase64String base64String: String) throws -> Data {
    guard let wmgr = walletManager else { throw CKCryptorError.missingWalletManager }
    let data = Data(base64Encoded: base64String)
    return try wmgr.wallet.decryptMessage(data)
  }
}
