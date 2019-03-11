//
//  NetworkManager+BlockchainInfoRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol BlockchainInfoRequestable: AnyObject {
  /// Throws error if a valid response is returned for the txid
  func confirmFailedTransaction(with txid: String) -> Promise<Bool>
}

extension NetworkManager: BlockchainInfoRequestable {

  func confirmFailedTransaction(with txid: String) -> Promise<Bool> {
    return blockchainInfoProvider.confirmFailedTransaction(with: txid)
  }

}
