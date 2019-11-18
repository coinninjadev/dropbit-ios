//
//  CKCryptorTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 1/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CNBitcoinKit

class CKCryptorTests: XCTestCase {

  var words: [String] { return TestHelpers.fakeWords() }
  var mockPersistenceManager: MockPersistenceManager { return MockPersistenceManager() }

  func testDecryptingCipherTextReturnsExpectedText() {
    let stack = InMemoryCoreDataStack()
    let context = stack.context
    mockPersistenceManager.fakeCoinToUse = CNBBaseCoin(purpose: .BIP49, coin: .TestNet, account: 0)

    let aliceWallet = WalletManager(words: words.reversed(), persistenceManager: mockPersistenceManager)

    let bobWallet = WalletManager(words: words, persistenceManager: mockPersistenceManager)
    let bobReceiveAddress = bobWallet.createAddressDataSource().receiveAddress(at: 0)
    let bobECUncompressedPubkeyString = bobReceiveAddress.uncompressedPublicKey ?? ""
    guard let bobECUncompressedPubkeyData = Data(fromHexEncodedString: bobECUncompressedPubkeyString) else {
      XCTFail("failed to convert bob's pubkey string to data")
      return
    }

    let aliceEncryptor = CKCryptor(walletManager: aliceWallet)
    let clearText = "hello"
    let clearData = clearText.data(using: .utf8)!
    guard let payloadString = try? aliceEncryptor.encryptAsBase64String(message: clearData,
                                                                        withRecipientUncompressedPubkey: bobECUncompressedPubkeyData,
                                                                        isEphemeral: true) else {
      XCTFail("failed to encrypt alice's message")
      return
    }

    let bobDecryptor = CKCryptor(walletManager: bobWallet)

    context.performAndWait {
      let dpath = CKMDerivativePath.findOrCreate(with: 49, 1, 0, 0, 0, in: context)
      let addr = CKMAddress.findOrCreate(withAddress: bobReceiveAddress.address, in: context) // just so it's in the core data context
      addr.derivativePath = dpath
      dpath.address = addr
      do {
        let bobDecryptedData = try bobDecryptor.decrypt(
          payloadAsBase64String: payloadString,
          withReceiveAddress: bobReceiveAddress.address,
          in: context
        )
        let bobDecryptedString = String(bytes: bobDecryptedData, encoding: .utf8) ?? ""
        XCTAssertEqual(bobDecryptedString, clearText)
      } catch {
        XCTFail("failed to decrypt data. \(error.localizedDescription)")
      }
    }
  }

  func testDecryptingBase64EncodedCipherTextReturnsExpectedText() {
    let possibleMemos = [
      "hello",
      "67890",
      "🙌",
      "👯‍♀️💑👨‍❤️‍👨👩‍❤️‍👩👨‍👩‍👧‍👦🎅🏿",
      "₿",
      "Ødin",
      "真曰分友"
    ]

    mockPersistenceManager.fakeCoinToUse = CNBBaseCoin(purpose: .BIP49, coin: .TestNet, account: 0)

    let aliceWallet = WalletManager(words: words.reversed(), persistenceManager: mockPersistenceManager)

    let bobWallet = WalletManager(words: words, persistenceManager: mockPersistenceManager)

    possibleMemos.forEach { self.assertTextEncryption(clearText: $0, aliceWallet: aliceWallet, bobWallet: bobWallet)}
  }

