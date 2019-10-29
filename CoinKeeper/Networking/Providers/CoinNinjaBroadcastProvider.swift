//
//  CoinNinjaBroadcastProvider.swift
//  DropBit
//
//  Created by Mitchell Malleo on 10/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya
import PromiseKit
import CNBitcoinKit

class CoinNinjaBroadcastProvider {

  var provider: MoyaProvider<CoinNinjaBroadcastTarget> {
    return MoyaProvider<CoinNinjaBroadcastTarget>()
  }

  func broadcastTransaction(with metadata: CNBTransactionMetadata) -> Promise<BroadcastInfo> {
    return Promise { seal in
      provider.request(.broadcast(metadata.encodedTx)) { (result) in
        switch result {
        case .success(let response):
          let stringData = String(data: response.data, encoding: .utf8) ?? "No data available"
          guard 200..<300 ~= response.statusCode else {
            let statusString = String(describing: response.statusCode)
            let encodedInfo = BroadcastInfo.Encoded(statusCode: statusString, statusMessage: stringData)
            let info = BroadcastInfo(destination: .coinninja(encodedInfo))
            seal.reject(info)
            return
          }
          let statusString = String(describing: response.statusCode)
          let encodedInfo = BroadcastInfo.Encoded(statusCode: statusString, statusMessage: stringData)
          var info = BroadcastInfo(destination: .coinninja(encodedInfo))

          info.txid = metadata.txid
          seal.fulfill(info)
        case .failure(let error): seal.reject(BroadcastInfo(destination: .coinninja(BroadcastInfo.Encoded(
          statusCode: String(describing: error.unacceptableStatusCode ?? 1000),
          statusMessage: error.localizedDescription))))
        }
      }
    }
  }
}
