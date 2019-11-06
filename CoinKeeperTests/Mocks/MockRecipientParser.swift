//
//  MockRecipientParser.swift
//  DropBitTests
//
//  Created by Ben Winters on 2/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation

class MockRecipientParser: RecipientParserType {

  func findRecipients(inText text: String, ofTypes types: [CKRecipientType]) throws -> [CKParsedRecipient] {
    throw CKRecipientParserError.noResults
  }

  func findSingleRecipient(inText text: String, ofTypes types: [CKRecipientType]) throws -> CKParsedRecipient {
    throw CKRecipientParserError.noResults
  }

}