  private func assertTextEncryption(clearText: String, aliceWallet: WalletManager, bobWallet: WalletManager) {
    let stack = InMemoryCoreDataStack()
    let context = stack.context
    mockPersistenceManager.fakeCoinToUse = CNBBaseCoin(purpose: .BIP49, coin: .TestNet, account: 0)

    let bobReceiveAddress = bobWallet.createAddressDataSource().receiveAddress(at: 0)
    let bobECUncompressedPubkeyString = bobReceiveAddress.uncompressedPublicKey ?? ""
    guard let bobECUncompressedPubkeyData = Data(fromHexEncodedString: bobECUncompressedPubkeyString) else {
      XCTFail("failed to convert bob's pubkey string to data")
      return
    }

    let aliceEncryptor = CKCryptor(walletManager: aliceWallet)
    let clearData = clearText.data(using: .utf8)!
    guard let payloadString = try? aliceEncryptor.encryptAsBase64String(
      message: clearData,
      withRecipientUncompressedPubkey: bobECUncompressedPubkeyData,
      isEphemeral: true
      ) else {
        XCTFail("failed to encrypt alice's message")
        return
    }

    let bobDecryptor = CKCryptor(walletManager: bobWallet)

    context.performAndWait {
      let dpath = CKMDerivativePath.findOrCreate(with: 49, 1, 0, 0, 0, in: context)
      let addr = CKMAddress.findOrCreate(withAddress: bobReceiveAddress.address, in: context) // just so it's in the core data context
      addr.derivativePath = dpath
      dpath.address = addr
      do {
        let bobDecryptedData = try bobDecryptor.decrypt(
          payloadAsBase64String: payloadString,
          withReceiveAddress: bobReceiveAddress.address,
          in: context
        )
        let bobDecryptedString = String(bytes: bobDecryptedData, encoding: .utf8) ?? ""
        XCTAssertEqual(bobDecryptedString, clearText)
      } catch {
        XCTFail("failed to decrypt data. \(error.localizedDescription)")
      }
    }

  }

  func testEncryptingPayload() {
    let stack = InMemoryCoreDataStack()
    let context = stack.context
    mockPersistenceManager.fakeCoinToUse = CNBBaseCoin(purpose: .BIP49, coin: .TestNet, account: 0)

    // Construct the test data
    let amountInfo = SharedPayloadAmountInfo(fiatCurrency: .USD, fiatAmount: 100)
    let alicePhoneNumber = GlobalPhoneNumber(countryCode: 1, nationalNumber: "5555555555")
    let alicePayload = SharedPayloadV1(txid: "4e0044689eeebff9f6232678397f9ed4ba52854bbde9efbee211c8f17a9d839b",
                                       memo: "谢谢 Bob 👋", amountInfo: amountInfo, senderPhoneNumber: alicePhoneNumber)
    guard let payloadData = try? alicePayload.encoded(),
      let stringifiedPayload = String(data: payloadData, encoding: .utf8) else {
        XCTFail("payloadData is nil")
        return
    }

    let aliceWallet = WalletManager(words: words.reversed(), persistenceManager: mockPersistenceManager)
    let aliceEncryptor = CKCryptor(walletManager: aliceWallet)

    let bobWallet = WalletManager(words: words, persistenceManager: mockPersistenceManager)
    let bobDecryptor = CKCryptor(walletManager: bobWallet)
    let bobReceiveAddress = bobWallet.createAddressDataSource().receiveAddress(at: 0)
    let bobECUncompressedPubkeyString = bobReceiveAddress.uncompressedPublicKey ?? ""
    guard let bobECUncompressedPubkeyData = Data(fromHexEncodedString: bobECUncompressedPubkeyString) else {
      XCTFail("failed to convert bob's pubkey string to data")
      return
    }

    guard let encryptedPayloadString = try? aliceEncryptor.encryptAsBase64String(
      message: payloadData,
      withRecipientUncompressedPubkey: bobECUncompressedPubkeyData,
      isEphemeral: true
      ) else {
        XCTFail("failed to encrypt alice's message")
        return
    }

    context.performAndWait {
      let dpath = CKMDerivativePath.findOrCreate(with: 49, 1, 0, 0, 0, in: context)
      let addr = CKMAddress.findOrCreate(withAddress: bobReceiveAddress.address, in: context) // just so it's in the core data context
      addr.derivativePath = dpath
      dpath.address = addr
      do {
        let bobDecryptedData = try bobDecryptor.decrypt(
          payloadAsBase64String: encryptedPayloadString,
          withReceiveAddress: bobReceiveAddress.address,
          in: context
        )
        let bobDecryptedPayload = try SharedPayloadV1(data: bobDecryptedData)
        let bobDecryptedString = String(bytes: bobDecryptedData, encoding: .utf8) ?? ""
        XCTAssertEqual(bobDecryptedString, stringifiedPayload)
        XCTAssertEqual(bobDecryptedPayload.info.memo, alicePayload.info.memo)
      } catch {
        XCTFail("failed to decrypt data. \(error.localizedDescription)")
      }
    }
  }

}
