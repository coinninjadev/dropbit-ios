//
//  CKCryptor.swift
//  DropBit
//
//  Created by BJ Miller on 1/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import RNCryptor
import CoreData
import CNBitcoinKit

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
    let keys = wmgr.encryptionCipherKeys(forUncompressedPublicKey: pubkey, withEntropy: isEphemeral)
    let encryptor = RNCryptor.EncryptorV3(encryptionKey: keys.encryptionKey, hmacKey: keys.hmacKey)
    let encryptedData = encryptor.encrypt(data: message)
    return (encryptedData + keys.associatedPublicKey).base64EncodedString()
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
    guard let payload = Data(base64Encoded: base64String) else { throw CKCryptorError.payloadNotBase64Encoded }
    guard let wmgr = walletManager else { throw CKCryptorError.missingWalletManager }

    // separate pubkey and encrypted data
    let pubkeyLength = 65
    let pubkeyStart = payload.count - pubkeyLength
    let uncompressedPubkeyData = payload.suffix(from: pubkeyStart)
    let encryptedData = payload.prefix(upTo: pubkeyStart)

    guard let path: CKMDerivativePath = CKMAddress.find(withAddress: address, in: context)?.derivativePath else {
      throw CKPersistenceError.missingValue(key: "address")
    }

    let keys = wmgr.decryptionCipherKeys(forReceiveAddressPath: path, withPublicKey: uncompressedPubkeyData, in: context)
    let decryptor = RNCryptor.DecryptorV3(encryptionKey: keys.encryptionKey, hmacKey: keys.hmacKey)
    return try decryptor.decrypt(data: encryptedData)
  }
}
