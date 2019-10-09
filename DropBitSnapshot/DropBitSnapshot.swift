//
//  DropBitSnapshot.swift
//  DropBitSnapshot
//
//  Created by Ben Winters on 10/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class DropBitSnapshot: UITestCase {

  override func setUp() {
    app.appendTestArguments([.resetPersistence, .skipTwitterAuthentication, .skipGlobalMessageDisplay, .loadMockTransactionHistory])
    setupSnapshot(app)
    app.launch()
    snapshot("proof of concept")
  }
  
}
