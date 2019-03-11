//
//  BlockchainInfoProvider.swift
//  CoinKeeper
//
//  Created by Ben Winters on 8/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya
import PromiseKit
import CNBitcoinKit

class BlockchainInfoProvider {

  var provider: MoyaProvider<BlockchainInfoTarget> {
    return MoyaProvider<BlockchainInfoTarget>()
  } //manager: CKAlamofireSessionManager.shared

  func confirmFailedTransaction(with txid: String) -> Promise<Bool> {

    return Promise { seal in
      provider.request(.transaction(txid)) { result in
        switch result {
        case .success(let response):
          switch response.statusCode {
          case 200..<300:
            do {
              let decoder = JSONDecoder()
              _ = try response.map(BCITransactionResponse.self, using: decoder)

              // If we succeed in decoding a response for the txid, then we have not
              // confirmed it as failed, so fulfill with false
              seal.fulfill(false)

            } catch {
              seal.reject(CKNetworkError.badResponse)
            }
          default:
            switch response.statusCode {
            case 500:
              seal.fulfill(true) //confirmed that txid does not exist on BCI
            default:
              seal.reject(CKNetworkError.unexpectedStatusCode(response.statusCode))
            }
          }
        case .failure:
          seal.fulfill(true) //confirmed that txid does not exist on BCI
        }
      }
    }
  }

  func broadcastTransaction(with metadata: CNBTransactionMetadata) -> Promise<BroadcastInfo> {
    return Promise { seal in
      provider.request(.sendRawTransaction(metadata.encodedTx)) { (result) in
        switch result {
        case .success(let response):
          let stringData = String(data: response.data, encoding: .utf8) ?? "No data available"
          guard 200..<300 ~= response.statusCode else {
            let info = BroadcastInfo(destination: .bci(BroadcastInfo.Encoded(statusCode: String(describing: response.statusCode),
                                                                             statusMessage: stringData)))
            seal.reject(info)
            return
          }
          var info = BroadcastInfo(destination: .bci(BroadcastInfo.Encoded(statusCode: String(describing: response.statusCode),
                                                                           statusMessage: stringData)))
          info.txid = metadata.txid
          seal.fulfill(info)
        case .failure(let error): seal.reject(BroadcastInfo(destination: .bci(BroadcastInfo.Encoded(
          statusCode: String(describing: error.unacceptableStatusCode ?? 1000),
          statusMessage: error.localizedDescription))))
        }
      }
    }
  }
}
