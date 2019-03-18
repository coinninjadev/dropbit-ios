//
//  MockNetworkManager+AddressRequestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: AddressRequestable {

  func fetchTransactionSummaries(for addresses: [String], afterDate: Date?) -> Promise<[AddressTransactionSummaryResponse]> {
    wasAskedToFetchTransactionSummariesForAddresses = true
    return Promise { _ in }
  }

}
