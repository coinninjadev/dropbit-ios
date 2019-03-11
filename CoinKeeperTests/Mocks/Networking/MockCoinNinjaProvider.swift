//
//  MockCoinNinjaProvider.swift
//  DropBit
//
//  Created by Ben Winters on 10/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit
import PromiseKit
import Moya

struct ResponseStub {
  let data: Data
  let statusCode: Int

  /// Pass in `Data()` for network calls that return no data, e.g. `.delete`.
  /// `data` is optional only for a clean call site
  init(data: Data?, statusCode: Int = 200) {
    guard let d = data else {
      fatalError("Programmer or encoding error")
    }
    self.data = d
    self.statusCode = statusCode
  }

}

class MockCoinNinjaProvider: CoinNinjaProviderType {
  weak var headerDelegate: HeaderDelegate?

  /// These values can be used and removed one at a time to handle a series of network requests.
  private var responseStubs: [ResponseStub] = []

  func appendResponseStub(data: Data?) {
    let stub = ResponseStub(data: data)
    appendResponseStub(stub)
  }

  func appendResponseStub(_ stub: ResponseStub) {
    responseStubs.append(stub)
  }

  func removeAllResponseStubs() {
    responseStubs.removeAll()
  }

  var provider: MoyaProvider<MultiTarget> {
    var plugins: [PluginType] = []
    if let delegate = headerDelegate {
      plugins.append(AuthPlugin(headerDelegate: delegate))
    }

    let endpointClosure = { (target: MultiTarget) -> Endpoint in
      let sampleClosure = { () -> EndpointSampleResponse in
        if let res = self.responseStubs.safelyRemoveFirst() {
          return EndpointSampleResponse.networkResponse(res.statusCode, res.data)
        } else {
          return EndpointSampleResponse.networkResponse(200, target.sampleData)
        }
      }

      return Endpoint(url: target.path,
                      sampleResponseClosure: sampleClosure,
                      method: target.method,
                      task: target.task,
                      httpHeaderFields: target.headers)
    }

    return MoyaProvider<MultiTarget>(
      endpointClosure: endpointClosure,
      stubClosure: MoyaProvider.immediatelyStub,
      manager: CKAlamofireSessionManager.shared,
      plugins: plugins
    )
  }
}
