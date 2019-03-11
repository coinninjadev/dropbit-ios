//
//  MockNetworkManager+TransactionRequestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: TransactionRequestable {

  func fetchTransactionDetails(for txids: [String]) -> Promise<[TransactionResponse]> {
    return Promise { _ in }
  }

}
