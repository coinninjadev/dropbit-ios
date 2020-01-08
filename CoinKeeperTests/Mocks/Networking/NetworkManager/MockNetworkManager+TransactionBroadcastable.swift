//
//  MockNetworkManager+TransactionBroadcastable.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Cnlib
import PromiseKit

extension MockNetworkManager: TransactionBroadcastable {

  func broadcastTx(with transactionData: CNBCnlibTransactionData) -> Promise<String> {
    return Promise { _ in }
  }

  func broadcastTx(metadata: CNBCnlibTransactionMetadata) -> Promise<String> {
    return Promise { _ in }
  }

  func postSharedPayloadIfAppropriate(
    withOutgoingTxData outgoingTxData: OutgoingTransactionData,
    walletManager: WalletManagerType) -> Promise<String> {
    return Promise { _ in }
  }

  func postSharedPayloadIfAppropriate(withPostableObject object: SharedPayloadPostableObject,
                                      walletManager: WalletManagerType) -> Promise<String> {
    return Promise { _ in }
  }

}
