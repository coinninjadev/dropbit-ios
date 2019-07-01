//
//  CKRecipientParserTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 12/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import XCTest

class CKRecipientParserTests: XCTestCase {

  var sut: CKRecipientParser!

  override func setUp() {
    super.setUp()
    self.sut = CKRecipientParser()
  }

  override func tearDown() {
    super.tearDown()
    self.sut = nil
  }

  func validPhoneNumbers() -> [String] {
    return [
      "13215551212",
      "1-876-555-1212",
      "+1 (876) 555-1212",
      "443.555.1212"
    ]
  }

  func testUSPhoneNumberFormatting() {
    for number in validPhoneNumbers() {
      do {
        _ = try self.sut.findSingleRecipient(inText: number)
      } catch {
        XCTFail("Error parsing \(number): \(error.localizedDescription)")
      }
    }
  }

  func textBlocksWithPunctuation(afterURL btcURL: BitcoinURL) -> [String] {
    let baseText = "Hey, here's my bitcoin address: \(btcURL.absoluteString)"
    let characters = [",", ".", "?", "!"]
    return characters.map { baseText + $0 }
  }

  func testParsingSucceeds_SingleAddressInTextBlockWithPunctualtion() {
    guard let btcURL = TestHelpers.mockValidBitcoinURL(withAmount: 1.2) else {
      XCTFail("Failed to create mock BitcoinURL")
      return
    }

    let textBlocks = textBlocksWithPunctuation(afterURL: btcURL)
    for text in textBlocks {
      do {
        let recipient = try self.sut.findSingleRecipient(inText: text)
        guard case let .bitcoinURL(associatedURL) = recipient else {
          XCTFail("Recipient is not a .bitcoinURL")
          return
        }
        XCTAssertEqual(associatedURL.absoluteString, btcURL.absoluteString)
      } catch {
        XCTFail("Error parsing \(text): \(error.localizedDescription)")
      }
    }
  }

  func testParsingSucceeds_TabsAndLineBreaks() {
    guard let btcURL = TestHelpers.mockValidBitcoinURL(withAmount: 1.2) else {
      XCTFail("Failed to create mock BitcoinURL")
      return
    }

    let textWithTab = "Hey, here's my bitcoin address: \t\(btcURL.absoluteString)."

    let textWithLinebreak = """
    Hey, here's my bitcoin address:
    \(btcURL.absoluteString).
    """

    for text in [textWithTab, textWithLinebreak] {
      do {
        let recipient = try self.sut.findSingleRecipient(inText: text)
        guard case let .bitcoinURL(associatedURL) = recipient else {
          XCTFail("Recipient is not a .bitcoinURL")
          return
        }
        XCTAssertEqual(associatedURL.absoluteString, btcURL.absoluteString)
      } catch {
        XCTFail("Error parsing \(text): \(error.localizedDescription)")
      }
    }
  }

  func testParsingSucceeds_PaymentRequest() {
    let expectedRequestURL = "https://bitpay.com/i/FTZtAAwrUCsHX9trpjSKum"
    let paymentRequestText = "bitcoin:?r=https://bitpay.com/i/FTZtAAwrUCsHX9trpjSKum"
    do {
      let recipient = try self.sut.findSingleRecipient(inText: paymentRequestText)
      guard case let .bitcoinURL(bitcoinURL) = recipient else {
        XCTFail("Recipient should be .bitcoinURL")
        return
      }

      XCTAssertEqual(bitcoinURL.absoluteString, paymentRequestText)
      XCTAssertEqual(bitcoinURL.components.paymentRequest?.absoluteString, expectedRequestURL)

    } catch {
      XCTFail("Failed to identify string as a payment request")
    }
  }

  func testParsingFails_MultipleAddresses() {
    let addresses = TestHelpers.validBase58CheckAddresses()
    let fullText = addresses.joined(separator: " ")
    do {
      _ = try self.sut.findSingleRecipient(inText: fullText)
      XCTFail("Text with multiple addresses should throw error")
    } catch let error as CKRecipientParserError {
      XCTAssertEqual(error.localizedDescription, CKRecipientParserError.multipleRecipients.localizedDescription)
    } catch {
      XCTFail("Error should be CKRecipientParserError")
    }
  }

  func testParsingFails_Bech32() {
    let address = TestHelpers.mockValidBech32Address()
    let fullText = "Hey, here's my bitcoin address: \(address)!"
    let expectedError = BitcoinAddressValidatorError.bech32
    do {
      _ = try self.sut.findSingleRecipient(inText: fullText)
    } catch let error as CKRecipientParserError {
      guard case let .validation(validationError) = error else {
        XCTFail("Bech 32 error should be wrapped in .validation case")
        return
      }
      XCTAssertEqual(validationError.debugMessage, expectedError.debugMessage)
    } catch {
      XCTFail("Error should be .bech32, not \"\(error.localizedDescription)\"")
    }
  }

}
