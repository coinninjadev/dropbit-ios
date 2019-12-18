//
//  BlockstreamProvider.swift
//  DropBit
//
//  Created by BJ Miller on 4/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Moya
import PromiseKit
import Cnlib

class BlockstreamProvider {

  var provider: MoyaProvider<BlockstreamTarget> {
    return MoyaProvider<BlockstreamTarget>()
  }

  func broadcastTransaction(with metadata: CNBCnlibTransactionMetadata) -> Promise<BroadcastInfo> {
    return Promise { seal in
      provider.request(.sendRawTransaction(metadata.encodedTx)) { (result) in
        switch result {
        case .success(let response):
          let stringData = String(data: response.data, encoding: .utf8) ?? "No data available"
          guard 200..<300 ~= response.statusCode else {
            let statusString = String(describing: response.statusCode)
            let encodedInfo = BroadcastInfo.Encoded(statusCode: statusString, statusMessage: stringData)
            let info = BroadcastInfo(destination: .blockstream(encodedInfo))
            seal.reject(info)
            return
          }
          let statusString = String(describing: response.statusCode)
          let encodedInfo = BroadcastInfo.Encoded(statusCode: statusString, statusMessage: stringData)
          var info = BroadcastInfo(destination: .blockstream(encodedInfo))

          info.txid = metadata.txid
          seal.fulfill(info)
        case .failure(let error): seal.reject(BroadcastInfo(destination: .blockstream(BroadcastInfo.Encoded(
          statusCode: String(describing: error.unacceptableStatusCode ?? 1000),
          statusMessage: error.localizedDescription))))
        }
      }
    }
  }
}
