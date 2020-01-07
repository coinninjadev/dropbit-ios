//
//  CKCryptorTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 1/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import Cnlib

//swiftlint:disable line_length

class CKCryptorTests: XCTestCase {

  var words: [String] = []
  var mockPersistenceManager: MockPersistenceManager!

  override func setUp() {
    super.setUp()
    words = TestHelpers.fakeWords()
    mockPersistenceManager = MockPersistenceManager()
  }

  override func tearDown() {
    words = []
    mockPersistenceManager = nil
    super.tearDown()
  }

  func testDecryptingCipherTextReturnsExpectedText() {
    let stack = InMemoryCoreDataStack()
    let context = stack.context
    mockPersistenceManager.fakeCoinToUse = CNBCnlibNewBaseCoin(49, 1, 0)!

    let aliceWallet = WalletManager(words: words.reversed(), persistenceManager: mockPersistenceManager)!

    let bobWallet = WalletManager(words: words, persistenceManager: mockPersistenceManager)!

    var bobReceiveAddress: CNBCnlibMetaAddress!
    do {
      bobReceiveAddress = try bobWallet.createAddressDataSource().receiveAddress(at: 0)
    } catch {
      XCTFail("Failed to get a receive address for bob")
      return
    }
    let bobECUncompressedPubkeyString = bobReceiveAddress.uncompressedPublicKey
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
      let baseCoin = CNBCnlibNewBaseCoin(49, 1, 0)!
      let dpath = CKMDerivativePath.findOrCreate(with: baseCoin, change: 0, index: 0, in: context)
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

    mockPersistenceManager.fakeCoinToUse = CNBCnlibNewBaseCoin(49, 1, 0)!

    let aliceWallet = WalletManager(words: words.reversed(), persistenceManager: mockPersistenceManager)!

    let bobWallet = WalletManager(words: words, persistenceManager: mockPersistenceManager)!

    possibleMemos.forEach { self.assertTextEncryption(clearText: $0, aliceWallet: aliceWallet, bobWallet: bobWallet)}
  }

  private func assertTextEncryption(clearText: String, aliceWallet: WalletManager, bobWallet: WalletManager) {
    let stack = InMemoryCoreDataStack()
    let context = stack.context
    mockPersistenceManager.fakeCoinToUse = CNBCnlibNewBaseCoin(49, 1, 0)!

    var bobReceiveAddress: CNBCnlibMetaAddress!
    do {
      bobReceiveAddress = try bobWallet.createAddressDataSource().receiveAddress(at: 0)
    } catch {
      XCTFail("Failed to get receive address for bob")
      return
    }
    let bobECUncompressedPubkeyString = bobReceiveAddress.uncompressedPublicKey
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
      let baseCoin = CNBCnlibNewBaseCoin(49, 1, 0)!
      let dpath = CKMDerivativePath.findOrCreate(with: baseCoin, change: 0, index: 0, in: context)
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
    mockPersistenceManager.fakeCoinToUse = CNBCnlibNewBaseCoin(49, 0, 0)!

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

    let aliceWallet = WalletManager(words: words.reversed(), persistenceManager: mockPersistenceManager)!
    let aliceEncryptor = CKCryptor(walletManager: aliceWallet)

    let bobWallet = WalletManager(words: words, persistenceManager: mockPersistenceManager)!
    let bobDecryptor = CKCryptor(walletManager: bobWallet)
    var bobReceiveAddress: CNBCnlibMetaAddress!

    do {
      bobReceiveAddress = try bobWallet.createAddressDataSource().receiveAddress(at: 0)
    } catch {
      XCTFail("Failed to get receive address for bob")
      return
    }

    let bobECUncompressedPubkeyString = bobReceiveAddress.uncompressedPublicKey
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
      let baseCoin = CNBCnlibNewBaseCoin(49, 0, 0)!
      let dpath = CKMDerivativePath.findOrCreate(with: baseCoin, change: 0, index: 0, in: context)
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

  func testLightningEndToEndSharedPayload() {
    let memo = "hey dude"
    let aliceWords = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "about"]
    let bobWords = ["zoo", "zoo", "zoo", "zoo", "zoo", "zoo", "zoo", "zoo", "zoo", "zoo", "zoo", "wrong"]
    let aliceWalletManager = WalletManager(words: aliceWords, persistenceManager: mockPersistenceManager)!
    let bobWalletManager = WalletManager(words: bobWords, persistenceManager: mockPersistenceManager)!

    let aliceCryptor = CKCryptor(walletManager: aliceWalletManager)
    let bobCryptor = CKCryptor(walletManager: bobWalletManager)

    guard let key = (try? bobWalletManager.hexEncodedPublicKey()) else {
      XCTFail("failed to get bob's public key")
      return
    }
    guard let bobPubKeyHexData = Data(fromHexEncodedString: key) else {
      XCTFail("bob is bad")
      return
    }

    do {
      let encrypted = try aliceCryptor
        .encryptAsBase64String(message: memo.data(using: .utf8)!,
                               withRecipientUncompressedPubkey: bobPubKeyHexData,
                               isEphemeral: false)

      let decryptedData = try bobCryptor.decryptWithDefaultPrivateKey(payloadAsBase64String: encrypted)
      let decryptedString = String(data: decryptedData, encoding: .utf8)
      XCTAssertEqual(decryptedString, memo)
    } catch {
      XCTFail("failed to decrypt message: \(error.localizedDescription)")
    }
  }

  func testAliceDecryptFromBobUsingDerivationPath() {
    let stack = InMemoryCoreDataStack()
    let context = stack.context
    let expectedMemo = "Hey y'all right back"

    mockPersistenceManager.fakeCoinToUse = CNBCnlibNewBaseCoin(84, 0, 0)!
    let aliceWords = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "about"]
    let aliceWalletManager = WalletManager(words: aliceWords, persistenceManager: mockPersistenceManager)!
    let aliceCryptor = CKCryptor(walletManager: aliceWalletManager)
    let aliceAddress = "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu"
    let b64payload = "AwDZH1vechFtjqeGn3yKwgVkDWWieW64UVPVXIwf9/MfXwyuWHH91b6SLIpBP3lB+G0YRtm5pX8Wb61Pd0FgKLQ44VCMVCje7ync6eACHRh5KARFVJ6CP40onzjO9IvFd1ikQ8NpR84GRcZIzQkU3miZ3RaqlFdDjnHjbjrvSwp5fgyxedggZRMQWZguNEP8Kc2j"

    let baseCoin = CNBCnlibNewBaseCoin(84, 0, 0)!
    let dpath = CKMDerivativePath.findOrCreate(with: baseCoin, change: 0, index: 0, in: context)
    let addr = CKMAddress.findOrCreate(withAddress: aliceAddress, in: context) // just so it's in the core data context
    addr.derivativePath = dpath
    dpath.address = addr

    do {
      let decryptedBytes = try aliceCryptor.decrypt(payloadAsBase64String: b64payload, withReceiveAddress: aliceAddress, in: context)
      let decryptedString = String(data: decryptedBytes, encoding: .utf8)
      XCTAssertEqual(decryptedString, expectedMemo)
    } catch {
      XCTFail("failed to decrypt message: \(error.localizedDescription)")
    }
  }

}
