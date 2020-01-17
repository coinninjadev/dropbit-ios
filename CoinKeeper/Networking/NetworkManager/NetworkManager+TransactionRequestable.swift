//
//  NetworkManager+TransactionRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol TransactionRequestable: AnyObject {
  func fetchTransactionDetails(for txids: [String]) -> Promise<[TransactionResponse]>
  func fetchTransactionDetails(for txid: String) -> Promise<TransactionResponse>
}

extension NetworkManager: TransactionRequestable {

  func fetchTransactionDetails(for txids: [String]) -> Promise<[TransactionResponse]> {
    guard txids.isNotEmpty else { return Promise.value([]) }
    return cnProvider.requestList(TransactionsTarget.query(txids))
  }

  func fetchTransactionDetails(for txid: String) -> Promise<TransactionResponse> {
    return cnProvider.request(TransactionsTarget.get(txid))
  }
}
