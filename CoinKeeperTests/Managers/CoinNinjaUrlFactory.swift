//
//  CoinNinjaUrlFactory.swift
//  DropBitTests
//
//  Created by Mitch on 8/31/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import XCTest

class CoinNinjaUrlFactoryTests: XCTestCase {

  func testUrlFactory() {
    let message = "Strings should be equal"
    XCTAssertEqual(CoinNinjaUrlFactory.buildUrl(for: .bitcoin)?.absoluteString, "https://www.coinninja.com/learnbitcoin", message)
    XCTAssertEqual(CoinNinjaUrlFactory.buildUrl(for: .seedWords)?.absoluteString, "https://www.coinninja.com/seedwords", message)
    XCTAssertEqual(CoinNinjaUrlFactory.buildUrl(for: .whyBitcoin)?.absoluteString, "https://www.coinninja.com/whybitcoin", message)
    XCTAssertEqual(CoinNinjaUrlFactory.buildUrl(for: .bitcoinSMS)?.absoluteString, "https://dropbit.app/dropbit", message)
    XCTAssertEqual(CoinNinjaUrlFactory.buildUrl(for: .dropBit)?.absoluteString, "https://dropbit.app/dropbit", message)
    XCTAssertEqual(CoinNinjaUrlFactory.buildUrl(for: .faqs)?.absoluteString, "https://dropbit.app/faq", message)
    XCTAssertEqual(CoinNinjaUrlFactory.buildUrl(for: .contactUs)?.absoluteString, "https://dropbit.app/faq#contact", message)
    XCTAssertEqual(CoinNinjaUrlFactory.buildUrl(for: .termsOfUse)?.absoluteString, "https://dropbit.app/termsofuse", message)
    XCTAssertEqual(CoinNinjaUrlFactory.buildUrl(for: .privacyPolicy)?.absoluteString, "https://dropbit.app/privacypolicy", message)

    let txid = "CKJCBAKSJBC"
    XCTAssertEqual(CoinNinjaUrlFactory.buildUrl(for: .transaction(id: txid))?.absoluteString,
                   "https://www.coinninja.com/tx/\(txid)", message)
  }
}
