//
//  MockNetworkManager+BlockchainInfoRequestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: BlockchainInfoRequestable {

  func confirmFailedTransaction(with txid: String) -> Promise<Bool> {
    if let didConfirmFailure = confirmFailedTransactionValueByTxid[txid] {
      return Promise.value(didConfirmFailure)
    } else {
      return Promise { $0.reject(DBTError.Network.badResponse)}
    }
  }

}
